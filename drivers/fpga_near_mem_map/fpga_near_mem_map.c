/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/*
 * FPGA Virtual to Physical Near-Memory Mapping Helper
 *
 * Copyright 2020 Intel Corporation, Inc.
 *
 * Authors:
 *   Michael Adler <Michael.Adler@intel.com
 *
 * This driver may eventually provide the framework for managing virtual to
 * physical translation in an FPGA. For now it only exists to support the
 * building blocks on machines where the FPGA accesses memory directly
 * with host physical addresses instead of normal IOMMU-protected DMA.
 *
 * The driver opens a security hole by exposing the virtual to physical mapping
 * of the connected process. The hole is limited, since translations are
 * available only for the address space of the connected process. Use with care!
 *
 * MOST SYSTEMS DO NOT NEED THIS DRIVER.
 *
 */

#include <linux/version.h>
#include <linux/dma-mapping.h>
#include <linux/eventfd.h>
#include <linux/fs.h>
#include <linux/miscdevice.h>
#include <linux/mm.h>
#include <linux/hugetlb.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/device.h>
#include <linux/sched.h>
#include <linux/version.h>

#include "fpga_near_mem_map.h"

static const struct file_operations ops;

static struct miscdevice near_mem_map_miscdev = {
	.minor = MISC_DYNAMIC_MINOR,
	.name = "fpga_near_mem_map",
	.fops = &ops,
	.mode = 0644
};

// Ideally we would look up the NUMA mask given a memory controller.
// For now, it's just a parameter that can be set when the driver
// is loaded.
unsigned long numa_mask_param = 0;
MODULE_PARM_DESC(numa_mask_param, "MMCFG associated NUMA memory domains mask");
module_param(numa_mask_param, ulong, 0440);

static int fpga_near_mem_map_open(struct inode *inode, struct file *file)
{
	struct device *dev = near_mem_map_miscdev.this_device;
	int ret = 0;

	dev_dbg(dev, "%s: pid %d\n", __func__,
		task_pid_nr(current));
	file->private_data = NULL;
	return ret;
}

static int fpga_near_mem_map_release(struct inode *inode, struct file *file)
{
	struct device *dev = near_mem_map_miscdev.this_device;

	dev_dbg(dev, "%s: pid %d\n", __func__,
		task_pid_nr(current));

	return 0;
}

/*
 * Walk the page table to determine whether the user virtual address
 * is mapped. Returns 0 when not present. Returns the page shift
 * when a mapping is found.
 *
 * Sets *page with the associated struct page* when a translation exists.
 */
static u32 user_vaddr_to_page(struct mm_struct *mm, u64 vaddr, struct page **page)
{
	pgd_t *pgd;
	pud_t *pud;
	pmd_t *pmd;
	pte_t *ptep;
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 12, 0)
	p4d_t *p4d;
#endif
	int ret;

	*page = NULL;

	if (!mm)
		return 0;

	pgd = pgd_offset(mm, vaddr);
	if (!pgd_present(*pgd))
		return 0;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 12, 0)
	p4d = p4d_offset(pgd, vaddr);
	if (!p4d_present(*p4d))
		return 0;
#if CONFIG_HUGETLB_PAGE
	if (p4d_large(*p4d)) {
		*page = p4d_page(*p4d);
		return P4D_SHIFT;
	}
#endif

	pud = pud_offset(p4d, vaddr);
#else
	pud = pud_offset(pgd, vaddr);
#endif
	if (!pud_present(*pud))
		return 0;
#if CONFIG_HUGETLB_PAGE
	if (pud_large(*pud)) {
		*page = pud_page(*pud);
		return PUD_SHIFT;
	}
#endif

	pmd = pmd_offset(pud, vaddr);
	if (!pmd_present(*pmd))
		return 0;
#if CONFIG_HUGETLB_PAGE
	if (pmd_large(*pmd)) {
		*page = pmd_page(*pmd);
		return PMD_SHIFT;
	}
#endif

	ptep = pte_offset_map(pmd, vaddr);
	ret = (!pte_present(*ptep) ? 0 : PAGE_SHIFT);
	if (ret) {
		*page = pte_page(*ptep);
	}
	pte_unmap(ptep);

	return ret;
}

/*
 * Return information about vaddr by probing the vm_area_struct.
 */
static long get_vaddr_page_vma_info(struct mm_struct *mm, u64 vaddr,
				    u64 *base_phys,
				    u32 *page_shift, u64 *page_phys,
				    u32 *page_nid, unsigned long *vm_flags)
{
	int level;
	struct vm_area_struct *vma;
	struct page *page;

	*base_phys = 0;
	*page_shift = 0;
	*page_phys = 0;
	*page_nid = 0;
	*vm_flags = 0;

	/* Lock the mm */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 8, 0)
	mmap_read_lock(mm);
#else
	down_read(&mm->mmap_sem);
#endif

	/* Is there a mapping at vaddr? */
	vma = find_vma(mm, vaddr);
	if (!vma || (vaddr < vma->vm_start)) {
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 8, 0)
		mmap_read_unlock(mm);
#else
		up_read(&mm->mmap_sem);
#endif
		return -ENOMEM; /* no mapping */
	}

	/* Is the mapping a huge page? */
	if (is_vm_hugetlb_page(vma)) {
		struct hstate *h = hstate_vma(vma);
		*page_shift = huge_page_shift(h);
	}
	else
		*page_shift = PAGE_SHIFT;

	*vm_flags = vma->vm_flags;

	page = NULL;
	level = user_vaddr_to_page(mm, vaddr, &page);
	if (level) {
		/*
		 * Update the page shift with the true value from the page table.
		 * A transparent huge page may be mapped inside a VMA tagged
		 * for smaller pages.
		 */
		*page_shift = level;
		*page_phys = page_to_phys(page);
		*page_nid = page_to_nid(page);
	}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 8, 0)
	mmap_read_unlock(mm);
#else
	up_read(&mm->mmap_sem);
#endif
	return 0;
}

static long fpga_near_mem_map_ioctl_page_vma_info(struct mm_struct *mm, void *arg)
{
	long ret;
	struct fpga_near_mem_map_page_vma_info vma_info;
	unsigned long minsz;
	struct device *dev = near_mem_map_miscdev.this_device;
	unsigned long vm_flags;

	minsz = offsetofend(struct fpga_near_mem_map_page_vma_info, page_shift);

	if (copy_from_user(&vma_info, (void __user *)arg, minsz))
		return -EFAULT;

	if (vma_info.argsz < minsz || vma_info.flags)
		return -EINVAL;

	ret = get_vaddr_page_vma_info(mm, (u64)vma_info.vaddr, &vma_info.base_phys,
				      &vma_info.page_shift,
				      &vma_info.page_phys, &vma_info.page_numa_id,
				      &vm_flags);
	vma_info.flags = 0;
	if (vm_flags & VM_READ)
		vma_info.flags |= FPGA_NEAR_MEM_MAP_PAGE_READ;
	if (vm_flags & VM_WRITE)
		vma_info.flags |= FPGA_NEAR_MEM_MAP_PAGE_WRITE;

	dev_dbg(dev, "%s: pid %d, vaddr %p, shift %d, read %d, write %d\n", __func__,
		task_pid_nr(current), vma_info.vaddr, vma_info.page_shift,
		(vma_info.flags & FPGA_NEAR_MEM_MAP_PAGE_READ) != 0,
		(vma_info.flags & FPGA_NEAR_MEM_MAP_PAGE_WRITE) != 0);

	if (copy_to_user(arg, &vma_info, minsz))
		return -EFAULT;

	return ret;
}

static long fpga_near_mem_map_ioctl_base_phys_addr(void *arg)
{
	struct fpga_near_mem_map_base_phys_addr req;
	unsigned long minsz;
	struct device *dev = near_mem_map_miscdev.this_device;

	minsz = offsetofend(struct fpga_near_mem_map_base_phys_addr, numa_mask);

	if (copy_from_user(&req, (void __user *)arg, minsz))
		return -EFAULT;

	if (req.argsz < minsz || req.flags)
		return -EINVAL;

	req.flags = 0;
	req.base_phys = 0;
	req.numa_mask = numa_mask_param;

	dev_dbg(dev, "%s: pid %d, base_phys 0x%llx, numa_mask 0x%llx\n", __func__,
		task_pid_nr(current), req.base_phys, req.numa_mask);

	if (copy_to_user(arg, &req, minsz))
		return -EFAULT;

	return 0;
}

static long fpga_near_mem_map_ioctl(struct file *file, unsigned int cmd,
			      unsigned long arg)
{
	struct device *dev = near_mem_map_miscdev.this_device;
	int ret;

	switch (cmd) {
	case FPGA_NEAR_MEM_MAP_GET_API_VERSION:
		ret = FPGA_NEAR_MEM_MAP_API_VERSION;
		break;
	case FPGA_NEAR_MEM_MAP_PAGE_VMA_INFO:
		ret = fpga_near_mem_map_ioctl_page_vma_info(current->mm, (void *)arg);
		break;
	case FPGA_NEAR_MEM_MAP_BASE_PHYS_ADDR:
		ret = fpga_near_mem_map_ioctl_base_phys_addr((void *)arg);
		break;
	default:
		dev_dbg(dev, "%x cmd not handled", cmd);
		ret = -EINVAL;
	}

	return ret;
}

static const struct file_operations ops = {
	.open		= fpga_near_mem_map_open,
	.release	= fpga_near_mem_map_release,
	.unlocked_ioctl = fpga_near_mem_map_ioctl,
	.owner		= THIS_MODULE,
};

#define dprintf(l, m...) \
	printk("%s:%d ", __func__, __LINE__); \
	printk(m)

static int __init fpga_near_mem_map_init(void)
{
	return misc_register(&near_mem_map_miscdev);
}
module_init(fpga_near_mem_map_init);

static void __exit fpga_near_mem_map_exit(void)
{
	misc_deregister(&near_mem_map_miscdev);
}
module_exit(fpga_near_mem_map_exit);

MODULE_DESCRIPTION("FPGA near-memory map driver");
MODULE_LICENSE("GPL v2");
