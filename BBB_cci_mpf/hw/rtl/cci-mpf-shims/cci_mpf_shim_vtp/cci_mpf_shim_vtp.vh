//
// Copyright (c) 2016, Intel Corporation
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

`ifndef __CCI_MPF_SHIM_VTP_VH__
`define __CCI_MPF_SHIM_VTP_VH__

`include "cci_mpf_platform.vh"
`include "cci_mpf_config.vh"


// ************************************************************************
// **                                                                    **
// **    All bit widths are for LINE addresses, not byte addresses!      **
// **                                                                    **
// ************************************************************************

// Width of a virtual address (line addresses).  This value must match
// the width of the CCI request header defined in the base CCI structures
// and the page table data structure.
localparam CCI_PT_VA_BITS = CCI_MPF_CLADDR_WIDTH;

// Width of a physical address (line addresses).  Old machines supported
// only 32 bits.  Recent machines support larger spaces.
localparam CCI_PT_PA_BITS =
`ifndef PLATFORM_SIMULATED
    // Running on hardware
    ((MPF_PLATFORM == "INTG_OME" || MPF_PLATFORM == "INTG_BDX") ?
        32 /* Old, small memory machine */ :
        CCI_MPF_CLADDR_WIDTH);
`else
    // Running in simulation. Versions of ASE after Oct. 2018 may generate
    // addresses outside the 32 bit range. This isn't ideal for simulating
    // BDX systems, but for now this is the easiest solution.
    CCI_MPF_CLADDR_WIDTH;
`endif


//
// Components of an address:
//

// Low order (page offset) bits in both VA and PA of a page
localparam CCI_PT_2MB_PAGE_OFFSET_BITS = 15;   // Line sized data (21-6)
localparam CCI_PT_4KB_PAGE_OFFSET_BITS = 6;    //                 (12-6)

// High order (page index) bits in 2MB and 4KB spaces
localparam CCI_PT_2MB_VA_PAGE_INDEX_BITS = CCI_PT_VA_BITS - CCI_PT_2MB_PAGE_OFFSET_BITS;
localparam CCI_PT_4KB_VA_PAGE_INDEX_BITS = CCI_PT_VA_BITS - CCI_PT_4KB_PAGE_OFFSET_BITS;
localparam CCI_PT_2MB_PA_PAGE_INDEX_BITS = CCI_PT_PA_BITS - CCI_PT_2MB_PAGE_OFFSET_BITS;
localparam CCI_PT_4KB_PA_PAGE_INDEX_BITS = CCI_PT_PA_BITS - CCI_PT_4KB_PAGE_OFFSET_BITS;


// Address of a virtual page without the page offset bits
typedef logic [CCI_PT_2MB_VA_PAGE_INDEX_BITS-1 : 0] t_tlb_2mb_va_page_idx;
typedef logic [CCI_PT_4KB_VA_PAGE_INDEX_BITS-1 : 0] t_tlb_4kb_va_page_idx;

// Address of a physical page without the page offset bits
typedef logic [CCI_PT_2MB_PA_PAGE_INDEX_BITS-1 : 0] t_tlb_2mb_pa_page_idx;
typedef logic [CCI_PT_4KB_PA_PAGE_INDEX_BITS-1 : 0] t_tlb_4kb_pa_page_idx;

// Offset within a page
typedef logic [CCI_PT_2MB_PAGE_OFFSET_BITS-1 : 0] t_tlb_2mb_page_offset;
typedef logic [CCI_PT_4KB_PAGE_OFFSET_BITS-1 : 0] t_tlb_4kb_page_offset;


//
// Convert a full address to page index and offset.
//
function automatic t_tlb_2mb_va_page_idx vtp2mbPageIdxFromVA(t_cci_clAddr va);
    return va[CCI_PT_2MB_PAGE_OFFSET_BITS +: CCI_PT_2MB_VA_PAGE_INDEX_BITS];
endfunction

function automatic t_tlb_4kb_va_page_idx vtp4kbPageIdxFromVA(t_cci_clAddr va);
    return va[CCI_PT_4KB_PAGE_OFFSET_BITS +: CCI_PT_4KB_VA_PAGE_INDEX_BITS];
endfunction

function automatic t_tlb_2mb_page_offset vtp2mbPageOffsetFromVA(t_cci_clAddr va);
    return va[CCI_PT_2MB_PAGE_OFFSET_BITS-1 : 0];
endfunction

function automatic t_tlb_4kb_page_offset vtp4kbPageOffsetFromVA(t_cci_clAddr va);
    return va[CCI_PT_4KB_PAGE_OFFSET_BITS-1 : 0];
endfunction


function automatic t_tlb_4kb_pa_page_idx vtp4kbPageIdxFromPA(t_cci_clAddr pa);
    return pa[CCI_PT_4KB_PAGE_OFFSET_BITS +: CCI_PT_4KB_PA_PAGE_INDEX_BITS];
endfunction

function automatic t_tlb_4kb_page_offset vtp4kbPageOffsetFromPA(t_cci_clAddr pa);
    return pa[CCI_PT_4KB_PAGE_OFFSET_BITS-1 : 0];
endfunction


//
// Conversion functions between 4KB and 2MB page indices
//
function automatic t_tlb_2mb_va_page_idx vtp4kbTo2mbVA(t_tlb_4kb_va_page_idx p);
    return p[9 +: CCI_PT_2MB_VA_PAGE_INDEX_BITS];
endfunction

function automatic t_tlb_4kb_va_page_idx vtp2mbTo4kbVA(t_tlb_2mb_va_page_idx p);
    return {p, 9'b0};
endfunction

function automatic t_tlb_4kb_va_page_idx vtp2mbTo4kbVAx(t_tlb_2mb_va_page_idx p);
    return {p, 9'bx};
endfunction

function automatic t_tlb_2mb_pa_page_idx vtp4kbTo2mbPA(t_tlb_4kb_pa_page_idx p);
    return p[9 +: CCI_PT_2MB_PA_PAGE_INDEX_BITS];
endfunction

function automatic t_tlb_4kb_pa_page_idx vtp2mbTo4kbPA(t_tlb_2mb_pa_page_idx p);
    return {p, 9'b0};
endfunction

function automatic t_tlb_4kb_pa_page_idx vtp2mbTo4kbPAx(t_tlb_2mb_pa_page_idx p);
    return {p, 9'bx};
endfunction


// ========================================================================
//
// Interface from a VTP shim to the VTP translation service.  A single
// service instance is shared by all VTP shims, even when multiple VTP
// pipeline shims are allocated.
//
// ========================================================================

// Multiple translation requests may be outstanding and they may be
// returned out of order.  A tag matches responses to requests.
localparam CCI_MPF_SHIM_VTP_MAX_SVC_REQS = 32;
typedef logic [$clog2(CCI_MPF_SHIM_VTP_MAX_SVC_REQS)-1 : 0]
    t_cci_mpf_shim_vtp_req_tag;

typedef struct packed
{
    // Virtual page to translate
    t_tlb_4kb_va_page_idx pageVA;

    // Is the request speculative? No hard errors on speculative translations.
    logic isSpeculative;

    // Dynamically unique tag for lookup request for associating out of order
    // responses with requests.
    t_cci_mpf_shim_vtp_req_tag tag;
}
t_cci_mpf_shim_vtp_lookup_req;

typedef struct packed
{
    // Translated physical address
    t_tlb_4kb_pa_page_idx pagePA;

    // Translation error?
    logic error;

    // Tag from lookup request
    t_cci_mpf_shim_vtp_req_tag tag;

    // Is translation a big page or just a 4KB page?
    logic isBigPage;

    // Is the translation cacheable?
    logic mayCache;
}
t_cci_mpf_shim_vtp_lookup_rsp;


interface cci_mpf_shim_vtp_svc_if;
    // Request translation of 4KB aligned address
    logic lookupEn;         // Enable the request
    t_cci_mpf_shim_vtp_lookup_req lookupReq;
    logic lookupRdy;        // Ready to accept a request?

    // Response with translated address.  The response is latency-
    // insensitive, signaled with lookupRspValid.
    logic lookupRspValid;
    t_cci_mpf_shim_vtp_lookup_rsp lookupRsp;

    modport server
       (
        input  lookupEn,
        input  lookupReq,
        output lookupRdy,

        output lookupRspValid,
        output lookupRsp
        );

    modport client
       (
        output lookupEn,
        output lookupReq,
        input  lookupRdy,

        input  lookupRspValid,
        input  lookupRsp
        );

endinterface // cci_mpf_shim_vtp_svc_if


// ========================================================================
//
// Interface for TLB lookup.
//
//   The interface is always described in terms of 4KB pages, independent
//   of whether the TLB is managing 4KB or 2MB pages.  This normalizes the
//   message passing among the VTP pipeline, a TLB and the page table
//   walker.
//
// ========================================================================

// For use only inside the TLB server. Clients should use
// CCI_MPF_SHIM_VTP_TLB_MIN_PIPE_STAGES.
localparam CCI_MPF_SHIM_VTP_TLB_NUM_INTERNAL_PIPE_STAGES = 5;
// The minimum depth of the server's pipeline from the client's
// perspective. The two extra cycles allow for registering both
// incoming requests and outgoing responses.
localparam CCI_MPF_SHIM_VTP_TLB_MIN_PIPE_STAGES = CCI_MPF_SHIM_VTP_TLB_NUM_INTERNAL_PIPE_STAGES + 2;

interface cci_mpf_shim_vtp_tlb_if;
    // These parameters determine the length of the server pipeline and may
    // be used to size FIFOs in clients.

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

endinterface


// ========================================================================
//
//  Interface between the VTP service and the hardware page table walker.
//
// ========================================================================

// Page walk requests may have associated metadata used by the client
// to reorder responses.
typedef logic [7 : 0] t_cci_mpf_shim_vtp_pt_walk_meta;

interface cci_mpf_shim_vtp_pt_walk_if;
    // Enable PT walk request
    logic reqEn;
    // Ready to accept a request?
    logic reqRdy;
    // VA to translate
    t_tlb_4kb_va_page_idx reqVA;

    // Meta-data associated with requests and returned with responses.
    t_cci_mpf_shim_vtp_pt_walk_meta reqMeta;
    logic reqIsSpeculative;
    t_cci_mpf_shim_vtp_req_tag reqTag;

    // Responses. These may be returned out of order. The client will use
    // the metadata and tag to sort them.
    logic rspEn;
    t_tlb_4kb_va_page_idx rspVA;
    t_tlb_4kb_pa_page_idx rspPA;
    t_cci_mpf_shim_vtp_pt_walk_meta rspMeta;
    logic rspIsSpeculative;
    t_cci_mpf_shim_vtp_req_tag rspTag;
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

endinterface



// ========================================================================
//
//  Interface between the page table walker and the FIM.
//
// ========================================================================

//
// The interface supports multiple implementations of page table walkers.
// A hardware page table walker needs reads. When page table management
// is on the CPU then writes may be used to send messages to a
// service running on the CPU.
//

typedef logic [63:0] t_cci_mpf_shim_vtp_pt_fim_wr_data;

interface cci_mpf_shim_vtp_pt_fim_if;

    //
    // Read the page table from host memory
    //
    logic readEn;
    t_cci_clAddr readAddr;
    logic readRdy;

    logic readDataEn;
    t_cci_clData readData;

    //
    // Write messages to a page table service. Only the low 64 bits are
    // written in the line at writeAddr. The value written to higher
    // bits is undefined.
    //
    logic writeEn;
    t_cci_clAddr writeAddr;
    logic writeRdy;
    t_cci_mpf_shim_vtp_pt_fim_wr_data writeData;


    // Page table walker (server) ports
    modport pt_walk
       (
        output readEn,
        output readAddr,
        input  readRdy,

        input  readDataEn,
        input  readData,

        output writeEn,
        output writeAddr,
        input  writeRdy,
        output writeData
        );

    // Memory read port, used by the walker to read PT entries in host memory
    modport to_fim
       (
        input  readEn,
        input  readAddr,
        output readRdy,

        output readDataEn,
        output readData,

        input  writeEn,
        input  writeAddr,
        output writeRdy,
        input  writeData
        );

endinterface

`endif // __CCI_MPF_SHIM_VTP_VH__
