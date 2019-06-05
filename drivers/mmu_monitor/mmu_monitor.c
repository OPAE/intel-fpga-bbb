// SPDX-License-Identifier: GPL-2.0
/*
 * MMU Monitor module
 *
 * Copyright 2019 Intel Corporation, Inc.
 *
 * Authors:
 *   Wu Hao <hao.wu@intel.com>
 *   Michael Adler <Michael.Adler@intel.com
 */

#include <linux/version.h>
#include <linux/eventfd.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <linux/mmu_notifier.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/device.h>
#include <linux/sched.h>

#include "mmu_monitor.h"

static const struct file_operations ops;

static struct miscdevice mon_miscdev = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "mmu_monitor",
	.fops = &ops,
	.mode = 0644
};

/* global list of monitors, protected by mon_list_lock */
static struct list_head mon_list;
static struct mutex mon_list_lock;

struct mmu_monitor {
	struct list_head node;

	struct mm_struct *mm;
	struct mmu_notifier notifier;

	struct eventfd_ctx *trigger;

	struct list_head evt_list;
	int evt_cnt;
	int start_evt_cnt;
};

#define QUEUE_MAX_EVT 100

struct mon_event {
	struct list_head node;
	unsigned long start;
	unsigned long end;
};

static struct mmu_monitor *notifier_to_monitor(struct mmu_notifier *mn)
{
	return container_of(mn, struct mmu_monitor, notifier);
}

/* add one event to the evt queue */
static int mmu_monitor_queue_event(struct mmu_monitor *mon, unsigned long start,
				   unsigned long end)
{
	struct mon_event *evt;

	if (mon->evt_cnt > QUEUE_MAX_EVT)
		return -EBUSY;

	evt = kzalloc(sizeof(*evt), GFP_KERNEL);
	if (!evt)
		return -ENOMEM;

	INIT_LIST_HEAD(&evt->node);
	evt->start = start;
	evt->end = end;

	list_add_tail(&evt->node, &mon->evt_list);
	mon->evt_cnt++;
	return 0;
}

/* fetch one event from the evt queue */
static struct mon_event *mmu_monitor_fetch_event(struct mmu_monitor *mon)
{
	struct mon_event *evt;

	if (list_empty(&mon->evt_list))
		return NULL;

	evt = list_first_entry(&mon->evt_list, struct mon_event, node);

	list_del(&evt->node);

	mon->evt_cnt--;

	return evt;
}

static void mmu_monitor_free_event(struct mon_event *evt)
{
	kfree(evt);
}

static void mmu_monitor_clean_queue(struct mmu_monitor *mon)
{
	struct mon_event *evt, *tmp;

	if (list_empty(&mon->evt_list))
		return;

	mon->start_evt_cnt = 0;

	list_for_each_entry_safe(evt, tmp, &mon->evt_list, node) {
		list_del(&evt->node);
		mon->evt_cnt--;
		mmu_monitor_free_event(evt);
	}
}

static void mmu_invalidate_range_start(struct mmu_notifier *mn,
				       struct mm_struct *mm,
				       unsigned long start, unsigned long end)
{
	struct mmu_monitor *mon = notifier_to_monitor(mn);
	struct device *dev = mon_miscdev.this_device;
        int cnt;

	/*
	 * In range_start we just track the number of ranges that are
	 * in the invalidation flow. An application may poll the driver
	 * with MMU_MON_GET_INFO to detecting pending invalidations.
	 */
	mutex_lock(&mon_list_lock);
	cnt = ++(mon->start_evt_cnt);
	mutex_unlock(&mon_list_lock);

	dev_dbg(dev, "%s: pid %d, start %lx, end %lx, cnt %d\n", __func__,
		task_pid_nr(current), start, end, cnt);
}

/*
 * Walk the page table to determine whether the user virtual address
 * is mapped. Returns 0 when not present. Returns the level in the table
 * when a mapping is found. Level 1 is the leaf (smallest pages) and
 * levels above that are huge pages.
 */
static int user_vaddr_is_mapped(struct mm_struct *mm, u64 vaddr)
{
	pgd_t *pgd;
	pud_t *pud;
	pmd_t *pmd;
	pte_t *pte;
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 12, 0)
	p4d_t *p4d;
#endif

	if (!mm)
		return 0;

	pgd = pgd_offset(mm, vaddr);
	if (!pgd_present(*pgd))
		return 0;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 12, 0)
	p4d = p4d_offset(pgd, vaddr);
	if (!p4d_present(*p4d))
		return 0;

	pud = pud_offset(p4d, vaddr);
#else
	pud = pud_offset(pgd, vaddr);
#endif
	if (!pud_present(*pud))
		return 0;
#if CONFIG_HUGETLB_PAGE
	if (pud_large(*pud))
		return 3;
#endif

	pmd = pmd_offset(pud, vaddr);
	if (!pmd_present(*pmd))
		return 0;
#if CONFIG_HUGETLB_PAGE
	if (pmd_large(*pmd))
		return 2;
#endif

	pte = pte_offset_map(pmd, vaddr);
	if (!pte_present(*pte))
		return 0;

	return 1;
}

static void mmu_invalidate_range_end(struct mmu_notifier *mn,
				       struct mm_struct *mm,
				       unsigned long start, unsigned long end)
{
	struct mmu_monitor *mon = notifier_to_monitor(mn);
	struct device *dev = mon_miscdev.this_device;
	int addr_still_mapped;

	/*
	 * Some invalidation is local to a particular thread but the
	 * address stays mapped. We filter those out by walking the page
	 * table to see whether a mapping remains. When a mapping remains,
	 * the notification is dropped.
	 *
	 * The pages being monitored are pinned for DMA access, so we
	 * can assume that the physical translation is unchanged.
	 *
	 * We only check the mapping at start, under the assumption that
	 * the notification is for the same operation on the whole range.
	 */
	addr_still_mapped = user_vaddr_is_mapped(mm, start);

	/*
	 * check if any eventfd register for monitoring first, then notify
	 * userspace via eventfd if queue event successfully.
	 */
	mutex_lock(&mon_list_lock);
	mon->start_evt_cnt--;
	if (mon->trigger && !addr_still_mapped) {
		if (!mmu_monitor_queue_event(mon, start, end))
			eventfd_signal(mon->trigger, 1);
	}
	mutex_unlock(&mon_list_lock);

	dev_dbg(dev, "%s: pid %d, start %lx, end %lx, level %d%s\n", __func__,
		task_pid_nr(current), start, end, addr_still_mapped,
		(addr_still_mapped ? " STILL MAPPED" : ""));
}

static const struct mmu_notifier_ops mon_mn_ops = {
	.invalidate_range_start = mmu_invalidate_range_start,
	.invalidate_range_end = mmu_invalidate_range_end,
};

static struct mmu_monitor *register_mmu_monitor(struct mm_struct *mm)
{
	struct mmu_monitor *mon;
	int ret;

	mon = kzalloc(sizeof(*mon), GFP_KERNEL);
	if (!mon)
		return ERR_PTR(-ENOMEM);

	INIT_LIST_HEAD(&mon->node);
	INIT_LIST_HEAD(&mon->evt_list);
	mon->evt_cnt = 0;
	mon->start_evt_cnt = 0;
	mon->mm = mm;
	mon->notifier.ops = &mon_mn_ops;

	ret = mmu_notifier_register(&mon->notifier, mm);
	if (ret) {
		kfree(mon);
		return ERR_PTR(ret);
	}

	list_add_tail(&mon->node, &mon_list);
	return mon;
}

static void unregister_mmu_monitor(struct mmu_monitor *mon)
{
	if (mon) {
		mutex_lock(&mon_list_lock);
		list_del(&mon->node);
		if (mon->trigger)
			eventfd_ctx_put(mon->trigger);
		mmu_monitor_clean_queue(mon);
		mutex_unlock(&mon_list_lock);
		mmu_notifier_unregister(&mon->notifier, mon->mm);
		kfree(mon);
	}
}

static int mmu_monitor_open(struct inode *inode, struct file *file)
{
	struct device *dev = mon_miscdev.this_device;
	struct mmu_monitor *mon;
	int ret = 0;

	mutex_lock(&mon_list_lock);
	mon = register_mmu_monitor(current->mm);
	if (IS_ERR(mon)) {
		dev_err(dev, "%s fail to register mmu_notifier\n", __func__);
		ret = PTR_ERR(mon);
	}

	dev_dbg(dev, "%s: pid %d, mon %p\n", __func__,
		task_pid_nr(current), mon);
	file->private_data = mon;
	mutex_unlock(&mon_list_lock);
	return ret;
}

static int mmu_monitor_release(struct inode *inode, struct file *file)
{
	struct device *dev = mon_miscdev.this_device;
	struct mmu_monitor *mon = file->private_data;

	dev_dbg(dev, "%s: pid %d, mon %p\n", __func__,
		task_pid_nr(current), mon);

	if (!mon) {
		return -ENODEV;
	}

	unregister_mmu_monitor(mon);

	return 0;
}

static long mmu_monitor_set_evtfd(struct mmu_monitor *mon, int evtfd)
{
	struct eventfd_ctx *trigger;

	if (mon->trigger) {
		eventfd_ctx_put(mon->trigger);
		mon->trigger = NULL;
	}

	if (evtfd < 0)
		return 0;

	trigger = eventfd_ctx_fdget(evtfd);
	if (IS_ERR(trigger))
		return PTR_ERR(trigger);

	mon->trigger = trigger;
	return 0;
}

static long mmu_monitor_ioctl_set_evtfd(struct mmu_monitor *mon, void *arg)
{
	struct mmu_monitor_evtfd evtfd;
	unsigned long minsz;
	long ret;

	minsz = offsetofend(struct mmu_monitor_evtfd, evtfd);

	if (copy_from_user(&evtfd, (void __user *)arg, minsz))
		return -EFAULT;

	if (evtfd.argsz < minsz || evtfd.flags)
		return -EINVAL;

	mutex_lock(&mon_list_lock);
	ret = mmu_monitor_set_evtfd(mon, evtfd.evtfd);
	mutex_unlock(&mon_list_lock);
	return ret;
}

static long mmu_monitor_get_event(struct mmu_monitor *mon, u64 *start, u64 *end)
{
	struct mon_event *evt = mmu_monitor_fetch_event(mon);

	if (!evt)
		return -ENOTTY;

	*start = evt->start;
	*end = evt->end;

	mmu_monitor_free_event(evt);
	return 0;
}

static long mmu_monitor_ioctl_get_event(struct mmu_monitor *mon, void *arg)
{
	struct mmu_monitor_event event;
	unsigned long minsz;
	long ret;

	minsz = offsetofend(struct mmu_monitor_event, end);

	if (copy_from_user(&event, (void __user *)arg, minsz))
		return -EFAULT;

	if (event.argsz < minsz || event.flags)
		return -EINVAL;

	mutex_lock(&mon_list_lock);
	ret = mmu_monitor_get_event(mon, &event.start, &event.end);
	if (ret)
		return ret;
	mutex_unlock(&mon_list_lock);

	if (copy_to_user(arg, &event, minsz))
		return -EFAULT;

	return 0;
}

static long mmu_monitor_ioctl_get_info(struct mmu_monitor *mon, void *arg)
{
	struct mmu_monitor_info info;
	unsigned long minsz;
	struct device *dev = mon_miscdev.this_device;

	minsz = offsetofend(struct mmu_monitor_info, evtcnt);

	if (copy_from_user(&info, (void __user *)arg, minsz))
		return -EFAULT;

	if (info.argsz < minsz || info.flags)
		return -EINVAL;

	mutex_lock(&mon_list_lock);
	info.evtcnt = mon->evt_cnt + mon->start_evt_cnt;
	dev_dbg(dev, "%s: pid %d, evt %d, start_evt %d\n", __func__,
		task_pid_nr(current), mon->evt_cnt, mon->start_evt_cnt);
	mutex_unlock(&mon_list_lock);

	if (copy_to_user(arg, &info, minsz))
		return -EFAULT;

	return 0;
}

static long mmu_monitor_ioctl_map_info(struct mm_struct *mm, void *arg)
{
	struct mmu_monitor_map_info map_info;
	unsigned long minsz;
	struct device *dev = mon_miscdev.this_device;

	minsz = offsetofend(struct mmu_monitor_map_info, page_level);

	if (copy_from_user(&map_info, (void __user *)arg, minsz))
		return -EFAULT;

	if (map_info.argsz < minsz || map_info.flags)
		return -EINVAL;

	map_info.page_level = 0;
	map_info.page_level = user_vaddr_is_mapped(mm, (u64)map_info.vaddr);

	dev_dbg(dev, "%s: pid %d, vaddr %p, level %d\n", __func__,
		task_pid_nr(current), map_info.vaddr, map_info.page_level);

	if (copy_to_user(arg, &map_info, minsz))
		return -EFAULT;

	return 0;
}

static long mmu_monitor_ioctl(struct file *file, unsigned int cmd,
			      unsigned long arg)
{
	struct device *dev = mon_miscdev.this_device;
	struct mmu_monitor *mon = file->private_data;
	int ret;

	if (!mon) {
		return -ENODEV;
	}

	switch (cmd) {
	case MMU_MON_SET_EVTFD:
		ret = mmu_monitor_ioctl_set_evtfd(mon, (void *)arg);
		break;
	case MMU_MON_GET_INFO:
		ret = mmu_monitor_ioctl_get_info(mon, (void *)arg);
		break;
	case MMU_MON_GET_EVENT:
		ret = mmu_monitor_ioctl_get_event(mon, (void *)arg);
		break;
	case MMU_MON_MAP_INFO:
		ret = mmu_monitor_ioctl_map_info(current->mm, (void *)arg);
		break;
	default:
		dev_dbg(dev, "%x cmd not handled", cmd);
		ret = -ENOTTY;
	}

	return ret;
}

static const struct file_operations ops = {
	.open		= mmu_monitor_open,
	.release	= mmu_monitor_release,
	.unlocked_ioctl = mmu_monitor_ioctl,
	.owner		= THIS_MODULE,
};

static int __init mmu_monitor_init(void)
{
	INIT_LIST_HEAD(&mon_list);
	mutex_init(&mon_list_lock);

	return misc_register(&mon_miscdev);
}
module_init(mmu_monitor_init);

static void __exit mmu_monitor_exit(void)
{
	misc_deregister(&mon_miscdev);
	mutex_destroy(&mon_list_lock);
}
module_exit(mmu_monitor_exit);

MODULE_DESCRIPTION("MMU Monitor Driver");
MODULE_LICENSE("GPL v2");
