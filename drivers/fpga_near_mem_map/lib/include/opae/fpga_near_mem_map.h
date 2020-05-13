//
// Copyright (c) 2020, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#ifndef __FPGA_NEAR_MEM_MAP_H__
#define __FPGA_NEAR_MEM_MAP_H__

#include <numa.h>
#include <opae/types.h>

#ifdef __cplusplus
extern "C" {
#endif


typedef struct
{
    uint64_t phys_addr;
    uint64_t phys_space_base; /* Base address of physical space. In some
                               * address spaces, the FPGA expects addresses
                               * as: phys_addr-phys_space_base. */
    uint32_t page_shift;      /* Page size: 1 << page_shift */
    uint32_t numa_id;
    bool may_read;
    bool may_write;
} fpga_near_mem_map_buf_info;


/**
 * Retrieve physical address and other buffer details
 *
 * This function is used on experimental systems when FPGA-side addressing
 * is physical.
 *
 * @note This function will disappear once the APIs for secure sharing of
 * buffer addresses is implemented.
 *
 * @param[in]  buf_addr Virtual address of buffer
 * @param[out] buf_info Buffer information, including physical address and
 *                      NUMA memory domain ID.
 * @returns FPGA_OK on success. FPGA_INVALID_PARAM if invalid parameters were
 * provided, or if the parameter combination is not valid. FPGA_EXCEPTION if an
 * internal exception occurred while trying to access the handle.
 */
fpga_result fpgaNearMemGetPageAddrInfo(const void *buf_addr,
                                       fpga_near_mem_map_buf_info *buf_info);


/**
 * Retrieve physical address and other buffer details
 *
 * This function is used on experimental systems when FPGA-side addressing
 * is physical.
 *
 * @note This function will disappear once the APIs for secure sharing of
 * buffer addresses is implemented.
 *
 * @param[in]  ctrl_num      Controller number (0 for now).
 * @param[out] base_phys     Base physical address of controller-managed memory.
 * @param[out] numa_mem_mask Mask of NUMA domain(s) associated with controller.
 *                           Ignored if the pointer is NULL. Caller should pass
 *                           in a pointer to an existing struct bitmask, e.g.
 *                           from numa_allocate_nodemask().
 * @returns FPGA_OK on success. FPGA_INVALID_PARAM if invalid parameters were
 * provided, or if the parameter combination is not valid. FPGA_EXCEPTION if an
 * internal exception occurred while trying to access the handle.
 */
fpga_result fpgaNearMemGetCtrlInfo(uint32_t ctrl_num,
                                   uint64_t *base_phys,
                                   struct bitmask *numa_mem_mask);


/**
 * Close connection to driver
 *
 * @returns FPGA_OK on success or FPGA_EXCEPTION on error.
 */
fpga_result fpgaNearMemClose(void);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif // __FPGA_NEAR_MEM_MAP_H__
