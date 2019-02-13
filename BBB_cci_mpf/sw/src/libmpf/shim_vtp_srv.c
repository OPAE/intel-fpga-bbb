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

#include <xmmintrin.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <inttypes.h>
#include <pthread.h>

#include <opae/mpf/mpf.h>
#include "mpf_internal.h"


static void *mpfVtpSrvMain(void *args)
{
    mpf_vtp_srv* srv = (mpf_vtp_srv*)args;
    _mpf_handle_p _mpf_handle = srv->_mpf_handle;
    mpf_vtp_pt* pt = _mpf_handle->vtp.pt;

    fpga_result r;

	pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, NULL);

    // Pointer to the next translation request
    volatile uint64_t* next_req = (volatile uint64_t*)srv->req_va;

    // End of the 4KB ring buffer
    volatile uint64_t* buf_end = next_req;
    buf_end = (volatile uint64_t*)((uint64_t)buf_end + 4096);

    // Server loop
    while (true)
    {
        // Wait for next request
        while (0 == *next_req)
        {
            _mm_pause();
        }

        mpf_vtp_pt_vaddr req_va = (mpf_vtp_pt_vaddr)(*next_req ^ 1);
        if (srv->_mpf_handle->dbg_mode)
        {
            MPF_FPGA_MSG("VTP translation request from VA %p", req_va);
        }

        mpf_vtp_pt_paddr rsp_pa;
        mpf_vtp_page_size page_size;
        uint32_t flags;
        r = mpfVtpPtTranslateVAtoPA(pt, req_va, &rsp_pa, &page_size, &flags);
        if (FPGA_OK == r)
        {
            // Response is the PA line address
            uint64_t rsp = rsp_pa >> 6;

            // Set bit 1 for 2MB pages
            if (page_size == MPF_VTP_PAGE_2MB)
            {
                rsp |= 2;
            }

            r = mpfWriteCsr(_mpf_handle, CCI_MPF_SHIM_VTP,
                            CCI_MPF_VTP_CSR_PAGE_TRANSLATION_RSP,
                            rsp);

            if (srv->_mpf_handle->dbg_mode)
            {
                MPF_FPGA_MSG("VTP translation response VA %p -> PA 0x%" PRIx64 " (line 0x%" PRIx64 "), %s",
                             req_va, rsp_pa, rsp_pa >> 6,
                             (page_size == MPF_VTP_PAGE_2MB ? "2MB" : "4KB"));
            }
        }

        // Done with request. Move on to the next one. Only one request is sent
        // per line.
        *next_req = 0;
        next_req += 8;
        if (next_req == buf_end)
        {
            next_req = (volatile uint64_t*)srv->req_va;
        }
    }

    return NULL;
}


fpga_result mpfVtpSrvInit(
    _mpf_handle_p _mpf_handle,
    mpf_vtp_srv** srv
)
{
    fpga_result r;
    mpf_vtp_srv* new_srv;

    *srv = NULL;

    // Is a software translation server expected by the hardware? This
    // is indicated in bit 3 of the VTP mode CSR.
    uint64_t vtp_mode = mpfReadCsr(_mpf_handle, CCI_MPF_SHIM_VTP,
                                   CCI_MPF_VTP_CSR_MODE, NULL);
    bool sw_translation = (vtp_mode & 8);

    if (_mpf_handle->dbg_mode)
    {
        MPF_FPGA_MSG("VTP translation server %s active", (sw_translation ? "is" : "is not"));
    }

    new_srv = malloc(sizeof(mpf_vtp_srv));
    *srv = new_srv;
    if (NULL == new_srv) return FPGA_NO_MEMORY;
    memset(new_srv, 0, sizeof(mpf_vtp_srv));

    new_srv->_mpf_handle = _mpf_handle;

    if (sw_translation)
    {
        r = fpgaPrepareBuffer(_mpf_handle->handle, 4096,
                              &new_srv->req_va, &new_srv->req_wsid, 0);
        if (r != FPGA_OK) return r;

        // Get the FPGA-side physical address
        r = fpgaGetIOAddress(_mpf_handle->handle, new_srv->req_wsid, &new_srv->req_pa);

        r = mpfWriteCsr(_mpf_handle, CCI_MPF_SHIM_VTP,
                        CCI_MPF_VTP_CSR_PAGE_TRANSLATION_BUF_PADDR,
                        new_srv->req_pa >> 6);
        if (FPGA_OK != r) goto fail;

        if (_mpf_handle->dbg_mode)
        {
            MPF_FPGA_MSG("Set VTP translation server ring buffer to PA 0x%" PRIx64 " (line 0x%" PRIx64 ")",
                         new_srv->req_pa, new_srv->req_pa >> 6);
        }

        int st = pthread_create(&new_srv->srv_tid, NULL, &mpfVtpSrvMain, (void*)new_srv);
        if (st != 0)
        {
            if (_mpf_handle->dbg_mode)
            {
                MPF_FPGA_MSG("ERROR: Failed to start VTP server thread! (errno=%d)", errno);
                MPF_FPGA_MSG("  %s", strerror(errno));
            }

            r = FPGA_EXCEPTION;
            goto fail;
        }
    }

    return FPGA_OK;

  fail:
    fpgaReleaseBuffer(_mpf_handle->handle, new_srv->req_wsid);
    return r;
}


fpga_result mpfVtpSrvTerm(
    mpf_vtp_srv* srv
)
{
    // Kill the server thread
    if (srv->srv_tid)
    {
        if (srv->_mpf_handle->dbg_mode) MPF_FPGA_MSG("VTP SRV terminating...");

        pthread_cancel(srv->srv_tid);
        pthread_join(srv->srv_tid, NULL);
        srv->srv_tid = 0;
    }

    // Release the request ring buffer
    assert(FPGA_OK == fpgaReleaseBuffer(srv->_mpf_handle->handle, srv->req_wsid));

    // Release the top-level server descriptor
    free(srv);

    return FPGA_OK;
}
