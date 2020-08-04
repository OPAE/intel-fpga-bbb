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

#ifndef _UAPI_FPGA_NEAR_MEM_MAP_H
#define _UAPI_FPGA_NEAR_MEM_MAP_H

#include <linux/types.h>

#define FPGA_NEAR_MEM_MAP_API_VERSION 1

#define FPGA_NEAR_MEM_MAP_MAGIC 0xB7

/**
 * FPGA_NEAR_MEM_MAP_GET_API_VERSION -
 *
 * Report the version of the driver API.
 * Return: Driver API Version.
 */
#define FPGA_NEAR_MEM_MAP_GET_API_VERSION	_IO(FPGA_NEAR_MEM_MAP_MAGIC, 0)


/*
 * Return details about the virtual memory area at vaddr.
 * The same information could be extracted from /proc/self/smaps
 * and /proc/self/pagemap, but this service is much faster.
 */
struct fpga_near_mem_map_page_vma_info {
	/* Input */
	__u32 argsz;
	__u32 flags;
#define FPGA_NEAR_MEM_MAP_PAGE_READ	(1 << 0)	/* Output: region is readable */
#define FPGA_NEAR_MEM_MAP_PAGE_WRITE	(1 << 1)	/* Output: region is writeable */
	const void *vaddr;
	/* Output */
	__u64 page_phys;	/* physical address */
	__u64 base_phys;	/* controller base physical address */
	__u32 page_numa_id;	/* NUMA node ID */
	__u32 page_shift;	/* page_size == (1L << page_shift) */
};

#define FPGA_NEAR_MEM_MAP_PAGE_VMA_INFO	_IO(FPGA_NEAR_MEM_MAP_MAGIC, 1)


/*
 * Return the base address of physical memory on the designated
 * memory controller. Recent implementations all return 0 as the
 * base physical address, leaving the memory address translation
 * from host physical inside the fixed region of the FPGA.
 */
struct fpga_near_mem_map_base_phys_addr {
	/* Input */
	__u32 argsz;
	__u32 flags;
	__u32 ctrl_num;		/* reserved -- set to 0 */
	/* Output */
	__u64 base_phys;	/* controller base physical address */
	__u64 numa_mask;	/* mask of valid NUMA memory domains associated
				 * with the controller */
};

#define FPGA_NEAR_MEM_MAP_BASE_PHYS_ADDR	_IO(FPGA_NEAR_MEM_MAP_MAGIC, 10)

#endif
