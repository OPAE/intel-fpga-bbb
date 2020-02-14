//
// Copyright (c) 2020, Intel Corporation
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
// Interface between the L2 TLB miss path and a page table walker.
//

`include "mpf_vtp.vh"

interface mpf_vtp_pt_walk_if;
    // Enable PT walk request
    logic reqEn;
    // Ready to accept a request?
    logic reqRdy;
    // VA to translate
    t_tlb_4kb_va_page_idx reqVA;

    // Meta-data associated with requests and returned with responses.
    t_mpf_vtp_pt_walk_meta reqMeta;
    logic reqIsSpeculative;
    t_mpf_vtp_req_tag reqTag;

    // Responses. These may be returned out of order. The client will use
    // the metadata and tag to sort them.
    logic rspEn;
    t_tlb_4kb_va_page_idx rspVA;
    t_tlb_4kb_pa_page_idx rspPA;
    t_mpf_vtp_pt_walk_meta rspMeta;
    logic rspIsSpeculative;
    t_mpf_vtp_req_tag rspTag;
    // 2MB page? If 0 then it is a 4KB page.
    logic rspIsBigPage;
    // Can the response be cached in the TLB?
    logic rspIsCacheable;
    // Requested VA is not in the page table.  This is an error!
    logic rspNotPresent;

    // Page table walker (server) ports
    modport server
       (
        output reqRdy,
        input  reqVA,
        input  reqEn,
        input  reqMeta,
        input  reqIsSpeculative,
        input  reqTag,

        output rspEn,
        output rspVA,
        output rspPA,
        output rspMeta,
        output rspIsSpeculative,
        output rspTag,
        output rspIsBigPage,
        output rspIsCacheable,
        output rspNotPresent
        );

    // Client (TLB) interface
    modport client
       (
        input  reqRdy,
        output reqVA,
        output reqEn,
        output reqMeta,
        output reqIsSpeculative,
        output reqTag,

        input  rspEn,
        input  rspVA,
        input  rspPA,
        input  rspMeta,
        input  rspIsSpeculative,
        input  rspTag,
        input  rspIsBigPage,
        input  rspIsCacheable,
        input  rspNotPresent
        );

endinterface // mpf_vtp_pt_walk_if
