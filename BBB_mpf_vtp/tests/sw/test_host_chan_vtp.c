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

//
// Test one or more host memory interfaces, varying address alignment and
// burst sizes.
//

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <inttypes.h>
#include <uuid/uuid.h>
#include <time.h>
#include <immintrin.h>
#include <cpuid.h>

#include <opae/fpga.h>
#include <opae/mpf/mpf.h>

// State from the AFU's JSON file, extracted using OPAE's afu_json_mgr script
#include "afu_json_info.h"
#include "test_host_chan_vtp.h"

#define CACHELINE_BYTES 64
#ifndef CL
#define CL(x) ((x) * CACHELINE_BYTES)
#endif
#ifndef MB
#define MB(x) ((x) * 1048576)
#endif
#ifndef KB
#define KB(x) ((x) * 1024)
#endif

static const size_t default_bufsize = MB(4);

// Engine's address mode
typedef enum
{
    ADDR_MODE_IOADDR = 0,
    ADDR_MODE_HOST_PHYSICAL = 1,
    ADDR_MODE_VIRTUAL = 3
}
t_fpga_addr_mode;

const char* addr_mode_str[] =
{
    "IOADDR",
    "Host physical",
    "reserved",
    "Virtual"
};


//
// Hold shared memory buffer details for one engine
//
typedef struct
{
    volatile uint64_t *rd_buf;
    size_t rd_buf_size;

    volatile uint64_t *wr_buf;
    size_t wr_buf_size;

    uint32_t max_burst_size;
    uint32_t group;
    uint32_t eng_type;
    t_fpga_addr_mode addr_mode;
    bool natural_bursts;
    bool ordered_read_responses;
}
t_engine_buf;

static fpga_handle s_accel_handle;
static t_csr_handle_p s_csr_handle;
static bool s_is_ase;
static t_engine_buf* s_eng_bufs;
static double s_afu_mhz;

static char *engine_type[] = 
{
    "CCI-P",
    "Avalon",
    "AXI-MM",
    NULL
};


//
// Taken from https://github.com/pmem/pmdk/blob/master/src/libpmem2/x86_64/flush.h.
// The clflushopt instruction was added for Skylake and isn't in <immintrin.h>
// _mm_clflushopt() in many of the compilers currently in use.
//
static inline void
asm_clflushopt(const void *addr)
{
	asm volatile(".byte 0x66; clflush %0" : "+m" \
		(*(volatile char *)(addr)));
}

//
// Flush a range of lines from the cache hierarchy in the entire coherence
// domain. (All cores all sockets)
//
static void
flushRange(void* start, size_t len)
{
    uint8_t* cl = start;
    uint8_t* end = start + len;

    // Does the CPU support clflushopt?
    static bool checked_clflushopt;
    static bool supports_clflushopt;

    if (! checked_clflushopt)
    {
        checked_clflushopt = true;
        supports_clflushopt = false;

        unsigned int eax, ebx, ecx, edx;
        if (__get_cpuid_max(0, 0) >= 7)
        {
            __cpuid_count(7, 0, eax, ebx, ecx, edx);
            // bit_CLFLUSHOPT is (1 << 23)
            supports_clflushopt = (((1 << 23) & ebx) != 0);
            printf("#  Processor supports clflushopt: %d\n", supports_clflushopt);
        }
    }
    if (! supports_clflushopt) return;

    while (cl < end)
    {
        asm_clflushopt(cl);
        cl += CACHELINE_BYTES;
    }

    _mm_sfence();
}


//
// Allocate a buffer in I/O memory, shared with the FPGA.
//
static void*
allocSharedBuffer(
    mpf_handle_t mpf_handle,
    size_t size)
{
    fpga_result r;
    void* buf;

    r = mpfVtpPrepareBuffer(mpf_handle, size, (void*)&buf, 0);
    if (FPGA_OK != r) return NULL;

    return buf;
}


static void
initReadBuf(
    volatile uint64_t *buf,
    size_t n_bytes)
{
    uint64_t cnt = 1;

    // The data in the read buffers doesn't really matter as long as there are
    // unique values in each line. Reads will be checked with a hash (CRC).
    while (n_bytes -= sizeof(uint64_t))
    {
        *buf++ = cnt++;
    }
}


static void
initEngine(
    uint32_t e,
    mpf_handle_t mpf_handle,
    t_csr_handle_p csr_handle)
{
    // Get the maximum burst size for the engine.
    uint64_t r = csrEngRead(s_csr_handle, e, 0);
    s_eng_bufs[e].max_burst_size = r & 0x7fff;
    s_eng_bufs[e].natural_bursts = (r >> 15) & 1;
    s_eng_bufs[e].ordered_read_responses = (r >> 39) & 1;
    s_eng_bufs[e].addr_mode = (r >> 40) & 3;
    s_eng_bufs[e].group = (r >> 47) & 7;
    s_eng_bufs[e].eng_type = (r >> 35) & 7;
    uint32_t eng_num = (r >> 42) & 31;
    printf("#  Engine %d type: %s\n", e, engine_type[s_eng_bufs[e].eng_type]);
    printf("#  Engine %d max burst size: %d\n", e, s_eng_bufs[e].max_burst_size);
    printf("#  Engine %d natural bursts: %d\n", e, s_eng_bufs[e].natural_bursts);
    printf("#  Engine %d ordered read responses: %d\n", e, s_eng_bufs[e].ordered_read_responses);
    printf("#  Engine %d addressing mode: %s\n", e, addr_mode_str[s_eng_bufs[e].addr_mode]);
    printf("#  Engine %d group: %d\n", e, s_eng_bufs[e].group);

    if (eng_num != e)
    {
        printf("  Engine %d internal numbering mismatch (%d)\n", e, eng_num);
        exit(1);
    }

    // Separate read and write buffers.
    s_eng_bufs[e].rd_buf = allocSharedBuffer(mpf_handle, default_bufsize);
    assert(NULL != s_eng_bufs[e].rd_buf);
    s_eng_bufs[e].rd_buf_size = default_bufsize;
    initReadBuf(s_eng_bufs[e].rd_buf, s_eng_bufs[e].rd_buf_size);
    flushRange((void*)s_eng_bufs[e].rd_buf, default_bufsize);

    s_eng_bufs[e].wr_buf = allocSharedBuffer(mpf_handle, default_bufsize);
    assert(NULL != s_eng_bufs[e].wr_buf);
    s_eng_bufs[e].wr_buf_size = default_bufsize;

    // Set the buffer size mask. Only half the buffer is used so
    // bursts can flow a bit beyond the mask without concern for
    // overflow.
    csrEngWrite(csr_handle, e, 4, (default_bufsize / 2) / CL(1) - 1);
}


// The same hash is implemented in the read path in the hardware.
static uint32_t
computeExpectedReadHash(
    uint16_t *buf,
    uint32_t num_bursts,
    uint32_t burst_size)
{
    uint32_t hash = HASH32_DEFAULT_INIT;

    while (num_bursts--)
    {
        uint32_t num_lines = burst_size;
        while (num_lines--)
        {
            // Hash the low and high 16 bits of each line
            hash = hash32(hash, ((buf[31]) << 16) | buf[0]);
            buf += 32;
        }
    }

    return hash;
}


// Checksum is used when hardware reads may arrive out of order.
static uint32_t
computeExpectedReadSum(
    uint16_t *buf,
    uint32_t num_bursts,
    uint32_t burst_size)
{
    uint32_t sum = 0;

    while (num_bursts--)
    {
        uint32_t num_lines = burst_size;
        while (num_lines--)
        {
            // Hash the low and high 16 bits of each line
            sum += ((buf[31] << 16) | buf[0]);
            buf += 32;
        }
    }

    return sum;
}


// Check a write buffer to confirm that the FPGA engine wrote the
// expected values.
static bool
testExpectedWrites(
    uint64_t *buf,
    uint32_t num_bursts,
    uint32_t burst_size,
    uint32_t *line_index)
{
    *line_index = 0;
    uint64_t line_addr = (intptr_t)buf / CL(1);

    while (num_bursts--)
    {
        uint32_t num_lines = burst_size;
        while (num_lines--)
        {
            // The low word is the line address
            if (buf[0] != line_addr++) return false;
            // The high word is 0xdeadbeef
            if (buf[7] != 0xdeadbeef) return false;

            *line_index += 1;
            buf += 8;
        }
    }

    // Confirm that the next line is 0. This is the first line not
    // written by the FPGA.
    if (buf[0] != 0) return false;
    if (buf[7] != 0) return false;

    return true;
}


//
// Test that virtual address translation failures are handled properly.
//
static int
testVtpFailurePath(
    uint32_t num_engines,
    uint32_t num_g0_engines
)
{
    // The test only runs when there are multiple port groups
    if (num_g0_engines == num_engines)
    {
        printf("VTP translation error test required multiple engines.\n");
        return 0;
    }

    int n_errors = 0;

    // Use two engines for the test: 0 and the last.
    const uint32_t eg0 = 0;
    const uint32_t eg1 = num_engines - 1;
    const uint64_t emask = ((uint64_t)1 << eg1) | 1;

    printf("Testing VTP translation error path:\n");

    // Use the wrong buffers for the two engines by swapping them.
    // Different VTP instances are managing the two groups, so translation
    // should fail. The VTP page tables will not know about each
    // other's pinned buffers.
    csrEngWrite(s_csr_handle, eg0, 0, (intptr_t)s_eng_bufs[eg1].rd_buf / CL(1));
    csrEngWrite(s_csr_handle, eg0, 1, (intptr_t)s_eng_bufs[eg1].wr_buf / CL(1));
    csrEngWrite(s_csr_handle, eg1, 0, (intptr_t)s_eng_bufs[eg0].rd_buf / CL(1));
    csrEngWrite(s_csr_handle, eg1, 1, (intptr_t)s_eng_bufs[eg0].wr_buf / CL(1));

    // Set the maximum burst size to the smaller of the two engines
    uint64_t max_burst_size = s_eng_bufs[eg0].max_burst_size;
    if (max_burst_size > s_eng_bufs[eg1].max_burst_size)
        max_burst_size = s_eng_bufs[eg1].max_burst_size;

    uint64_t burst_size = 1;
    while (1)
    {
        uint64_t num_bursts = 1;
        while (num_bursts <= 2)
        {
            printf("  Testing %ld bursts of %ld flits:\n", num_bursts, burst_size);

            // Configure engine burst details
            csrEngWrite(s_csr_handle, eg0, 2, (num_bursts << 32) | burst_size);
            csrEngWrite(s_csr_handle, eg0, 3, (num_bursts << 32) | burst_size);
            csrEngWrite(s_csr_handle, eg1, 2, (num_bursts << 32) | burst_size);
            csrEngWrite(s_csr_handle, eg1, 3, (num_bursts << 32) | burst_size);

            // Since this is a failure test, we can't wait for the engines
            // to finish. Instead, we will wait for the translation error count
            // to change. Get the current counts.
            uint64_t err_cnt_csr_orig = csrEngGlobRead(s_csr_handle, 7);

            // Start your engines
            csrEnableEngines(s_csr_handle, emask);

            struct timespec wait_time;
            wait_time.tv_sec = 0;
            wait_time.tv_nsec = 1000000;

            // Loop until the test starts
            while (csrGetEnginesEnabled(s_csr_handle) == 0)
            {
                nanosleep(&wait_time, NULL);
            }

            // Loop until the CSRs change
            while (csrEngGlobRead(s_csr_handle, 7) == err_cnt_csr_orig)
            {
                nanosleep(&wait_time, NULL);
            }

            // Sleep a little more to let the bursts complete. There is a race
            // here, but we're just testing the error path. Building a more
            // complicated protocol is of questionable value.
            nanosleep(&wait_time, NULL);

            // Stop the engines
            csrDisableEngines(s_csr_handle, emask);

            // The error counter CSR has 4 16 bit counters for failed flits
            // seen. From the low bits, the order is group 0 read, group 0 write,
            // group 1 read, group 1 write.
            uint64_t err_cnt_csr = csrEngGlobRead(s_csr_handle, 7);

            for (int i = 0; i < 4; i += 1)
            {
                uint32_t n_flits = (uint16_t)(err_cnt_csr >> (16 * i)) -
                                   (uint16_t)(err_cnt_csr_orig >> (16 * i));
                if (i & 1)
                {
                    printf("    G%d write -- ", i >> 1);

                    // Writes -- flits is burst_size * num_bursts
                    if (n_flits != (burst_size * num_bursts))
                    {
                        printf("ERROR (expected %ld flits, found %d)\n",
                               burst_size * num_bursts, n_flits);
                        n_errors += 1;
                    }
                    else
                    {
                        printf("PASS  (%d flits)\n", n_flits);
                    }
                }
                else
                {
                    printf("    G%d read  -- ", i >> 1);

                    // Reads -- flits is num_bursts
                    if (n_flits != num_bursts)
                    {
                        printf("ERROR (expected %ld flits, found %d)\n",
                               num_bursts, n_flits);
                        n_errors += 1;
                    }
                    else
                    {
                        printf("PASS  (%d flits)\n", n_flits);
                    }
                }
            }

            num_bursts += 1;
        }

        if (burst_size == max_burst_size) break;
        burst_size = max_burst_size;
    }

    return n_errors;
}


static int
testSmallRegions(
    uint32_t num_engines,
    uint64_t emask
)
{
    int num_errors = 0;

    // What is the maximum burst size for the engines? It is encoded in CSR 0.
    uint64_t max_burst_size = 1024;
    bool natural_bursts = false;
    for (uint32_t e = 0; e < num_engines; e += 1)
    {
        if (emask & ((uint64_t)1 << e))
        {
            if (max_burst_size > s_eng_bufs[e].max_burst_size)
                max_burst_size = s_eng_bufs[e].max_burst_size;

            natural_bursts |= s_eng_bufs[e].natural_bursts;
        }
    }

    printf("Testing emask 0x%lx, maximum burst size %ld:\n", emask, max_burst_size);

    uint64_t burst_size = 1;
    while (burst_size <= max_burst_size)
    {
        uint64_t num_bursts = 1;
        while (num_bursts < 20)
        {
            //
            // Test only reads (mode 1), only writes (mode 2) and
            // read+write (mode 3).
            //
            for (int mode = 1; mode <= 3; mode += 1)
            {
                for (uint32_t e = 0; e < num_engines; e += 1)
                {
                    if (emask & ((uint64_t)1 << e))
                    {
                        // Read buffer base address (0 disables reads)
                        if (mode & 1)
                            csrEngWrite(s_csr_handle, e, 0,
                                        (intptr_t)s_eng_bufs[e].rd_buf / CL(1));
                        else
                            csrEngWrite(s_csr_handle, e, 0, 0);

                        // Write buffer base address (0 disables writes)
                        if (mode & 2)
                            csrEngWrite(s_csr_handle, e, 1,
                                        (intptr_t)s_eng_bufs[e].wr_buf / CL(1));
                        else
                            csrEngWrite(s_csr_handle, e, 1, 0);

                        // Clear the write buffer
                        memset((void*)s_eng_bufs[e].wr_buf, 0,
                               s_eng_bufs[e].wr_buf_size);
                        flushRange((void*)s_eng_bufs[e].wr_buf, default_bufsize);

                        // Configure engine burst details
                        csrEngWrite(s_csr_handle, e, 2,
                                    (num_bursts << 32) | burst_size);
                        csrEngWrite(s_csr_handle, e, 3,
                                    (num_bursts << 32) | burst_size);
                    }
                }

                char *mode_str = "R+W:  ";
                if (mode == 1)
                    mode_str = "Read: ";
                if (mode == 2)
                {
                    mode_str = "Write:";
                }

                printf("  %s %2ld bursts of %2ld lines", mode_str,
                       num_bursts, burst_size);

                // Start your engines
                csrEnableEngines(s_csr_handle, emask);

                // Wait for engine to complete. Checking csrGetEnginesEnabled()
                // resolves a race between the request to start an engine
                // and the engine active flag going high. Execution is done when
                // the engine is enabled and the active flag goes low.
                struct timespec wait_time;
                wait_time.tv_sec = 0;
                wait_time.tv_nsec = 1000000;
                while ((csrGetEnginesEnabled(s_csr_handle) == 0) ||
                       csrGetEnginesActive(s_csr_handle))
                {
                    nanosleep(&wait_time, NULL);
                }

                // Stop the engine
                csrDisableEngines(s_csr_handle, emask);

                bool pass = true;
                for (uint32_t e = 0; e < num_engines; e += 1)
                {
                    if (emask & ((uint64_t)1 << e))
                    {
                        // Compute the expected hash and sum
                        uint32_t expected_hash = 0;
                        uint32_t expected_sum = 0;
                        if (mode & 1)
                        {
                            expected_hash = computeExpectedReadHash(
                                (uint16_t*)s_eng_bufs[e].rd_buf,
                                num_bursts, burst_size);

                            expected_sum = computeExpectedReadSum(
                                (uint16_t*)s_eng_bufs[e].rd_buf,
                                num_bursts, burst_size);
                        }

                        // Get the actual hash
                        uint32_t actual_hash = 0;
                        uint32_t actual_sum = 0;
                        if (mode & 1)
                        {
                            uint64_t check_val = csrEngRead(s_csr_handle, e, 5);
                            actual_hash = (uint32_t)check_val;
                            actual_sum = check_val >> 32;
                        }

                        // Test that writes arrived
                        bool writes_ok = true;
                        uint32_t write_error_line;
                        if (mode & 2)
                        {
                            flushRange((void*)s_eng_bufs[e].wr_buf, default_bufsize);

                            writes_ok = testExpectedWrites(
                                (uint64_t*)s_eng_bufs[e].wr_buf,
                                num_bursts, burst_size, &write_error_line);
                        }

                        if (expected_sum != actual_sum)
                        {
                            pass = false;
                            num_errors += 1;
                            printf("\n - FAIL %d: read ERROR expected sum 0x%08x found 0x%08x\n",
                                   e, expected_sum, actual_sum);
                        }
                        else if ((expected_hash != actual_hash) &&
                                 s_eng_bufs[e].ordered_read_responses)
                        {
                            pass = false;
                            num_errors += 1;
                            printf("\n - FAIL %d: read ERROR expected hash 0x%08x found 0x%08x\n",
                                   e, expected_hash, actual_hash);
                        }
                        else if (! writes_ok)
                        {
                            pass = false;
                            num_errors += 1;
                            printf("\n - FAIL %d: write ERROR line index 0x%x\n", e, write_error_line);
                        }
                    }
                }

                if (pass) printf(" - PASS\n");
            }

            num_bursts = (num_bursts * 2) + 1;
        }

        if (natural_bursts)
        {
            // Natural burst sizes -- test powers of 2
            burst_size <<= 1;
        }
        else
        {
            // Test every burst size up to 4 and then sparsely after that
            if ((burst_size < 4) || (burst_size == max_burst_size))
                burst_size += 1;
            else
            {
                burst_size = burst_size * 3 + 1;
                if (burst_size > max_burst_size) burst_size = max_burst_size;
            }
        }
    }

    return num_errors;
}


//
// Configure (but don't start) a continuous bandwidth test on one engine.
//
static int
configBandwidth(
    uint32_t e,
    uint32_t burst_size,
    uint32_t mode            // 1 - read, 2 - write, 3 - read+write
)
{
    // Read buffer base address (0 disables reads)
    if (mode & 1)
    {
        csrEngWrite(s_csr_handle, e, 0,
                    (intptr_t)s_eng_bufs[e].rd_buf / CL(1));
    }
    else
    {
        csrEngWrite(s_csr_handle, e, 0, 0);
    }

    // Write buffer base address (0 disables writes)
    if (mode & 2)
    {
        csrEngWrite(s_csr_handle, e, 1,
                    (intptr_t)s_eng_bufs[e].wr_buf / CL(1));
    }
    else
    {
        csrEngWrite(s_csr_handle, e, 1, 0);
    }

    // Configure engine burst details
    csrEngWrite(s_csr_handle, e, 2, burst_size);
    csrEngWrite(s_csr_handle, e, 3, burst_size);

    return 0;
}


//
// Run a bandwidth test (configured already with configBandwidth) on the set
// of engines indicated by emask.
//
static int
runBandwidth(
    uint32_t num_engines,
    uint64_t emask
)
{
    assert(emask != 0);

    csrEnableEngines(s_csr_handle, emask);

    // Wait for them to start
    struct timespec wait_time;
    wait_time.tv_sec = 0;
    wait_time.tv_nsec = 1000000;
    while (csrGetEnginesEnabled(s_csr_handle) == 0)
    {
        nanosleep(&wait_time, NULL);
    }

    // Let them run for a while
    usleep(s_is_ase ? 10000000 : 100000);
    
    csrDisableEngines(s_csr_handle, emask);

    // Wait for them to stop
    while (csrGetEnginesActive(s_csr_handle))
    {
        nanosleep(&wait_time, NULL);
    }

    if (s_afu_mhz == 0)
    {
        s_afu_mhz = csrGetClockMHz(s_csr_handle);
        printf("  AFU clock is %.1f MHz\n", s_afu_mhz);
    }

    uint64_t cycles = csrGetClockCycles(s_csr_handle);
    uint64_t read_lines = 0;
    uint64_t write_lines = 0;
    for (uint32_t e = 0; e < num_engines; e += 1)
    {
        if (emask & ((uint64_t)1 << e))
        {
            read_lines += csrEngRead(s_csr_handle, e, 2);
            write_lines += csrEngRead(s_csr_handle, e, 3);
        }
    }

    if (!read_lines && !write_lines)
    {
        printf("  FAIL: no memory traffic detected!\n");
        return 1;
    }

    double read_bw = 64 * read_lines * s_afu_mhz / (1000.0 * cycles);
    double write_bw = 64 * write_lines * s_afu_mhz / (1000.0 * cycles);

    if (! write_lines)
    {
        printf("  Read GiB/s:  %f\n", read_bw);
    }
    else if (! read_lines)
    {
        printf("  Write GiB/s: %f\n", write_bw);
    }
    else
    {
        printf("  R+W GiB/s:   %f (read %f, write %f)\n",
               read_bw + write_bw, read_bw, write_bw);
    }

    return 0;
}


static void
printVtpStats(
    mpf_handle_t mpf_handle,
    uint32_t group_id
)
{
    if (! mpfVtpIsAvailable(mpf_handle)) return;

    mpf_vtp_stats vtp_stats;
    mpfVtpGetStats(mpf_handle, &vtp_stats);

    printf("\n# VTP group %d statistics:\n", group_id);
    printf("#   VTP failed:            %ld\n", vtp_stats.numFailedTranslations);
    if (vtp_stats.numFailedTranslations)
    {
        printf("#   VTP failed addr:       0x%lx\n", (uint64_t)vtp_stats.ptWalkLastVAddr);
    }
    printf("#   VTP PT walk cycles:    %ld\n", vtp_stats.numPTWalkBusyCycles);
    printf("#   VTP L2 4KB hit / miss: %ld / %ld\n",
           vtp_stats.numTLBHits4KB, vtp_stats.numTLBMisses4KB);
    printf("#   VTP L2 2MB hit / miss: %ld / %ld\n",
           vtp_stats.numTLBHits2MB, vtp_stats.numTLBMisses2MB);

    double cycles_per_pt = (double)vtp_stats.numPTWalkBusyCycles /
                           (double)(vtp_stats.numTLBMisses4KB + vtp_stats.numTLBMisses2MB);

    double usec_per_cycle = 0;
    if (s_afu_mhz) usec_per_cycle = 1.0 / (double)s_afu_mhz;
    printf("#   VTP usec / PT walk:    %f\n\n", cycles_per_pt * usec_per_cycle);
}


int
testHostChanVtp(
    int argc,
    char *argv[],
    fpga_handle accel_handle,
    t_csr_handle_p csr_handle,
    bool is_ase,
    bool test_vtp_fail)
{
    fpga_result r;
    int result = 0;
    s_accel_handle = accel_handle;
    s_csr_handle = csr_handle;
    s_is_ase = is_ase;

    printf("# Test ID: %016" PRIx64 " %016" PRIx64 "\n",
           csrEngGlobRead(csr_handle, 1),
           csrEngGlobRead(csr_handle, 0));

    uint32_t num_engines = csrGetNumEngines(csr_handle);
    uint32_t num_grp_engines[2];
    uint32_t engine_groups = csrEngGlobRead(csr_handle, 2);
    num_grp_engines[0] = (uint8_t)engine_groups;
    num_grp_engines[1] = (uint8_t)(engine_groups >> 8);
    printf("# Engines: %d (g0 %d, g1 %d)\n", num_engines,
           num_grp_engines[0], num_grp_engines[1]);
    assert(0 != num_grp_engines[0]);

    //
    // There may be two separate MPF instances. The first manages the
    // primary interface. The second is a VTP instance for translating
    // the group 1 ports using what may be a separate physical address
    // space. MPF buffers must be managed using the MPF handle corresponding
    // to the proper instance!
    //
    mpf_handle_t mpf_handle[2];
    r = mpfConnect(accel_handle, 0, 0, &mpf_handle[0], MPF_FLAG_FEATURE_ID, 1);
    assert(FPGA_OK == r);
    if (num_grp_engines[1])
    {
        r = mpfConnect(accel_handle, 0, 0, &mpf_handle[1], MPF_FLAG_FEATURE_ID, 2);
        assert(FPGA_OK == r);
        assert(mpfVtpIsAvailable(mpf_handle[1]));

        // Is this VTP instance for a near-memory controller in physical mode?
        if (mpfVtpAddrModeIsPhysical(mpf_handle[1]))
        {
            // Yes. Configure it. We will eventually have to pass in a memory
            // controller number. For now, 0 works.
            r = mpfVtpBindToNearMemCtrl(mpf_handle[1], 0);
            assert(FPGA_OK == r);
        }
    }

    // Force smaller page mapping to trigger more MPF activity
    mpfVtpSetMaxPhysPageSize(mpf_handle[0], MPF_VTP_PAGE_4KB);

    // Allocate memory buffers for each engine
    s_eng_bufs = malloc(num_engines * sizeof(t_engine_buf));
    assert(NULL != s_eng_bufs);
    for (uint32_t e = 0; e < num_engines; e += 1)
    {
        // Pick the proper MPF handle. The memory will be translatable
        // in the FPGA only by the VTP instance associated with mpf_idx.
        // (Buffers could be made visible on both by managing the same
        // virtual buffer in both MPF instances.)
        uint32_t mpf_idx = (e >= num_grp_engines[0]) ? 1 : 0;

        initEngine(e, mpf_handle[mpf_idx], csr_handle);
    }
    printf("\n");
    
    if (test_vtp_fail)
    {
        result = testVtpFailurePath(num_engines, num_grp_engines[0]);
        goto done;
    }

    // Test each engine separately
    for (uint32_t e = 0; e < num_engines; e += 1)
    {
        if (testSmallRegions(num_engines, (uint64_t)1 << e))
        {
            // Quit on error
            result = 1;
            goto done;
        }
    }

    // Test all the engines at once
    if (num_engines > 1)
    {
        if (testSmallRegions(num_engines, ((uint64_t)1 << num_engines) - 1))
        {
            // Quit on error
            result = 1;
            goto done;
        }
    }

    // Bandwidth test each engine individually
    for (uint32_t e = 0; e < num_engines; e += 1)
    {
        uint64_t burst_size = 1;
        while (burst_size <= s_eng_bufs[e].max_burst_size)
        {
            printf("\nTesting engine %d, burst size %ld:\n", e, burst_size);

            for (int mode = 1; mode <= 3; mode += 1)
            {
                configBandwidth(e, burst_size, mode);
                runBandwidth(num_engines, (uint64_t)1 << e);
            }

            if (s_eng_bufs[e].natural_bursts)
            {
                // Natural burst sizes -- test powers of 2
                burst_size <<= 1;
            }
            else
            {
                burst_size += 1;
                if ((burst_size < s_eng_bufs[e].max_burst_size) && (burst_size == 5))
                {
                    burst_size = s_eng_bufs[e].max_burst_size;
                }
            }
        }
    }

    // Bandwidth test all engines together
    if (num_engines > 1)
    {
        printf("\nTesting all engines, max burst size:\n");

        for (int mode = 1; mode <= 3; mode += 1)
        {
            for (uint32_t e = 0; e < num_engines; e += 1)
            {
                configBandwidth(e, s_eng_bufs[e].max_burst_size, mode);
            }
            runBandwidth(num_engines, ((uint64_t)1 << num_engines) - 1);
        }
    }

    // Release buffers
  done:
    for (uint32_t e = 0; e < num_engines; e += 1)
    {
        // Pick the proper MPF handle
        uint32_t mpf_idx = (e >= num_grp_engines[0]) ? 1 : 0;

        mpfVtpReleaseBuffer(mpf_handle[mpf_idx], (void*)s_eng_bufs[e].rd_buf);
        mpfVtpReleaseBuffer(mpf_handle[mpf_idx], (void*)s_eng_bufs[e].wr_buf);
    }

    printVtpStats(mpf_handle[0], 0);
    mpfDisconnect(mpf_handle[0]);

    if (num_grp_engines[1])
    {
        printVtpStats(mpf_handle[1], 1);
        mpfDisconnect(mpf_handle[1]);
    }

    return result;
}
