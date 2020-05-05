/* SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note */
/*
 * FPGA Virtual to Physical (VTP) Mapping Helper
 *
 * Copyright 2020 Intel Corporation, Inc.
 *
 * Authors:
 *   Michael Adler <Michael.Adler@intel.com
 *
 * This driver may eventually provide the framework for managing virtual to
 * physical translation in an FPGA. For now it only exists to support the
 * MPF VTP building block on machines where the FPGA accesses memory directly
 * with host physical addresses instead of normal IOMMU-protected DMA.
 *
 * The driver opens a security hole by exposing the virtual to physical mapping
 * of the connected process. The hole is limited, since translations are
 * available only for the address space of the connected process. Use with care!
 *
 * MOST SYSTEMS DO NOT NEED THIS DRIVER.
 *
 */

#ifndef _UAPI_FPGA_VTP_MAPPER_H
#define _UAPI_FPGA_VTP_MAPPER_H

#include <linux/types.h>

#define FPGA_VTP_API_VERSION 1

#define FPGA_VTP_MAGIC 0xB7

/**
 * FPGA_VTP_GET_API_VERSION -
 *
 * Report the version of the driver API.
 * Return: Driver API Version.
 */
#define FPGA_VTP_GET_API_VERSION	_IO(FPGA_VTP_MAGIC, 0)


/*
 * Return details about the virtual memory area at vaddr.
 * The same information could be extracted from /proc/self/smaps
 * and /proc/self/pagemap, but this service is much faster.
 */
struct fpga_vtp_mapper_page_vma_info {
	/* Input */
	__u32 argsz;
	__u32 flags;
#define FPGA_VTP_PAGE_READ	(1 << 0)	/* Output: region is readable */
#define FPGA_VTP_PAGE_WRITE	(1 << 1)	/* Output: region is writeable */
	const void *vaddr;
	/* Output */
	__u64 page_phys;	/* physical address */
	__u32 page_shift;	/* page_size == (1L << page_shift) */
};

#define FPGA_VTP_PAGE_VMA_INFO	_IO(FPGA_VTP_MAGIC, 1)


/*
 * Return the base address of physical memory on the designated
 * memory controller.
 */
struct fpga_vtp_mapper_base_phys_addr {
	/* Input */
	__u32 argsz;
	__u32 flags;
	__u32 ctrl_num;		/* reserved -- set to 0 */
	/* Output */
	__u64 base_phys;	/* base physical address */
};

#define FPGA_VTP_BASE_PHYS_ADDR	_IO(FPGA_VTP_MAGIC, 10)

#endif
