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


/**
 * \file shim_vtp_srv.h
 * \brief Internal functions and data structures for managing VTP translation.
 */

#ifndef __FPGA_MPF_SHIM_VTP_SRV_H__
#define __FPGA_MPF_SHIM_VTP_SRV_H__

#include <pthread.h>
#include <opae/mpf/shim_vtp.h>



/**
 * VTP translation server state.
 */
typedef struct
{
    // Request ring buffer
    uint64_t req_wsid;
    mpf_vtp_pt_vaddr req_va;
    mpf_vtp_pt_paddr req_pa;

    // Handle for server thread
    pthread_t srv_tid;

    // Opaque parent MPF handle.  It is opaque because the internal MPF handle
    // points to the page table, so the dependence would be circular.
    _mpf_handle_p _mpf_handle;
}
mpf_vtp_srv;


/**
 * Initialize a page translation server.
 *
 * Initializes and starts a page translation server if the FPGA
 * requires one.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @param[out] srv         Allocated server handle.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpSrvInit(
    _mpf_handle_p _mpf_handle,
    mpf_vtp_srv** srv
);


/**
 * Destroy a page translation server.
 *
 * Terminate and deallocate a page translation server.
 *
 * @param[in]  srv         Translation server handle.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpSrvTerm(
    mpf_vtp_srv* srv
);


#endif // __FPGA_MPF_SHIM_VTP_SRV_H__
