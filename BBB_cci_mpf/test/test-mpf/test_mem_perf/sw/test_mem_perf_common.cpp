//
// Copyright (c) 2016, Intel Corporation
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

#include "test_mem_perf.h"
// Generated from the AFU JSON file by afu_json_mgr
#include "afu_json_info.h"

#include <unistd.h>
#include <time.h>

const char* testAFUID()
{
    return AFU_ACCEL_UUID;
}

bool
TEST_MEM_PERF::initMem(
    bool enableWarmup,
    bool cached,
    uint64_t rd_prefetchInterval,
    uint64_t rd_prefetchDistance,
    uint64_t wr_prefetchInterval,
    uint64_t wr_prefetchDistance)
{
    // Allocate memory for control
    dsm_buf_handle = this->allocBuffer(getpagesize());
    dsm = reinterpret_cast<volatile uint64_t*>(dsm_buf_handle->c_type());
    if (dsm == NULL) return false;
    memset((void*)dsm, 0, getpagesize());

    // Allocate memory for read/write tests.  The HW indicates the size
    // of the memory buffer in CSR 0.
    uint64_t addr_info = readTestCSR(0);
    
    // Low 16 bits holds the number of line address bits required
    buffer_bytes = CL(1) * (1LL << uint16_t(addr_info));
    cout << "# Allocating two " << buffer_bytes / (1024 * 1024) << "MB test buffers..." << endl;

    // Allocate two buffers worth plus an extra 2MB page to allow for alignment
    // changes.
    buffer_handle = this->allocBuffer(2 * buffer_bytes + 2048 * 1024);
    rd_mem = (uint64_t*)(buffer_handle->c_type());
    if (rd_mem == NULL) return false;
    // Align to minimize cache conflicts
    wr_mem = (uint64_t*)(uint64_t(rd_mem) + buffer_bytes + 512 * CL(1));

    memset((void*)rd_mem, 0, buffer_bytes);
    memset((void*)wr_mem, 0, buffer_bytes);

    //
    // Configure the HW test
    //
    writeTestCSR(1, uint64_t(dsm) / CL(1));

    if (enableWarmup)
    {
        warmUp(wr_mem, buffer_bytes, cached);
        warmUp(rd_mem, buffer_bytes, cached);
    }

    writeTestCSR(2, uint64_t(rd_mem) / CL(1));
    writeTestCSR(3, uint64_t(wr_mem) / CL(1));

    if (rd_prefetchInterval != 0)
    {
        if (((rd_prefetchInterval - 1) & rd_prefetchInterval) || (rd_prefetchInterval > 8))
        {
            cerr << "Read prefetch interval must be 1, 2, 4 or 8 (4KB pages)" << endl;
            exit(1);
        }

        writeTestCSR(7, rd_prefetchInterval |
                        ((uint64_t(rd_mem) + (4096 * rd_prefetchDistance)) / CL(1)));
    }

    if (wr_prefetchInterval != 0)
    {
        if (((wr_prefetchInterval - 1) & wr_prefetchInterval) || (wr_prefetchInterval > 8))
        {
            cerr << "Read prefetch interval must be 1, 2, 4 or 8 (4KB pages)" << endl;
            exit(1);
        }

        writeTestCSR(8, wr_prefetchInterval |
                        ((uint64_t(wr_mem) + (4096 * wr_prefetchDistance)) / CL(1)));
    }

    // Wait for the HW to be ready
    while ((readTestCSR(7) & 3) != 0)
    {
        sleep(1);
    }

    return true;
}


int
TEST_MEM_PERF::runTest(const t_test_config* config, t_test_stats* stats)
{
    // Clear the FPGA-side cache?
    if (config->clear_caches)
    {
        memset((void*)rd_mem, 0, config->buf_lines * CL(1));
        memset((void*)wr_mem, 0, config->buf_lines * CL(1));
    }

    // Ensure that the requested number of cycles and the actual executed
    // cycle count fit in a 32 bit counter.  We assume the test won't run
    // for more than 2x the requested length, which had better be the case.
    assert(config->cycles == (config->cycles & 0x7fffffff));

    assert((config->mcl & config->stride) == 0);
    assert((config->buf_lines & (config->buf_lines - 1)) == 0);
    assert(config->stride <= 0xffff);

    // Read baseline values of counters.  We'll read them again after the
    // test and compute the difference.
    stats->read_cache_line_hits = readCommonCSR(CCI_TEST::CSR_COMMON_CACHE_RD_HITS);
    stats->write_cache_line_hits = readCommonCSR(CCI_TEST::CSR_COMMON_CACHE_WR_HITS);
    stats->vl0_rd_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VL0_RD_LINES);
    stats->vl0_wr_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VL0_WR_LINES);
    stats->vh0_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VH0_LINES);
    stats->vh1_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VH1_LINES);
    stats->read_almost_full_cycles = readCommonCSR(CCI_TEST::CSR_COMMON_RD_ALMOST_FULL_CYCLES);
    stats->write_almost_full_cycles = readCommonCSR(CCI_TEST::CSR_COMMON_WR_ALMOST_FULL_CYCLES);

    // Mask of active memory window
    writeTestCSR(4, config->buf_lines - 1);
    // Maximum outstanding reads and writes. If the value is 0 convert it to
    // the maximum.
    uint64_t rd_req_max_credits = config->rd_req_max_credits - 1;
    if (rd_req_max_credits == 0) rd_req_max_credits = 1;
    uint64_t wr_req_max_credits = config->wr_req_max_credits - 1;
    if (wr_req_max_credits == 0) wr_req_max_credits = 1;
    writeTestCSR(6, (wr_req_max_credits << 32) | (rd_req_max_credits));

    // Start the test
    writeTestCSR(5, (uint64_t(config->stride) << 8) |
                    (uint64_t(config->vc) << 6) |
                    (uint64_t(config->mcl) << 4) |
                    (uint64_t(config->wrline_m) << 3) |
                    (uint64_t(config->rdline_s) << 2) |
                    (uint64_t(config->enable_writes) << 1) |
                    uint64_t(config->enable_reads));
    writeTestCSR(0, config->cycles);

    // Wait time for something to happen
    struct timespec ms;
    // Longer when simulating
    ms.tv_sec = (hwIsSimulated() ? 2 : 0);
    ms.tv_nsec = 2500000;

    uint64_t iter_state_end = 0;

    // Wait for test to signal it is complete
    while (*dsm == 0)
    {
        nanosleep(&ms, NULL);

        // Is the test done but not writing to DSM?  Could be a bug.
        uint8_t state = (readTestCSR(7) >> 8) & 255;
        if (state > 1)
        {
            if (iter_state_end++ == 5)
            {
                // Give up and signal an error
                break;
            }
        }
    }

    stats->actual_cycles = *dsm;
    // Run length in seconds
    stats->run_sec = double(stats->actual_cycles) /
                     (double(getAFUMHz()) * 1000.0 * 1000.0);

    totalCycles += config->cycles;

    stats->read_lines = readTestCSR(4);
    stats->write_lines = readTestCSR(5);

    stats->read_cache_line_hits = readCommonCSR(CCI_TEST::CSR_COMMON_CACHE_RD_HITS) - stats->read_cache_line_hits;
    stats->write_cache_line_hits = readCommonCSR(CCI_TEST::CSR_COMMON_CACHE_WR_HITS) - stats->write_cache_line_hits;
    stats->vl0_rd_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VL0_RD_LINES) - stats->vl0_rd_lines;
    stats->vl0_wr_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VL0_WR_LINES) - stats->vl0_wr_lines;
    stats->vh0_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VH0_LINES) - stats->vh0_lines;
    stats->vh1_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VH1_LINES) - stats->vh1_lines;
    stats->read_almost_full_cycles = readCommonCSR(CCI_TEST::CSR_COMMON_RD_ALMOST_FULL_CYCLES) - stats->read_almost_full_cycles;
    stats->write_almost_full_cycles = readCommonCSR(CCI_TEST::CSR_COMMON_WR_ALMOST_FULL_CYCLES) - stats->write_almost_full_cycles;

    // Inflight counters are in DSM.
    stats->read_max_inflight_lines = dsm[1] & 0xffffffff;
    stats->write_max_inflight_lines = dsm[1] >> 32;

    if (stats->actual_cycles == 0)
    {
        // Error!
        dbgRegDump(readTestCSR(7));
        cerr << "WARNING : actual_cycles => 0" << endl;
        return 1;
    }

    stats->read_average_latency = (stats->read_lines ? dsm[2] / stats->read_lines : 0);
    stats->write_average_latency = (stats->write_lines ? dsm[3] / stats->write_lines : 0);

    *dsm = 0;

    return 0;
}


int
TEST_MEM_PERF::runTestN(const t_test_config* config, t_test_stats* stats, int n)
{
    int r = 0;
    t_test_stats stats_single;

    memset(stats, 0, sizeof(t_test_stats));

    // Sum results from all runs
    for (int i = 0; i < n; i += 1)
    {
        r |= runTest(config, &stats_single);

        stats->actual_cycles += stats_single.actual_cycles;
        stats->run_sec += stats_single.run_sec;

        stats->read_lines += stats_single.read_lines;
        stats->write_lines += stats_single.write_lines;
        stats->read_cache_line_hits += stats_single.read_cache_line_hits;
        stats->write_cache_line_hits += stats_single.write_cache_line_hits;
        stats->vl0_rd_lines += stats_single.vl0_rd_lines;
        stats->vl0_wr_lines += stats_single.vl0_wr_lines;
        stats->vh0_lines += stats_single.vh0_lines;
        stats->vh1_lines += stats_single.vh1_lines;
        stats->read_almost_full_cycles += stats_single.read_almost_full_cycles;
        stats->write_almost_full_cycles += stats_single.write_almost_full_cycles;

        if (stats->read_max_inflight_lines < stats_single.read_max_inflight_lines)
        {
            stats->read_max_inflight_lines = stats_single.read_max_inflight_lines;
        }
        stats->read_average_latency += stats_single.read_average_latency;
        if (stats->write_max_inflight_lines < stats_single.write_max_inflight_lines)
        {
            stats->write_max_inflight_lines = stats_single.write_max_inflight_lines;
        }
        stats->write_average_latency += stats_single.write_average_latency;
    }

    // Convert sums to avarages
    stats->actual_cycles /= n;
    stats->run_sec /= n;

    stats->read_lines /= n;
    stats->write_lines /= n;
    stats->read_cache_line_hits /= n;
    stats->write_cache_line_hits /= n;
    stats->vl0_rd_lines /= n;
    stats->vl0_wr_lines /= n;
    stats->vh0_lines /= n;
    stats->vh1_lines /= n;
    stats->read_almost_full_cycles /= n;
    stats->write_almost_full_cycles /= n;

    stats->read_average_latency /= n;
    stats->write_average_latency /= n;

    return r;
}


void
TEST_MEM_PERF::warmUp(void* buf, uint64_t n_bytes, bool cached)
{
    // Warm up VTP by stepping across 4K pages
    t_test_config config;
    memset(&config, 0, sizeof(config));

    // Read from the buffer to be warmed up
    writeTestCSR(2, uint64_t(buf) / CL(1));
    writeTestCSR(3, uint64_t(buf) / CL(1));

    // Give the warm-up code 10x the number of cycles needed to request
    // reads of each page.  The later pages don't matter much anyway, so
    // this is plenty of time for the early part of the buffer.
    config.cycles = 10 * n_bytes / 4096;
    config.buf_lines = n_bytes / CL(1);
    config.stride = 4096 / CL(1);
    config.vc = 2;
    config.enable_writes = 1;
    config.wrline_m = cached;

    t_test_stats stats;
    runTest(&config, &stats);

    // Warm up cache by writing the first 2K lines in the buffer
    if (cached)
    {
        config.cycles = 32768;
        config.buf_lines = 2048;
        config.stride = 1;
        config.vc = 1;
        runTest(&config, &stats);
    }
}


uint64_t
TEST_MEM_PERF::testNumCyclesExecuted()
{
    return totalCycles;
}


void
TEST_MEM_PERF::dbgRegDump(uint64_t r)
{
    uint64_t fiu_state = readCommonCSR(CSR_COMMON_FIU_STATE);
    uint64_t fiu_active_c0_lines = readTestCSR(8);
    uint64_t fiu_active_c1_lines = readTestCSR(9);

    cerr << "Test state:" << endl
         << "  State:                " << ((r >> 8) & 255) << endl
         << "  AFU edge C0 Alm Full: " << (r & 1) << endl
         << "  AFU edge C1 Alm Full: " << ((r >> 1) & 1) << endl
         << "  MPF C0 Not Empty:     " << ((r >> 2) & 1) << endl
         << "  MPF C1 Not Empty:     " << ((r >> 3) & 1) << endl
         << "  FIU C0 Alm Full:      " << (fiu_state & 1) << endl
         << "  FIU C1 Alm Full:      " << ((fiu_state >> 1) & 1) << endl
         << "  FIU error:            " << ((fiu_state >> 2) & 1) << endl
         << "  FIU C0 Active Lines:  " << fiu_active_c0_lines << endl
         << "  FIU C1 Active Lines:  " << fiu_active_c1_lines << endl
        ;
}
