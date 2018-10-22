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

#include <stdlib.h>
#include <unistd.h>

#include <uuid/uuid.h>
#include <iostream>
#include <algorithm>

#include "opae_svc_wrapper.h"

using namespace std;
using namespace opae::fpga::types;
using namespace opae::fpga::bbb::mpf::types;


OPAE_SVC_WRAPPER::OPAE_SVC_WRAPPER(const char *accel_uuid) :
    accel(NULL),
    mpf(NULL),
    is_ok(false),
    is_simulated(false)
{
    fpga_result r;

    // Don't print verbose messages in ASE by default
    setenv("ASE_LOG", "0", 0);

    // Is the hardware simulated with ASE?
    is_simulated = probeForASE();

    // Connect to an available accelerator with the requested UUID
    r = findAndOpenAccel(accel_uuid);

    is_ok = (FPGA_OK == r);
}


OPAE_SVC_WRAPPER::~OPAE_SVC_WRAPPER()
{
    if (mpf != nullptr)
    {
        mpf->close();
    }
}


shared_buffer::ptr_t
OPAE_SVC_WRAPPER::allocBuffer(size_t nBytes)
{
    fpga_result r;
    void* va;

    //
    // Allocate an I/O buffer shared with the FPGA.  When VTP is present
    // the FPGA-side address translation allows us to allocate multi-page,
    // virtually contiguous buffers.  When VTP is not present the
    // accelerator must manage physical addresses on its own.  In that case,
    // the I/O buffer allocation (fpgaPrepareBuffer) is limited to
    // allocating one page per invocation.
    //

    shared_buffer::ptr_t buf;

    if ((mpf != nullptr) && mpfVtpIsAvailable(*mpf))
    {
        // VTP is available.  Use it to get a virtually contiguous region.
        // The region may be composed of multiple non-contiguous physical
        // pages.
        buf = mpf_shared_buffer::allocate(mpf, nBytes);
    }
    else
    {
        // VTP is not available.  Map a page without a TLB entry.  nBytes
        // must not be larger than a page.
        buf = shared_buffer::allocate(accel, nBytes);
    }

    return buf;
}


fpga_result
OPAE_SVC_WRAPPER::findAndOpenAccel(const char* accel_uuid)
{
    // Look for accelerator with AFU ID
    auto filter = properties::get();
    filter->guid.parse(accel_uuid);
    filter->type = FPGA_ACCELERATOR;

    std::vector<token::ptr_t> tokens;
    try
    {
        tokens = token::enumerate({filter});
    }
    catch (const opae::fpga::types::no_driver& nd)
    {
        std::cerr << "Failed to load FPGA driver. Is an FPGA present on the machine?"
                  << std::endl;
        return FPGA_NOT_FOUND;
    }

    // Assert we have found at least one
    if (tokens.size() < 1)
    {
        std::cerr << "FPGA with accelerator UUID " << accel_uuid << " not found." << std::endl;
        return FPGA_NOT_FOUND;
    }

    // Loop through all the matching accelerators, looking for one that isn't busy.
    for (int f = 0; f < tokens.size(); f += 1)
    {
        token::ptr_t tok = tokens[f];
        try
        {
            // Connect to an FPGA and map MMIO
            accel = handle::open(tok, 0);

            // Connect to MPF
            mpf = mpf_handle::open(accel, 0, 0, 0);

            return FPGA_OK;
        }
        catch (const opae::fpga::types::busy &e)
        {
            // No action when an FPGA is busy. We will try all that are available.
        }
    }

    std::cerr << ((tokens.size() == 1) ? "FPGA is" : "All FPGAs are") << " busy." << std::endl;
    return FPGA_BUSY;
}


//
// Is the FPGA real or simulated with ASE?
//
bool
OPAE_SVC_WRAPPER::probeForASE()
{
    // The BBS ID of the ASE device is 0xa5e.
    auto dev_filter = properties::get();
    dev_filter->type = FPGA_DEVICE;

    try
    {
        auto tokens = token::enumerate({dev_filter});
        if (tokens.size() == 0) return false;

        auto dev_props = properties::get(tokens[0]);
        return (0xa5e == dev_props->bbs_id);
    }
    catch (const opae::fpga::types::no_driver& nd)
    {
        return false;
    }
}
