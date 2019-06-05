/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/*
 * MMU Monitor Module User API header File
 *
 * Copyright 2019 Intel Corporation, Inc.
 *
 * Authors:
 *   Wu Hao <hao.wu@intel.com>
 *   Michael Adler <Michael.Adler@intel.com
 */

#ifndef _UAPI_MMU_MONITOR_H
#define _UAPI_MMU_MONITOR_H

#include <linux/types.h>

#define MMU_MON_MAGIC 0xB6

/*
 * Set eventfd for notification.
 *
 * once user sets a valid eventfd via this interface, mmu_monitor starts
 * logging related mmu notifier events. To disable this function, user
 * needs to issue one ioctl with evtfd = -1;
 */
struct mmu_monitor_evtfd {
	/* Input */
	__u32 argsz;
	__u32 flags;
	__s32 evtfd;
};

#define MMU_MON_SET_EVTFD	_IO(MMU_MON_MAGIC, 0)

/*
 * Return the address range from a single notification event.
 */
struct mmu_monitor_event {
	/* Input */
	__u32 argsz;
	__u32 flags;
	/* Output */
	__u64 start;
	__u64 end;
};

#define MMU_MON_GET_EVENT	_IO(MMU_MON_MAGIC, 1)

/*
 * Return the current state of the monitor.
 */
struct mmu_monitor_info {
	/* Input */
	__u32 argsz;
	__u32 flags;
	/* Output */
	__u32 evtcnt;		/* Count of outstanding events */
};

#define MMU_MON_GET_INFO	_IO(MMU_MON_MAGIC, 2)

/*
 * Walk the page table and determine whether user address vaddr
 * is mapped. "page_level" returns 0 if the address is not mapped.
 * If the address is mapped "page_level" indicates the level
 * in the table, and thus the page size. Page level one is the pte
 * leaf (normal page size). Levels above that are huge pages.
 */
struct mmu_monitor_map_info {
	/* Input */
	__u32 argsz;
	__u32 flags;
	const void *vaddr;
	/* Output */
	__u32 page_level;
};

#define MMU_MON_MAP_INFO	_IO(MMU_MON_MAGIC, 3)

#endif
