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
#include <pthread.h>

#include "mmu_monitor.h"

#define FLAGS_4K (MAP_PRIVATE | MAP_ANONYMOUS)
#define FLAGS_2M (FLAGS_4K | MAP_HUGE_2MB | MAP_HUGETLB)
#define FLAGS_1G (FLAGS_4K | MAP_HUGE_1GB | MAP_HUGETLB)

static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

static void *mmu_tracking_thread(void *arg)
{
    struct mmu_monitor_evtfd mon_evtfd;
    struct mmu_monitor_event mon_event;
    int mfd, evtfd, ret;
    uint64_t count = 0;
    unsigned int i;

    // "arg" holds the fd of the monitor device.
    mfd = (uintptr_t)arg;

    // Create an eventfd for monitoring events from the monitor device.
    evtfd = eventfd(0, 0);
    mon_evtfd.flags = MMU_MON_FILTER_MAPPED;
    mon_evtfd.argsz = sizeof(struct mmu_monitor_evtfd);
    mon_evtfd.evtfd = evtfd;
    ret = ioctl(mfd, MMU_MON_SET_EVTFD, &mon_evtfd);
    if (ret)
    {
        fprintf(stderr, "Error setting MMU monitor event fd\n");
        exit(1);
    }

    while (1)
    {
        // Wait for an event from the driver.
        ret = read(evtfd, &count, sizeof(count));
        if (ret != sizeof(count))
        {
            fprintf(stderr, "Error reading mmu_notifier event counter\n");
            exit(1);
        }

        // Get the page pinning lock.
        pthread_mutex_lock(&mutex);

        for (i = 0; i < count; i++)
        {
            // Get each mmu_notifier event's details.
            mon_event.flags = 0;
            mon_event.argsz = sizeof(struct mmu_monitor_event);
            mon_event.start = 0;
            mon_event.end = 0;

            ioctl(mfd, MMU_MON_GET_EVENT, &mon_event);
            printf("mon_event[%d] start = 0x%llx, end = 0x%llx, len = %lld\n", i,
                   mon_event.start, mon_event.end,
                   mon_event.end - mon_event.start);
        }

        pthread_mutex_unlock(&mutex);
    }

    // Should not be reached
    close(evtfd);
    return NULL;
}

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

    int mfd = open("/dev/mmu_monitor", O_RDONLY);
    if (mfd == -1)
    {
        fprintf(stderr, "Failed to open /dev/mmu_monitor\n");
        return 1;
    }

    ret = ioctl(mfd, MMU_MON_GET_API_VERSION);
    printf("API version: %d\n", ret);

    if (ret != 2)
    {
        fprintf(stderr, "Expected API version 2!\n");
        exit(1);
    }

    // Create a thread that consumes monitor events
    pthread_t tidp;
    assert(pthread_create(&tidp, NULL, mmu_tracking_thread, (void*)(uintptr_t)mfd) == 0);

    // Allocate two page buffers of varying page size and protection
    uint8_t* buffers[7] = { MAP_FAILED };
    buffers[0] = mmap(NULL, 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_4K, -1, 0);
    buffers[1] = mmap(NULL, 4096 * 2, (PROT_READ), FLAGS_4K, -1, 0);

    buffers[2] = mmap(NULL, 512 * 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_2M, -1, 0);
    buffers[3] = mmap(NULL, 512 * 4096 * 2, (PROT_READ), FLAGS_2M, -1, 0);

    buffers[4] = mmap(NULL, 512L * 512 * 4096 * 2, (PROT_READ | PROT_WRITE), FLAGS_1G, -1, 0);
    buffers[5] = mmap(NULL, 512L * 512 * 4096 * 2, (PROT_READ), FLAGS_1G, -1, 0);

    // Map/unmap the last buffer so it definitely points to an unmapped address
    buffers[6] = mmap(NULL, 4096, (PROT_READ | PROT_WRITE), FLAGS_4K, -1, 0);
    munmap(buffers[6], 4096);

    for (int b = 0; b < 6; b++)
    {
        if (buffers[b] == MAP_FAILED)
        {
            fprintf(stderr, "Failed to allocate buffers[%d]\n", b);
            unmap_buffers(buffers, 6);
            exit(1);
        }
    }

    for (int b = 0; b < 7; b++)
    {
        struct mmu_monitor_page_vma_info info;
        info.flags = 0;
        info.argsz = sizeof(info);

        info.vaddr = buffers[b];

        ret = ioctl(mfd, MMU_MON_PAGE_VMA_INFO, &info);
        printf("page_vma_info: buffer %d, va %p, ret %d (%d), page shift %d, read %d, write %d\n",
               b, buffers[b], ret, errno,
               info.page_shift,
               (info.flags & MMU_MON_PAGE_READ) != 0,
               (info.flags & MMU_MON_PAGE_WRITE) != 0);
    }

    // Touch each buffer to force backing storage to be allocated
    for (int b = 0; b < 6; b += 2)
    {
        volatile int foo;
        foo = buffers[b + 1][0];
        buffers[b][0] = foo;
    }

    // Unmap the buffers
    unmap_buffers(buffers, 6);

    // Loop until there are no monitor events pending
    bool waited = false;
    struct mmu_monitor_state mon_state;
    do
    {
        mon_state.flags = 0;
        mon_state.argsz = sizeof(struct mmu_monitor_state);

        // Lock the mutex as proof that the tracking thread isn't busy
        pthread_mutex_lock(&mutex);
        ioctl(mfd, MMU_MON_GET_STATE, &mon_state);
        pthread_mutex_unlock(&mutex);

        if (mon_state.evtcnt && ! waited)
        {
            printf("waiting...\n");
            waited = true;
        }
    }
    while (mon_state.evtcnt);

    pthread_cancel(tidp);
    pthread_join(tidp, NULL);

    close(mfd);
    return 0;
}
