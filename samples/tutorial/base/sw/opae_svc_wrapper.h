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

#ifndef __OPAE_SVC_WRAPPER_H__
#define __OPAE_SVC_WRAPPER_H__ 1

#include <stdint.h>

#include <opae/cxx/core/shared_buffer.h>
#include <opae/cxx/core/handle.h>
#include <opae/cxx/core/properties.h>
#include <opae/cxx/core/token.h>

using namespace opae;

#include <opae/mpf/cxx/mpf_handle.h>
#include <opae/mpf/cxx/mpf_shared_buffer.h>

using namespace opae::fpga::bbb;

typedef class OPAE_SVC_WRAPPER SVC_WRAPPER;

class OPAE_SVC_WRAPPER
{
  public:
    // The constructor and destructor connect to and disconnect from the FPGA.
    OPAE_SVC_WRAPPER(const char* accel_uuid);
    ~OPAE_SVC_WRAPPER();

    // Any errors in constructor?
    bool isOk(void) const { return is_ok; }

    // Is the hardware simulated with ASE?
    bool hwIsSimulated(void) const { return is_simulated; }

    //
    // Wrap MMIO write and read.
    //
    void write_csr64(uint32_t idx, uint64_t v)
    {
        accel->write_csr64(idx, v);
    }

    uint64_t read_csr64(uint32_t idx)
    {
        return accel->read_csr64(idx);
    }

    //
    // Expose a buffer allocate method that hides the details of
    // the various allocation interfaces.  When VTP is present, large
    // multi-page, virtually contiguous buffers may be allocated.
    // When VTP is not present, the standard physical page allocator
    // is used.
    //
    fpga::types::shared_buffer::ptr_t allocBuffer(size_t nBytes);

    fpga::types::handle::ptr_t accel;
    mpf::types::mpf_handle::ptr_t mpf;

  protected:
    bool is_ok;
    bool is_simulated;

  private:
    // Connect to an accelerator
    fpga_result findAndOpenAccel(const char* accel_uuid);

    // Is the HW simulated with ASE or real?
    bool probeForASE();
};

#endif //  __OPAE_SVC_WRAPPER_H__
