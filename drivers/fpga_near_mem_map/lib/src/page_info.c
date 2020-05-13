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

#include <opae/fpga_near_mem_map.h>

// Driver API
#include "../../fpga_near_mem_map.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <unistd.h>

static bool did_init;
static int fd;

static int init_mapper(void)
{
    if (did_init)
        return 0;

    fd = open("/dev/fpga_near_mem_map", O_RDONLY);
    if (fd == -1)
    {
        fprintf(stderr, "***\n\ninit_mapper: Failed to open /dev/fpga_near_mem_map\n\n***\n");
        return -1;
    }

    did_init = true;
    return 0;
}


fpga_result fpgaNearMemGetPageAddrInfo(const void *buf_addr,
                                       fpga_near_mem_map_buf_info *buf_info)
{
    if ((NULL == buf_addr) || (NULL == buf_info))
        return FPGA_INVALID_PARAM;

    if (init_mapper())
        return FPGA_EXCEPTION;

    struct fpga_near_mem_map_page_vma_info info;
    info.flags = 0;
    info.argsz = sizeof(info);
    info.vaddr = buf_addr;

    if (ioctl(fd, FPGA_NEAR_MEM_MAP_PAGE_VMA_INFO, &info))
        return FPGA_EXCEPTION;

    buf_info->phys_addr = info.page_phys;
    buf_info->phys_space_base = info.base_phys;
    buf_info->page_shift = info.page_shift;
    buf_info->numa_id = info.page_numa_id;
    buf_info->may_read = (info.flags & FPGA_NEAR_MEM_MAP_PAGE_READ);
    buf_info->may_write = (info.flags & FPGA_NEAR_MEM_MAP_PAGE_WRITE);

    return FPGA_OK;
}


fpga_result fpgaNearMemGetCtrlInfo(uint32_t ctrl_num,
                                   uint64_t *base_phys,
                                   struct bitmask *numa_mem_mask)
{
    int ret;

    if (NULL == base_phys)
        return FPGA_INVALID_PARAM;

    if (init_mapper())
        return FPGA_EXCEPTION;

    struct fpga_near_mem_map_base_phys_addr base_info;
    base_info.argsz = sizeof(base_info);
    base_info.flags = 0;
    base_info.ctrl_num = ctrl_num;
    ret = ioctl(fd, FPGA_NEAR_MEM_MAP_BASE_PHYS_ADDR, &base_info);
    if (ret)
    {
        return FPGA_EXCEPTION;
    }

    *base_phys = base_info.base_phys;
    if (numa_mem_mask)
    {
        int b = 0;
        uint64_t numa_mask = base_info.numa_mask;

        // Set bits from base_info.numa_mask in numa_mem_mask
        numa_bitmask_clearall(numa_mem_mask);
        while (numa_mask)
        {
            if (numa_mask & 1)
            {
                numa_bitmask_setbit(numa_mem_mask, b);
            }

            b += 1;
            numa_mask >>= 1;
        }
    }

    return FPGA_OK;
}


fpga_result fpgaNearMemClose(void)
{
    int ret = 0;

    if (did_init)
        ret = close(fd);

    return ((0 == ret) ? FPGA_OK : FPGA_EXCEPTION);
}
