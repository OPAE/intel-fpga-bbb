//
// Copyright (c) 2019, Intel Corporation
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

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <inttypes.h>
#include <stdbool.h>
#include <sys/mman.h>
#include <linux/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/eventfd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <assert.h>

#include "fpga_near_mem_map.h"

#define FLAGS_4K (MAP_PRIVATE | MAP_ANONYMOUS)
#define FLAGS_2M (FLAGS_4K | MAP_HUGE_2MB | MAP_HUGETLB)
#define FLAGS_1G (FLAGS_4K | MAP_HUGE_1GB | MAP_HUGETLB)


static void unmap_buffers(uint8_t **buffers, size_t sz) {
    size_t n_bytes = 4096 * 2;

    for (int b = 0; b < sz; b += 2) {
        if (buffers[b] != MAP_FAILED) {
            printf("munmap buffer %d, va %p\n", b, buffers[b]);
            assert(munmap(buffers[b], n_bytes) == 0);
        }

        if (buffers[b + 1] != MAP_FAILED) {
            printf("munmap buffer %d, va %p\n", b + 1, buffers[b + 1]);
            assert(munmap(buffers[b + 1], n_bytes) == 0);
        }
         n_bytes *= 512;
    }
}

int main(int argc, char *argv[])
{
    int ret;

    int mfd = open("/dev/fpga_near_mem_map", O_RDONLY);
    if (mfd == -1)
    {
        fprintf(stderr, "Failed to open /dev/fpga_near_mem_map\n");
        return 1;
    }

    ret = ioctl(mfd, FPGA_NEAR_MEM_MAP_GET_API_VERSION);
    printf("API version: %d\n", ret);

    if (ret != 1)
    {
        fprintf(stderr, "Expected API version 1!\n");
        exit(1);
    }

    struct fpga_near_mem_map_base_phys_addr base_info;
    base_info.argsz = sizeof(base_info);
    base_info.flags = 0;
    base_info.ctrl_num = 0;
    ret = ioctl(mfd, FPGA_NEAR_MEM_MAP_BASE_PHYS_ADDR, &base_info);
    assert(0 == ret);
    printf("Base address: 0x%" PRIx64 "\n", base_info.base_phys);
    printf("NUMA mask: 0x%" PRIx64 "\n", base_info.numa_mask);

    // Allocate two page buffers of each size
    uint8_t* buffers[6] = { MAP_FAILED };
    buffers[0] = mmap(NULL, 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_4K, -1, 0);
    buffers[1] = mmap(NULL, 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_4K, -1, 0);

    buffers[2] = mmap(NULL, 512 * 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_2M, -1, 0);
    buffers[3] = mmap(NULL, 512 * 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_2M, -1, 0);

    buffers[4] = mmap(NULL, 512L * 512 * 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_1G, -1, 0);
    buffers[5] = mmap(NULL, 512L * 512 * 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_1G, -1, 0);

    for (int b = 0; b < 6; b++)
    {
        if (buffers[b] == MAP_FAILED)
        {
            fprintf(stderr, "Failed to allocate buffers[%d]\n", b);
            unmap_buffers(buffers, 6);
            exit(1);
        }
    }

    volatile int x;
    for (int b = 0; b < 6; b++)
    {
        struct fpga_near_mem_map_page_vma_info info;
        info.flags = 0;
        info.argsz = sizeof(info);
        info.vaddr = buffers[b];

        // Touch the page so it is allocated
        *buffers[b] = 0;

        ret = ioctl(mfd, FPGA_NEAR_MEM_MAP_PAGE_VMA_INFO, &info);
        printf("page_vma_info: buffer %d, va %p, ret %d (%d), pa 0x%" PRIx64 ", page shift %d, numa id %d, read %d, write %d\n",
               b, buffers[b], ret, errno,
               (uint64_t)info.page_phys,
               info.page_shift,
               info.page_numa_id,
               (info.flags & FPGA_NEAR_MEM_MAP_PAGE_READ) != 0,
               (info.flags & FPGA_NEAR_MEM_MAP_PAGE_WRITE) != 0);
    }

    close(mfd);
    return 0;
}
