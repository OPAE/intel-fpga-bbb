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
// Interface to a TLB data cache array, holding a since page size. This
// interface is typically used between the shared L2 pipeline and the
// TLB cache.
//

`include "mpf_vtp.vh"

interface mpf_vtp_tlb_data_if;
    // Look up VA in the table and return the PA or signal a miss two cycles
    // later.  The TLB code operates on aligned pages.  It is up to the caller
    // to compute offsets into pages.
    logic lookupEn;         // Enable the request
    t_tlb_4kb_va_page_idx lookupPageVA;
    logic lookupIsSpeculative;
    logic lookupRdy;        // Ready to accept a request?

    // Did the lookup hit in the TLB cache?
    logic lookupRspHit;
    // Respond with page's physical address two cycles after lookupEn
    t_tlb_4kb_pa_page_idx lookupRspPagePA;
    logic lookupRspIsBigPage;
    // Is the page present in the translation table? Even failed translations
    // are cached so that speculative loads don't keep forcing page walks.
    logic lookupRspNotPresent;

    //
    // Signals for handling misses and fills.
    //
    logic lookupMiss;
    t_tlb_4kb_va_page_idx lookupMissVA;

    logic fillEn;
    t_tlb_4kb_va_page_idx fillVA;
    t_tlb_4kb_pa_page_idx fillPA;
    // 2MB page? If 0 then it is a 4KB page.
    logic fillBigPage;
    // Failed speculative translation?
    logic fillNotPresent;

    modport server
       (
        input  lookupEn,
        input  lookupPageVA,
        input  lookupIsSpeculative,
        output lookupRdy,

        output lookupRspHit,
        output lookupRspPagePA,
        output lookupRspIsBigPage,
        output lookupRspNotPresent,

        output lookupMiss,
        output lookupMissVA,
        input  fillEn,
        input  fillVA,
        input  fillPA,
        input  fillBigPage,
        input  fillNotPresent
        );

    modport client
       (
        output lookupEn,
        output lookupPageVA,
        output lookupIsSpeculative,
        input  lookupRdy,

        // Responses are returned from the TLB in the order translations were
        // requested.  At the end of a lookup exactly one of lookupRspHit
        // and lookupMiss will be set for one cycle.  When looukpRspValid is
        // set the remaining lookupRsp fields also have meaning.
        input  lookupMiss,
        input  lookupRspHit,
        input  lookupRspPagePA,
        input  lookupRspIsBigPage,
        input  lookupRspNotPresent
        );

    // Fill -- add a new translation
    modport fill
       (
        output fillEn,
        output fillVA,
        output fillPA,
        output fillBigPage,
        output fillNotPresent
        );

endinterface // mpf_vtp_tlb_data_if
