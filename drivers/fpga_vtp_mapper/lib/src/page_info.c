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

#include <opae/fpga_vtp_mapper.h>

// Driver API
#include "../../fpga_vtp_mapper.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdio.h>

static int init_mapper(uint64_t *phys_space_base)
{
    int ret;
    int mfd = open("/dev/fpga_vtp_mapper", O_RDONLY);
    if (mfd == -1)
    {
        fprintf(stderr, "***\n\ninit_mapper: Failed to open /dev/fpga_vtp_mapper\n\n***\n");
        return -1;
    }

    struct fpga_vtp_mapper_base_phys_addr base_info;
    base_info.argsz = sizeof(base_info);
    base_info.flags = 0;
    ret = ioctl(mfd, FPGA_VTP_BASE_PHYS_ADDR, &base_info);
    *phys_space_base = base_info.base_phys;

    return ((0 == ret) ? mfd : -1);
}


fpga_result fpgaGetPageAddrInfo(const void *buf_addr,
                                fpga_vtp_buf_info *buf_info)
{
    static bool did_init = false;
    static int fd;
    static uint64_t phys_space_base;

    if ((NULL == buf_addr) || (NULL == buf_info))
        return FPGA_INVALID_PARAM;

    // Open the driver on the first call here
    if (!did_init)
    {
        fd = init_mapper(&phys_space_base);
        if (fd == -1)
        {
            return FPGA_EXCEPTION;
        }

        did_init = true;
    }

    struct fpga_vtp_mapper_page_vma_info info;
    info.flags = 0;
    info.argsz = sizeof(info);
    info.vaddr = buf_addr;

    if (ioctl(fd, FPGA_VTP_PAGE_VMA_INFO, &info))
        return FPGA_EXCEPTION;

    buf_info->phys_addr = info.page_phys;
    buf_info->phys_space_base = phys_space_base;
    buf_info->page_shift = info.page_shift;
    buf_info->numa_id = info.page_numa_id;
    buf_info->may_read = (info.flags & FPGA_VTP_PAGE_READ);
    buf_info->may_write = (info.flags & FPGA_VTP_PAGE_WRITE);

    return FPGA_OK;
}
