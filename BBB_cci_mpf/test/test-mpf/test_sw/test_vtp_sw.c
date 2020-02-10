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

#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <sys/mman.h>

#include <opae/fpga.h>
#include <opae/mpf/mpf.h>


//
// Connect to any accelerator. We aren't going to use it other than
// to keep OPAE happy and to have a feature list for MPF to walk.
//
static fpga_handle connect_to_accel()
{
    fpga_properties filter = NULL;
    fpga_token accel_token;
    uint32_t num_matches;
    fpga_handle accel_handle;
    fpga_result r;

    // Don't print verbose messages in ASE by default
    setenv("ASE_LOG", "0", 0);

    // Set up a filter that will search for an accelerator
    fpgaGetProperties(NULL, &filter);
    fpgaPropertiesSetObjectType(filter, FPGA_ACCELERATOR);

    // Do the search across the available FPGA contexts
    num_matches = 1;
    fpgaEnumerate(&filter, 1, &accel_token, 1, &num_matches);

    // Not needed anymore
    fpgaDestroyProperties(&filter);

    if (num_matches < 1)
    {
        fprintf(stderr, "Accelerator not found!\n");
        return 0;
    }

    // Open accelerator
    r = fpgaOpen(accel_token, &accel_handle, 0);
    assert(FPGA_OK == r);

    // Done with token
    fpgaDestroyToken(&accel_token);

    return accel_handle;
}


/*
 * Allocate (mmap) new buffer
 */
#define KB 1024
#define MB (1024 * KB)
#define GB (1024UL * MB)

#define PROTECTION (PROT_READ | PROT_WRITE)

#ifndef MAP_HUGETLB
#define MAP_HUGETLB 0x40000
#endif
#ifndef MAP_HUGE_SHIFT
#define MAP_HUGE_SHIFT 26
#endif

#define MAP_1G_HUGEPAGE	(0x1e << MAP_HUGE_SHIFT) /* 2 ^ 0x1e = 1G */

#define FLAGS_4K (MAP_PRIVATE | MAP_ANONYMOUS)
#define FLAGS_2M (FLAGS_4K | MAP_HUGETLB)
#define FLAGS_1G (FLAGS_2M | MAP_1G_HUGEPAGE)

static fpga_result buffer_allocate(void **addr, uint64_t len, int flags)
{
    void *addr_local = NULL;

    assert(NULL != addr);

    addr_local = mmap(NULL, len, PROTECTION, flags, 0, 0);
    if (addr_local == MAP_FAILED) {
        if (errno == ENOMEM) {
            if (len > 2 * MB)
                FPGA_MSG("Could not allocate buffer (no free 1 "
                     "GiB huge pages)");
            if (len > 4 * KB)
                FPGA_MSG("Could not allocate buffer (no free 2 "
                     "MiB huge pages)");
            else
                FPGA_MSG("Could not allocate buffer (out of "
                     "memory)");
            return FPGA_NO_MEMORY;
        }
        FPGA_MSG("FPGA buffer mmap failed: %s", strerror(errno));
        return FPGA_INVALID_PARAM;
    }

    *addr = addr_local;
    return FPGA_OK;
}

/*
 * Release (unmap) allocated buffer
 */
static fpga_result buffer_release(void *addr, uint64_t len)
{
    if (munmap(addr, len)) {
        FPGA_MSG("FPGA buffer munmap failed: %s",
             strerror(errno));
        return FPGA_INVALID_PARAM;
    }

    return FPGA_OK;
}

static fpga_result testVtpGetIOAddrVec(mpf_handle_t mpf_handle,
                                       uint8_t *buf,
                                       const char *info)
{
    fpga_result r;

    uint64_t ioaddr[512];
    int flags[512];
    mpf_vtp_page_size page_size;
    int n_pages;
    int i;

    printf("Testing buffer with %s pages...\n", info);

    r = mpfVtpPinAndGetIOAddress(mpf_handle, MPF_VTP_PIN_MODE_LOOKUP_ONLY,
                                 buf, ioaddr, &page_size, NULL);
    assert(FPGA_OK == r);

    printf("  Buffer VA %p -> IOVA 0x%016" PRIx64 ", %lld byte pages\n",
           buf, ioaddr[0], 1LL << (uint32_t)page_size);

    n_pages = 512;
    r = mpfVtpPinAndGetIOAddressVec(mpf_handle, MPF_VTP_PIN_MODE_LOOKUP_ONLY,
                                    buf + (1LL << page_size),
                                    &n_pages, ioaddr, &page_size, flags);
    assert(FPGA_OK == r);
    printf("  Vector of translations returned %d results:\n", n_pages);
    for (i = 0; i < n_pages; i += 1)
    {
        printf("    Buffer VA %p -> IOVA 0x%016" PRIx64 ", %ld byte pages, flags %d\n",
               buf + (1LL << page_size) * (i + 1), ioaddr[i], 1L << (uint32_t)page_size,
               flags[i]);
    }

    return FPGA_OK;
}


int main(int argc, char *argv[])
{
    fpga_result r;
    fpga_handle accel_handle;
    volatile char *buf;
    uint64_t wsid;
    uint64_t buf_pa;

    // Find and connect to the accelerator
    accel_handle = connect_to_accel();

    mpf_handle_t mpf_handle;
    r = mpfConnect(accel_handle, 0, 0, &mpf_handle, MPF_FLAG_NONE);
    assert(FPGA_OK == r);

    bool has_vtp = mpfShimPresent(mpf_handle, CCI_MPF_SHIM_VTP);
    printf("AFU %s VTP shim\n", (has_vtp ? "has" : "does not have"));

    //
    // Allocate 3 buffers, each with different page sizes.
    //
    uint8_t *buf_2xGB;
    r = buffer_allocate((void*)&buf_2xGB, GB * 2, FLAGS_1G);
    if (FPGA_OK != r)
    {
        fprintf(stderr, "Error allocating 2GB buffer\n");
        exit(1);
    }
    buf_2xGB[0] = 0;
    buf_2xGB[GB] = 0;

    uint8_t *buf_700x2MB;
    r = buffer_allocate((void*)&buf_700x2MB, MB * 2 * 700, FLAGS_2M);
    if (FPGA_OK != r)
    {
        fprintf(stderr, "Error allocating 2MB buffer\n");
        exit(1);
    }
    memset(buf_700x2MB, 0, MB * 2 * 700);

    uint8_t *buf_2000x4KB;
    r = buffer_allocate((void*)&buf_2000x4KB, KB * 4 * 2000, FLAGS_4K);
    if (FPGA_OK != r)
    {
        fprintf(stderr, "Error allocating 4KB buffer\n");
        exit(1);
    }
    memset(buf_2000x4KB, 0, KB * 4 * 2000);

    //
    // Tell VTP about the buffers
    //
    r = mpfVtpPrepareBuffer(mpf_handle, GB * 2, (void*)&buf_2xGB, FPGA_BUF_PREALLOCATED);
    assert(FPGA_OK == r);
    r = mpfVtpPrepareBuffer(mpf_handle, MB * 2 * 700, (void*)&buf_700x2MB, FPGA_BUF_PREALLOCATED);
    assert(FPGA_OK == r);
    r = mpfVtpPrepareBuffer(mpf_handle, KB * 4 * 2000, (void*)&buf_2000x4KB, FPGA_BUF_PREALLOCATED);
    assert(FPGA_OK == r);

    testVtpGetIOAddrVec(mpf_handle, buf_2xGB, "1GB");
    testVtpGetIOAddrVec(mpf_handle, buf_700x2MB, "2MB");
    testVtpGetIOAddrVec(mpf_handle, buf_2000x4KB, "4KB");

    // Done
    assert(FPGA_OK == buffer_release(buf_2000x4KB, KB * 4 * 2000));
    assert(FPGA_OK == buffer_release(buf_700x2MB, MB * 2 * 700));
    assert(FPGA_OK == buffer_release(buf_2xGB, GB * 2));

    r = mpfDisconnect(mpf_handle);
    assert(FPGA_OK == r);

    fpgaReleaseBuffer(accel_handle, wsid);
    fpgaClose(accel_handle);

    return 0;
}
