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


int main(int argc, char *argv[])
{
    // Find and connect to the accelerator
    OPAE_SVC_WRAPPER fpga(AFU_ACCEL_UUID);
    assert(fpga.isOk());

    // Connect the CSR manager
    CSR_MGR csrs(fpga);

    // Allocate a memory buffer for storing the result.  Unlike the hello
    // world examples, here we do not need the physical address of the
    // buffer.  The accelerator instantiates MPF's VTP and will use
    // virtual addresses.
    auto result_buf_handle = fpga.allocBuffer(getpagesize());
    auto result_buf = reinterpret_cast<volatile uint64_t*>(result_buf_handle->c_type());
    assert(NULL != result_buf);

    // Set the low word of the shared buffer to 0.  The FPGA will write
    // a non-zero value to it.
    result_buf[0] = 0;

    // Set the result buffer pointer
    csrs.writeCSR(0, intptr_t(result_buf));

    // Allocate a 16MB buffer and share it with the FPGA.  Because the FPGA
    // is using VTP we can allocate a virtually contiguous region.
    // OPAE_SVC_WRAPPER detects the presence of VTP and uses it for memory
    // allocation instead of calling OPAE directly.  The buffer will
    // be composed of physically discontiguous pages.  VTP will construct
    // a private TLB to map virtual addresses from this process to FPGA-side
    // physical addresses.
    auto list_buf_handle = fpga.allocBuffer(16 * 1024 * 1024);
    auto list_buf = reinterpret_cast<volatile t_linked_list*>(list_buf_handle->c_type());
    assert(NULL != list_buf);

    // Initialize a linked list in the buffer
    initList(const_cast<t_linked_list*>(list_buf), 32, 0x80000);

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

    // All shared buffers are automatically released and the FPGA connection
    // is closed when their destructors are invoked here.
    return 0;
}
