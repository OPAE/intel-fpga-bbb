/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/*
 * MMU Monitor Module User API header File
 *
 * Copyright 2019 Intel Corporation, Inc.
 *
 * Authors:
 *   Wu Hao <hao.wu@intel.com>
 *   Michael Adler <Michael.Adler@intel.com
 *
 * This driver provides services that may be used by a user space process
 * connected to an accelerator. The driver code assumes that memory accessible
 * to the accelerator is pinned and mapped for I/O by some mechanism outside
 * the monitor.
 *
 * The monitor:
 *  - Provides an ioctl for probing a virtual address, returning the page size
 *    and read/write access of the region. This is equivalent to reading
 *    /proc/self/smaps, but faster.
 *  - Provides a service for tracking MMU changes that invalidate page mappings.
 *    User code may use this service to detect pages that are unmapped and
 *    should no longer be accessed by the accelerator.
 */

#ifndef _UAPI_MMU_MONITOR_H
#define _UAPI_MMU_MONITOR_H

#include <linux/types.h>

#define MMU_MON_API_VERSION 2

#define MMU_MON_MAGIC 0xB6

/**
 * MMU_MON_GET_API_VERSION -
 *
 * Report the version of the driver API.
 * Return: Driver API Version.
 */
#define MMU_MON_GET_API_VERSION	_IO(MMU_MON_MAGIC, 0)

/*
 * Set eventfd for notification.
 *
 * Once user sets a valid eventfd via this interface, mmu_monitor starts
 * logging related mmu notifier events. To disable this function, user
 * needs to issue one ioctl with evtfd = -1;
 */
struct mmu_monitor_evtfd {
	/* Input */
	__u32 argsz;
	__u32 flags;
#define MMU_MON_FILTER_MAPPED	(1 << 0)	/* Input: filter events when the page
						 * is still mapped. */
	__s32 evtfd;
};

#define MMU_MON_SET_EVTFD	_IO(MMU_MON_MAGIC, 1)

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

#define MMU_MON_GET_EVENT	_IO(MMU_MON_MAGIC, 2)

/*
 * Return the current state of the monitor.
 */
struct mmu_monitor_state {
	/* Input */
	__u32 argsz;
	__u32 flags;
	/* Output */
	__u32 evtcnt;		/* Count of outstanding events */
};

#define MMU_MON_GET_STATE	_IO(MMU_MON_MAGIC, 3)

/*
 * Return details about the virtual memory area at vaddr.
 * The same information could be extracted from /proc/self/smaps
 * but this service is much faster.
 */
struct mmu_monitor_page_vma_info {
	/* Input */
	__u32 argsz;
	__u32 flags;
#define MMU_MON_PAGE_READ	(1 << 0)	/* Output: region is readable */
#define MMU_MON_PAGE_WRITE	(1 << 1)	/* Output: region is writeable */
	const void *vaddr;
	/* Output */
	__u32 page_shift;	/* page_size == (1L << page_shift) */
};

#define MMU_MON_PAGE_VMA_INFO	_IO(MMU_MON_MAGIC, 4)

#endif
