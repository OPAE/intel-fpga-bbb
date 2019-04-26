// Copyright(c) 2017, Intel Corporation
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


/**
 * \file mpf_shim_vtp_internal.h
 * \brief Internal functions and data structures for managing VTP.
 */

#ifndef __FPGA_MPF_SHIM_VTP_INTERNAL_H__
#define __FPGA_MPF_SHIM_VTP_INTERNAL_H__

#include "shim_vtp_pt.h"
#include "shim_vtp_srv.h"


/**
 * Initialize VTP.
 *
 * This function should be called automatically as a side effect of
 * establishing a connection to MPF.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpInit(
    _mpf_handle_p _mpf_handle
);


/**
 * Terminate VTP.
 *
 * This function should be called automatically as a side effect of
 * disconnecting MPF.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpTerm(
    _mpf_handle_p _mpf_handle
);


/**
 * Is VTP operating in on-demand pinning mode? In this mode, the FPGA
 * logic sends translation requests to a VTP software service. The
 * software service detects references to unpinned memory and pins it
 * before returning the translation.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @returns                True iff in on-demand pinning mode.
 */
bool mpfVtpPinOnDemandMode(
    _mpf_handle_p _mpf_handle
);


/**
 * Pin and insert a single page in the translation table.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @param[in]  pt_locked   True if the page table manager lock is held already.
 * @param[in]  va          Virtual address of page start.
 * @param[in]  page_size   Size of the page.
 * @param[in]  pt_flags    Flags passed to mpfVtpPtInsertPageMapping().
 * @param[out] pinned_pa   Physical address to which the page was pinned.
 * @param[out] pin_result  The result of calling fpgaPrepareBuffer() to pin
 *                         the page. This return value allows callers to
 *                         differentiate between fpgaPrepareBuffer() errors
 *                         and page table errors.
 * @returns                True iff in on-demand pinning mode.
 */
fpga_result mpfVtpPinAndInsertPage(
    _mpf_handle_p _mpf_handle,
    bool pt_locked,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_page_size page_size,
    uint32_t pt_flags,
    mpf_vtp_pt_paddr* pinned_pa,
    fpga_result* pin_result
);


/**
 * VTP persistent state.  An instance of this struct is stored in the
 * MPF handle.
 */
typedef struct
{
    // VTP page table state
    mpf_vtp_pt* pt;

    // VTP transation server state
    mpf_vtp_srv* srv;

    // Maximum requested page size
    mpf_vtp_page_size max_physical_page_size;

    // Does libfpga support FPGA_PREALLOCATED?  The old AAL compatibility
    // version does not.
    bool use_fpga_buf_preallocated;

    // Is VTP available in the FPGA?
    bool is_available;

    // State of the invalidation register toggle. This value is coordinated
    // with CCI_MPF_VTP_CSR_INVAL_PAGE_VADDR in order to detect completion
    // of translation invalidation requests.
    bool csr_inval_page_toggle;
}
mpf_vtp_state;

#endif // __FPGA_MPF_SHIM_VTP_INTERNAL_H__
