// Copyright(c) 2019, Intel Corporation
//
// Redistribution  and  use  in source  and  binary  forms,  with  or  without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of  source code  must retain the  above copyright notice,
//   this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// * Neither the name  of Intel Corporation  nor the names of its contributors
//   may be used to  endorse or promote  products derived  from this  software
//   without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED TO,  THE
// IMPLIED WARRANTIES OF  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT  SHALL THE COPYRIGHT OWNER  OR CONTRIBUTORS BE
// LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY,  OR
// CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT LIMITED  TO,  PROCUREMENT  OF
// SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  DATA, OR PROFITS;  OR BUSINESS
// INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,  WHETHER IN
// CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include "test_spec_load.h"
// Generated from the AFU JSON file by afu_json_mgr
#include "afu_json_info.h"

#include <unistd.h>
#include <time.h>
#include <boost/format.hpp>
#include <boost/algorithm/string.hpp>
#include <stdlib.h>
#include <sys/mman.h>


// ========================================================================
//
// Each test must provide these functions used by main to find the
// specific test instance.
//
// ========================================================================

const char* testAFUID()
{
    return AFU_ACCEL_UUID;
}

void testConfigOptions(po::options_description &desc)
{
    // Add test-specific options
    desc.add_options()
        ("rd-engines", po::value<int>()->default_value(1), "Number of streaming read engines")
        ("repeat", po::value<int>()->default_value(1), "Number of repetitions")
        ("ts", po::value<int>()->default_value(1), "Test length (seconds)")
        ;
}

CCI_TEST* allocTest(const po::variables_map& vm, SVC_WRAPPER& svc)
{
    return new TEST_SPEC_LOAD(vm, svc);
}


// ========================================================================
//
// Random traffic test.
//
// ========================================================================

int TEST_SPEC_LOAD::test()
{
    n_rd_engines = vm["rd-engines"].as<int>();
    uint32_t max_rd_engines = 0xff & (readTestCSR(0) >> 8);
    if ((n_rd_engines < 1) || (n_rd_engines > max_rd_engines))
    {
        cerr << "Number of read engines must be between 1 and " << max_rd_engines << endl;
        exit(1);
    }

    // Allocate memory for control
    auto dsm_buf_handle = this->allocBuffer(getpagesize());
    auto dsm = reinterpret_cast<volatile uint64_t*>(dsm_buf_handle->c_type());
    assert(NULL != dsm);
    memset((void*)dsm, 0, getpagesize());

    genBuffers();

    // Result buffer address
    writeTestCSR(1, uint64_t(dsm));
    // Last read engine index
    writeTestCSR(2, n_rd_engines - 1);

    // Configure buffers
    for (int e = 0; e < n_rd_engines; e++)
    {
        // Set the engine index being configured
        writeTestCSR(3, e);
        // Buffer base address
        writeTestCSR(4, (uint64_t)(mem_buf_handles[e]->c_type()));
        // Expected hash
        writeTestCSR(5, mem_buf_hashes[e]);
    }

    uint32_t run_sec = uint64_t(vm["ts"].as<int>());
    uint64_t repetitions = uint64_t(vm["repeat"].as<int>());
    uint64_t iter = 0;

    while (repetitions--)
    {
        cout << endl << "Iteration " << iter << ":" << endl;

        uint64_t vl0_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VL0_RD_LINES) +
                             readCommonCSR(CCI_TEST::CSR_COMMON_VL0_WR_LINES);
        uint64_t vh0_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VH0_LINES);
        uint64_t vh1_lines = readCommonCSR(CCI_TEST::CSR_COMMON_VH1_LINES);

        // Start the test
        writeTestCSR(0, 1);

        sleep(run_sec);

        // Stop the test
        writeTestCSR(0, 0);

        // Wait for test to signal it is complete
        while (*dsm == 0)
        {
        }

        while (readTestCSR(0) & 3)
        {
            sleep(1);
        }

        uint64_t vl0_lines_n = readCommonCSR(CCI_TEST::CSR_COMMON_VL0_RD_LINES) +
                               readCommonCSR(CCI_TEST::CSR_COMMON_VL0_WR_LINES);
        uint64_t vh0_lines_n = readCommonCSR(CCI_TEST::CSR_COMMON_VH0_LINES);
        uint64_t vh1_lines_n = readCommonCSR(CCI_TEST::CSR_COMMON_VH1_LINES);

        cout << "    VL0 " << vl0_lines_n - vl0_lines
             << " : VH0 " << vh0_lines_n - vh0_lines
             << " : VH1 " << vh1_lines_n - vh1_lines
             << endl;
        vl0_lines = vl0_lines_n;
        vh0_lines = vh0_lines_n;
        vh1_lines = vh1_lines_n;

        for (int e = 0; e < n_rd_engines; e++)
        {
            // Set the engine index being probed
            writeTestCSR(3, e);
            uint64_t trips = readTestCSR(3);
            uint64_t dropped_reads = readTestCSR(5);
            uint64_t spec_errors = readTestCSR(6);
            cout << "    Engine 0 trips: " << trips
                 << ", dropped reads: " << dropped_reads
                 << ", spec errors: " << spec_errors
                 << endl;
        }

        uint64_t error_mask = readTestCSR(2);
        if (0 != error_mask)
        {
            cout << "ERROR: engine error mask 0x" << hex << error_mask << dec << endl;
            break;
        }

        for (int e = 0; e < n_rd_engines; e++)
        {
            // Set the engine index being probed
            writeTestCSR(3, e);
            uint64_t trips = readTestCSR(3);
            uint64_t last_hash = readTestCSR(4);
            assert((trips == 0) || (last_hash == mem_buf_hashes[e]));
        }

        iter += 1;
    }

    return 0;
}


uint64_t
TEST_SPEC_LOAD::testNumCyclesExecuted()
{
    return readTestCSR(1);
}


int
TEST_SPEC_LOAD::genBuffers()
{
    mem_buf_handles = new fpga::types::shared_buffer::ptr_t[n_rd_engines];
    mem_buf_sizes = new size_t[n_rd_engines];
    mem_buf_hashes = new uint32_t[n_rd_engines];
    assert(NULL != mem_buf_handles);

    // The first pass allocates the buffers
    for (int e = 0; e < n_rd_engines; e++)
    {
        size_t n_bytes;
        size_t n_alloc_bytes;

        int flags = (MAP_PRIVATE | MAP_ANONYMOUS);

        // Pick a size for each buffer. Usually use a few 4KB pages. Sometimes use
        // 2MB pages.
        //
        // Allocate an extra page to reserve the virtual space. The extra page
        // will be unmapped before the test begins in order to ensure there
        // is no valid mapping.
        if ((e & 3) == 3)
        {
            n_bytes = 2048 * 1024;
            n_alloc_bytes = n_bytes + 2048 * 1024;
            flags |= MAP_HUGETLB;
        }
        else
        {
            n_bytes = 4096 * ((e & 3) + 1);
            n_alloc_bytes = n_bytes + 4096;
        }

        void* buf = mmap(NULL, n_alloc_bytes, (PROT_READ | PROT_WRITE), flags, -1, 0);
        if (buf == MAP_FAILED)
        {
            cerr << "Failed to mmap " << n_alloc_bytes << " byte buffer" << endl;
            exit(1);
        }

        cout << "  Allocated buffer " << e << " with mmap (" << n_bytes / 1024 << "KB) at 0x"
             << hex << buf << dec << endl;

        memset(buf, 0, n_bytes);
        mem_buf_handles[e] = this->attachBuffer(buf, n_bytes);
        mem_buf_sizes[e] = n_bytes;
    }

    // Now that all memory is allocated, unmap the last page of each buffer so we
    // know that there are illegal addresses at the end of each buffer.
    for (int e = 0; e < n_rd_engines; e++)
    {
        void* buf = (void*)mem_buf_handles[e]->c_type();
        size_t n_bytes = mem_buf_sizes[e];

        // Unmap the page just after the buffer
        buf = (void*)((uint8_t*)buf + n_bytes);
        assert(0 == munmap(buf, (n_bytes >= 2048 * 1024) ? 2048 * 1024 : 4096));

        cout << "  Released guard " << e << " with munmap at 0x"
             << hex << buf << dec << endl;
    }

    // Put random values in the low word of each line in the buffers
    for (int e = 0; e < n_rd_engines; e++)
    {
        volatile uint64_t* buf = (volatile uint64_t*)mem_buf_handles[e]->c_type();
        size_t n_bytes = mem_buf_sizes[e];

        // The initial hash value must match the initial value in the hash32 RTL.
        mem_buf_hashes[e] = 0b1010011010110;

        while (n_bytes > 64)
        {
            // Random values, but make sure bit 0 is clear since it indicates
            // whether the stream end is reached.
            *buf = random() & ~uint64_t(1);
            mem_buf_hashes[e] = hash32(mem_buf_hashes[e], *buf);

            buf += 8;
            n_bytes -= 64;
        }

        // Mark end of stream
        *buf = 1;
    }

    return 0;
}


uint32_t
TEST_SPEC_LOAD::hash32(uint32_t cur_hash, uint32_t data)
{
    // This code matches the hash32 RTL. It isn't fast and doesn't have to be
    // since it runs once at buffer initialization.

    // Burst bits into individual buckets
    uint8_t value[32], new_data[32], new_value[32];

    for (int i = 0; i < 32; i++)
    {
        value[i] = cur_hash & 1;
        cur_hash >>= 1;

        new_data[i] = data & 1;
        data >>= 1;
    }

    new_value[31] = new_data[31] ^ value[0];
    new_value[30] = new_data[30] ^ value[31];
    new_value[29] = new_data[29] ^ value[30];
    new_value[28] = new_data[28] ^ value[29];
    new_value[27] = new_data[27] ^ value[28];
    new_value[26] = new_data[26] ^ value[27];
    new_value[25] = new_data[25] ^ value[26];
    new_value[24] = new_data[24] ^ value[25];
    new_value[23] = new_data[23] ^ value[24];
    new_value[22] = new_data[22] ^ value[23];
    new_value[21] = new_data[21] ^ value[22];
    new_value[20] = new_data[20] ^ value[21];
    new_value[19] = new_data[19] ^ value[20];
    new_value[18] = new_data[18] ^ value[19];
    new_value[17] = new_data[17] ^ value[18];
    new_value[16] = new_data[16] ^ value[17];
    new_value[15] = new_data[15] ^ value[16];
    new_value[14] = new_data[14] ^ value[15];
    new_value[13] = new_data[13] ^ value[14];
    new_value[12] = new_data[12] ^ value[13];
    new_value[11] = new_data[11] ^ value[12];
    new_value[10] = new_data[10] ^ value[11];
    new_value[9]  = new_data[9] ^ value[10];
    new_value[8]  = new_data[8] ^ value[9];
    new_value[7]  = new_data[7] ^ value[8];
    new_value[6]  = new_data[6] ^ value[7] ^ value[0];
    new_value[5]  = new_data[5] ^ value[6];
    new_value[4]  = new_data[4] ^ value[5] ^ value[0];
    new_value[3]  = new_data[3] ^ value[4];
    new_value[2]  = new_data[2] ^ value[3] ^ value[0];
    new_value[1]  = new_data[1] ^ value[2] ^ value[0];
    new_value[0]  = new_data[0] ^ value[1] ^ value[0];

    uint32_t new_hash = 0;
    for (int i = 0; i < 32; i++)
    {
        new_hash <<= 1;
        new_hash |= new_value[31-i];
    }

    return new_hash;
}
