//
// Copyright (c) 2017, Intel Corporation
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

#ifndef _WIN32
#define _GNU_SOURCE
#include <sys/mman.h>
#include <pthread.h>
#else
#include <Windows.h>
#endif

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <assert.h>
#include <inttypes.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include <opae/mpf/mpf.h>
#include "mpf_internal.h"

#ifndef _WIN32
#include "mmu_monitor.h"
#endif


// MAP_HUGE_SHIFT is defined since Linux 3.8
#ifndef MAP_HUGE_SHIFT
#define MAP_HUGE_SHIFT 26
#endif

#define MAP_1G_HUGEPAGE	(0x1e << MAP_HUGE_SHIFT) /* 2 ^ 0x1e = 1G */

#define FLAGS_4K (MAP_PRIVATE | MAP_ANONYMOUS)
#define FLAGS_2M (FLAGS_4K | MAP_HUGETLB)
#define FLAGS_1G (FLAGS_2M | MAP_1G_HUGEPAGE)

static bool is_simulated_fpga;


fpga_result mpfOsInit(_mpf_handle_p _mpf_handle)
{
    is_simulated_fpga = _mpf_handle->simulated_fpga;
    return FPGA_OK;
}


void mpfOsMemoryBarrier(void)
{
#ifndef _WIN32
    __asm__ volatile ("mfence" : : : "memory");
#else
    MemoryBarrier();
#endif
}


fpga_result mpfOsPrepareMutex(
    mpf_os_mutex_handle* mutex
)
{
#ifndef _WIN32
    //
    // Linux mutex implemented with pthreads.
    //
    pthread_mutex_t* m = malloc(sizeof(pthread_mutex_t));
    if (NULL == m) return FPGA_NO_MEMORY;

    pthread_mutex_init(m, NULL);

    // Return an anonymous handle to the mutex
    *mutex = (mpf_os_mutex_handle)m;
    return FPGA_OK;
#else
    //
    // Windows mutex
    //
    HANDLE m = CreateMutex(NULL, FALSE, NULL);
    if (NULL == m) return FPGA_NO_MEMORY;

    *mutex = (mpf_os_mutex_handle)m;
    return FPGA_OK;
#endif
}


fpga_result mpfOsDestroyMutex(
    mpf_os_mutex_handle mutex
)
{
#ifndef _WIN32
    pthread_mutex_t* m = (pthread_mutex_t*)mutex;
    if (pthread_mutex_destroy(m) == 0)
    {
        free(m);
        return FPGA_OK;
    }
    else
    {
        return FPGA_EXCEPTION;
    }
#else
    HANDLE m = (HANDLE)mutex;
    CloseHandle(m);
    return FPGA_OK;
#endif
}


fpga_result mpfOsLockMutex(
    mpf_os_mutex_handle mutex
)
{
#ifndef _WIN32
    pthread_mutex_t* m = (pthread_mutex_t*)mutex;
    int s = pthread_mutex_lock(m);
    return (0 == s) ? FPGA_OK : FPGA_EXCEPTION;
#else
    HANDLE m = (HANDLE)mutex;
    DWORD s = WaitForSingleObject(m, INFINITE);
    return (WAIT_OBJECT_0 == s) ? FPGA_OK : FPGA_EXCEPTION;
#endif
}


fpga_result mpfOsUnlockMutex(
    mpf_os_mutex_handle mutex
)
{
#ifndef _WIN32
    pthread_mutex_t* m = (pthread_mutex_t*)mutex;
    int s = pthread_mutex_unlock(m);
    return (0 == s) ? FPGA_OK : FPGA_EXCEPTION;
#else
    HANDLE m = (HANDLE)mutex;
    return ReleaseMutex(m) ? FPGA_OK : FPGA_EXCEPTION;
#endif
}


bool mpfOsTestMutexIsLocked(
    mpf_os_mutex_handle mutex
)
{
#ifndef _WIN32
    pthread_mutex_t* m = (pthread_mutex_t*)mutex;
    int s = pthread_mutex_trylock(m);
    if (0 != s)
    {
        // Mutex was locked already
        return true;
    }
    else
    {
        // Mutex wasn't locked. Release the lock acquired just now by the test.
        mpfOsUnlockMutex(mutex);
        return false;
    }
#else
    HANDLE m = (HANDLE)mutex;
    DWORD s = WaitForSingleObject(m, 0);
    if (WAIT_OBJECT_0 != s)
    {
        return true;
    }
    else
    {
        mpfOsUnlockMutex(mutex);
        return false;
    }
#endif
}


// Round a length up to a multiple of the page size
static size_t roundUpToPages(
    size_t num_bytes,
    mpf_vtp_page_size page_size
)
{
    size_t page_bytes = mpfPageSizeEnumToBytes(page_size);
    return (num_bytes + page_bytes - 1) & ~(page_bytes - 1);
}


fpga_result mpfOsMapMemory(
    size_t num_bytes,
    mpf_vtp_page_size* page_size,
    void** buffer
)
{
    if ((NULL == buffer) || (0 == num_bytes) || (NULL == page_size))
    {
        return FPGA_INVALID_PARAM;
    }

#ifndef _WIN32
    // POSIX

    // Try to allocate the buffer using the requested page size but use smaller
    // pages if necessary.
    if (*page_size > MPF_VTP_PAGE_1GB)
    {
        *page_size = MPF_VTP_PAGE_1GB;
    }

    while (true)
    {
        int flags;
        if (*page_size == MPF_VTP_PAGE_1GB)
            flags = FLAGS_1G;
        else if (*page_size == MPF_VTP_PAGE_2MB)
            flags = FLAGS_2M;
        else
            flags = FLAGS_4K;

        size_t size = roundUpToPages(num_bytes, *page_size);
        *buffer = mmap(NULL, size, (PROT_READ | PROT_WRITE), flags, -1, 0);

        // Buffer allocated?
        if (*buffer != MAP_FAILED)
        {
            // Allocating the buffer is not a guarantee that sufficient backing RAM
            // exists, especially for huge pages. Lock the range, forcing pages to
            // be mapped. munmap() still unlocks these pages, so we can just leave
            // them locked. The driver is going to pin them for FPGA access anyway.

            // No need to lock when simulating.
            if (is_simulated_fpga) break;

            int status = mlock(*buffer, size);
            // Success? If no error then leave the buffer locked and return it.
            if (! status) break;

            // Physical mapping failed. Unmap the buffer and either try a smaller
            // page size or fail.
            munmap(*buffer, size);
        }

        // Try a smaller size
        if (*page_size == MPF_VTP_PAGE_1GB)
            *page_size = MPF_VTP_PAGE_2MB;
        else if (*page_size == MPF_VTP_PAGE_2MB)
            *page_size = MPF_VTP_PAGE_4KB;
        else
        {
            // Failed
            *buffer = NULL;
            break;
        }
    }
#else
    // Windows

    // Implement me
    *buffer = NULL;
#endif

    if (*buffer == NULL) return FPGA_NO_MEMORY;

    return FPGA_OK;
}


fpga_result mpfOsUnmapMemory(
    void* buffer,
    size_t num_bytes
)
{
    if (NULL == buffer) return FPGA_INVALID_PARAM;

#ifndef _WIN32
    // POSIX

    if (munmap(buffer, num_bytes))
    {
        return FPGA_EXCEPTION;
    }
#else
    // Windows

    // Implement me
    return FPGA_EXCEPTION;
#endif

    return FPGA_OK;
}


#define MAPS_BUF_SZ 4096

//
// The /dev/mmu_monitor device driver is mainly used by VTP to track pages that
// are unmapped. The driver also provides a service that walks the memory table.
// It is much faster than parsing /proc/self/smaps.
//
// Return:
//   - FPGA_OK if the translation was successful
//   - FPGA_EXCEPTION if the service is unavailable
//   - FPGA_NOT_FOUND if the address is not mapped
//
static fpga_result getPageSizeFromMonDev(
    void* vaddr,
    mpf_vtp_page_size* page_size
)
{
    static int mfd = 0;

    if (mfd == -1) return FPGA_EXCEPTION;

    // First time called?
    if (mfd == 0)
    {
        mfd = open("/dev/mmu_monitor", O_RDONLY);
        if (mfd == -1) return FPGA_EXCEPTION;

        // Ignore old versions of the driver
        if (ioctl(mfd, MMU_MON_GET_API_VERSION) < 2)
        {
            close(mfd);
            mfd = -1;
            return FPGA_EXCEPTION;
        }
    }

    struct mmu_monitor_page_vma_info info;
    int ret;
    info.flags = 0;
    info.argsz = sizeof(info);
    info.vaddr = vaddr;
    ret = ioctl(mfd, MMU_MON_PAGE_VMA_INFO, &info);
    if (ret)
    {
        return (errno == ENOMEM) ? FPGA_NOT_FOUND : FPGA_EXCEPTION;
    }

    if (info.page_shift >= 30)
    {
        *page_size = MPF_VTP_PAGE_1GB;
    }
    else if (info.page_shift >= 21)
    {
        *page_size = MPF_VTP_PAGE_2MB;
    }
    else
    {
        *page_size = MPF_VTP_PAGE_4KB;
    }

    return FPGA_OK;
}


fpga_result mpfOsGetPageSize(
    void* vaddr,
    mpf_vtp_page_size* page_size
)
{
    if (NULL == page_size) return FPGA_INVALID_PARAM;

#ifndef _WIN32
    // Linux

    // First try the faster MMU monitor service
    fpga_result r;
    r = getPageSizeFromMonDev(vaddr, page_size);
    if ((r == FPGA_OK) || (r == FPGA_NOT_FOUND))
    {
        return r;
    }

    // No MMU monitor service. Use the slower /proc/self/smaps.

    // This routine is derived from libhugetlbfs, written by
    // David Gibson & Adam Litke, IBM Corporation.

    char line[MAPS_BUF_SZ];
    uint64_t addr = (uint64_t)vaddr;

    *page_size = MPF_VTP_PAGE_NONE;

    FILE *f = fopen("/proc/self/smaps", "r");
    if (f == NULL)
    {
        return FPGA_EXCEPTION;
    }

    while (fgets(line, MAPS_BUF_SZ, f))
    {
        unsigned long long start, end;
        char* tmp0;
        char* tmp1;

        // Range entries begin with <start addr>-<end addr>
        start = strtoll(line, &tmp0, 16);
        // Was a number found and is the next character a dash?
        if ((tmp0 == line) || (*tmp0 != '-'))
        {
            // No -- not a range
            continue;
        }

        end = strtoll(++tmp0, &tmp1, 16);
        // Keep search if not a number or the address isn't in range.
        if ((tmp0 == tmp1) || (start > addr) || (end <= addr))
        {
            continue;
        }

        while (fgets(line, MAPS_BUF_SZ, f))
        {
            // Look for KernelPageSize
            unsigned page_kb;
            int ret = sscanf(line, "KernelPageSize: %u kB", &page_kb);
            if (ret == 0)
                continue;

            fclose(f);

            if (ret < 1 || page_kb == 0) {
                return FPGA_EXCEPTION;
            }

            // page_kb is reported in kB. Convert to a VTP-supported size.
            if (page_kb >= 1048576)
            {
                *page_size = MPF_VTP_PAGE_1GB;
            }
            else if (page_kb >= 2048)
            {
                *page_size = MPF_VTP_PAGE_2MB;
            }
            else if (page_kb >= 4)
            {
                *page_size = MPF_VTP_PAGE_4KB;
            }
            else
            {
                return FPGA_EXCEPTION;
            }

            return FPGA_OK;
        }
    }

    // We couldn't find an entry for this addr in smaps.
    fclose(f);
    return FPGA_NOT_FOUND;

#else
    // Windows

    // Implement me
    return FPGA_EXCEPTION;
#endif
}
