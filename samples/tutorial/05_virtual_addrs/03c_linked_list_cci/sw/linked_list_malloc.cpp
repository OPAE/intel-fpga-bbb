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
#include <stdlib.h>
#include <malloc.h>
#include <unistd.h>
#include <assert.h>

#include <iostream>
#include <string>
#include <atomic>

using namespace std;

#include "opae_svc_wrapper.h"
#include "csr_mgr.h"

using namespace opae::fpga::types;
using namespace opae::fpga::bbb::mpf::types;

// State from the AFU's JSON file, extracted using OPAE's afu_json_mgr script
#include "afu_json_info.h"

//
// A simple data structure for our example.  It contains 4 memory lines in
// which the last 3 lines hold values in the low word and the 1st line
// holds a pointer to the next entry in the list.  The pad fields are
// unused.
//
typedef struct t_linked_list
{
    t_linked_list* next;
    uint64_t pad_next[7];

    uint64_t v0;
    uint64_t pad0[7];

    uint64_t v1;
    uint64_t pad1[7];

    uint64_t v2;
    uint64_t pad2[7];
}
t_linked_list;

//
// Construct a linked list of type t_linked_list in a buffer starting at
// head.  Generated the list with n_entries, separating each entry by
// spacing_bytes.
//
// Both head and spacing_bytes must be cache-line aligned.
//
t_linked_list* initList(t_linked_list* head,
                        uint64_t n_entries,
                        uint64_t spacing_bytes)
{
    t_linked_list* p = head;
    uint64_t v = 1;

    for (int i = 0; i < n_entries; i += 1)
    {
        p->v0 = v++;
        p->v1 = v++;
        p->v2 = v++;

        t_linked_list* p_next = (t_linked_list*)(intptr_t(p) + spacing_bytes);
        p->next = (i+1 < n_entries) ? p_next : NULL;

        p = p_next;
    }

    // Force all initialization to memory before the buffer is passed to the FPGA.
    std::atomic_thread_fence(std::memory_order_seq_cst);

    return head;
}


//
// The key difference between CPU and FPGA access to memory is the required alignment.
// malloc_cache_aligned() allocates buffers that are aligned to multiples of cache
// lines. The FPGA requires natural alignment up to the load/store request size.
// Namely, 4 line read requests require buffers aligned to 4 cache lines.
//
// For this example the allocator is kept simple. It could be turned into a class
// that wraps the buffer in a smart pointer so it is deallocated on last use.
//
static const uint32_t BYTES_PER_LINE = 64;
static void* malloc_cache_aligned(size_t size, size_t align_to_num_lines = 1)
{
    void* buf;

    // Aligned to the requested number of cache lines
    if (0 == posix_memalign(&buf, BYTES_PER_LINE * align_to_num_lines, size)) {
      return buf;
    }

    return NULL;
}


int main(int argc, char *argv[])
{
    // Find and connect to the accelerator
    OPAE_SVC_WRAPPER fpga(AFU_ACCEL_UUID);
    assert(fpga.isOk());

    // Connect the CSR manager
    CSR_MGR csrs(fpga);

    // Like the previous linked list example we use only virtual addresses
    // here, passing them to the FPGA directly. This example, however, does
    // not call either OPAE or MPF to allocate the storage. It is allocated
    // using standard buffer management. The VTP run-time logic in MPF will
    // automatically call OPAE to pin pages on first use by the FPGA.
    //
    // There is one key difference. Addresses used by the FPGA must be at
    // least cache-line aligned.
    uint64_t* result_buf =
        reinterpret_cast<uint64_t*>(malloc_cache_aligned(BYTES_PER_LINE));
    assert(NULL != result_buf);

    // Set the low word of the shared buffer to 0.  The FPGA will write
    // a non-zero value to it.
    result_buf[0] = 0;

    // Set the result buffer pointer
    csrs.writeCSR(0, intptr_t(result_buf));

    // Allocate a 16MB buffer, being careful to align it to 4 cache lines.
    // FPGA multi-line reads and writes require addresses aligned to the
    // multi-line access size.
    //
    // The memory here is allocated using a standard allocator. The
    // virtual addresses will be passed to the FPGA.  The VTP module will
    // automatically pin and map pages for access by the FPGA on reference.
    t_linked_list* list_buf =
        reinterpret_cast<t_linked_list*>(malloc_cache_aligned(32 * 0x80000, 4));
    assert(NULL != list_buf);

    // Initialize a linked list in the buffer
    initList(list_buf, 32, 0x80000);

    // Start the FPGA, which is waiting for the list head in CSR 1.
    csrs.writeCSR(1, intptr_t(list_buf));

    // Spin, waiting for the value in memory to change to something non-zero.
    struct timespec pause;
    // Longer when simulating
    pause.tv_sec = (fpga.hwIsSimulated() ? 1 : 0);
    pause.tv_nsec = 2500000;

    while (0 == result_buf[0])
    {
        nanosleep(&pause, NULL);
    };

    // Hash is stored in result_buf[1]
    uint64_t r = result_buf[1];
    cout << "Hash: 0x" << hex << r << dec << "  ["
         << ((0x5726aa1d == r) ? "Correct" : "ERROR")
         << "]" << endl << endl;

    // Reads CSRs to get some statistics
    cout << "# List length: " << csrs.readCSR(0) << endl
         << "# Linked list data entries read: " << csrs.readCSR(1) << endl;

    cout << "#" << endl
         << "# AFU frequency: " << csrs.getAFUMHz() << " MHz"
         << (fpga.hwIsSimulated() ? " [simulated]" : "")
         << endl;

    // MPF VTP (virtual to physical) statistics
    mpf_handle::ptr_t mpf = fpga.mpf;
    if (mpfVtpIsAvailable(*mpf))
    {
        mpf_vtp_stats vtp_stats;
        mpfVtpGetStats(*mpf, &vtp_stats);

        cout << "#" << endl;
        if (vtp_stats.numFailedTranslations)
        {
            cout << "# VTP failed translating VA: 0x" << hex << uint64_t(vtp_stats.ptWalkLastVAddr) << dec << endl;
        }
        cout << "# VTP PT walk cycles: " << vtp_stats.numPTWalkBusyCycles << endl
             << "# VTP L2 4KB hit / miss: " << vtp_stats.numTLBHits4KB << " / "
             << vtp_stats.numTLBMisses4KB << endl
             << "# VTP L2 2MB hit / miss: " << vtp_stats.numTLBHits2MB << " / "
             << vtp_stats.numTLBMisses2MB << endl;
    }

    free(result_buf);
    free(list_buf);

    return 0;
}
