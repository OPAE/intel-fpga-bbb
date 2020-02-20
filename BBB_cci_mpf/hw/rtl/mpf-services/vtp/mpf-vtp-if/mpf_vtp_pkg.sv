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
// VTP global data structures and definitions.
//

`include "cci_mpf_platform.vh"
`include "cci_mpf_config.vh"

package mpf_vtp_pkg;

    //
    // Base address type from which VTP address calculations are derived
    //
    localparam VTP_CLADDR_WIDTH = cci_mpf_if_pkg::CCI_MPF_CLADDR_WIDTH;
    typedef logic [VTP_CLADDR_WIDTH-1 : 0] t_vtp_clAddr;



    // ********************************************************************
    // **                                                                **
    // **   All bit widths are for LINE addresses, not byte addresses!   **
    // **                                                                **
    // ********************************************************************

    // Width of a virtual address (line addresses).  This value must match
    // the width of the CCI request header defined in the base CCI structures
    // and the page table data structure.
    localparam VTP_PT_VA_BITS = VTP_CLADDR_WIDTH;

    // Width of a physical address (line addresses).  Old machines supported
    // only 32 bits.  Recent machines support larger spaces.
    localparam VTP_PT_PA_BITS =
`ifndef PLATFORM_SIMULATED
        // A couple of very old integrated platforms have small physical
        // address spaces.
  `ifdef MPF_PLATFORM_PA_BITS
       `MPF_PLATFORM_PA_BITS;
  `else
        VTP_CLADDR_WIDTH;
  `endif
`else
        // Running in simulation. Versions of ASE after Oct. 2018 may generate
        // addresses outside the 32 bit range. This isn't ideal for simulating
        // BDX systems, but for now this is the easiest solution.
        VTP_CLADDR_WIDTH;
`endif

    //
    // Components of an address:
    //

    // Low order (page offset) bits in both VA and PA of a page
    localparam VTP_PT_2MB_PAGE_OFFSET_BITS = 15;   // Line sized data (21-6)
    localparam VTP_PT_4KB_PAGE_OFFSET_BITS = 6;    //                 (12-6)

    // High order (page index) bits in 2MB and 4KB spaces
    localparam VTP_PT_2MB_VA_PAGE_INDEX_BITS = VTP_PT_VA_BITS - VTP_PT_2MB_PAGE_OFFSET_BITS;
    localparam VTP_PT_4KB_VA_PAGE_INDEX_BITS = VTP_PT_VA_BITS - VTP_PT_4KB_PAGE_OFFSET_BITS;
    localparam VTP_PT_2MB_PA_PAGE_INDEX_BITS = VTP_PT_PA_BITS - VTP_PT_2MB_PAGE_OFFSET_BITS;
    localparam VTP_PT_4KB_PA_PAGE_INDEX_BITS = VTP_PT_PA_BITS - VTP_PT_4KB_PAGE_OFFSET_BITS;


    // Address of a virtual page without the page offset bits
    typedef logic [VTP_PT_2MB_VA_PAGE_INDEX_BITS-1 : 0] t_tlb_2mb_va_page_idx;
    typedef logic [VTP_PT_4KB_VA_PAGE_INDEX_BITS-1 : 0] t_tlb_4kb_va_page_idx;

    // Address of a physical page without the page offset bits
    typedef logic [VTP_PT_2MB_PA_PAGE_INDEX_BITS-1 : 0] t_tlb_2mb_pa_page_idx;
    typedef logic [VTP_PT_4KB_PA_PAGE_INDEX_BITS-1 : 0] t_tlb_4kb_pa_page_idx;

    // Offset within a page
    typedef logic [VTP_PT_2MB_PAGE_OFFSET_BITS-1 : 0] t_tlb_2mb_page_offset;
    typedef logic [VTP_PT_4KB_PAGE_OFFSET_BITS-1 : 0] t_tlb_4kb_page_offset;


    //
    // Convert a full address to page index and offset.
    //
    function automatic t_tlb_2mb_va_page_idx vtp2mbPageIdxFromVA(t_vtp_clAddr va);
        return va[VTP_PT_2MB_PAGE_OFFSET_BITS +: VTP_PT_2MB_VA_PAGE_INDEX_BITS];
    endfunction

    function automatic t_tlb_4kb_va_page_idx vtp4kbPageIdxFromVA(t_vtp_clAddr va);
        return va[VTP_PT_4KB_PAGE_OFFSET_BITS +: VTP_PT_4KB_VA_PAGE_INDEX_BITS];
    endfunction

    function automatic t_tlb_2mb_page_offset vtp2mbPageOffsetFromVA(t_vtp_clAddr va);
        return va[VTP_PT_2MB_PAGE_OFFSET_BITS-1 : 0];
    endfunction

    function automatic t_tlb_4kb_page_offset vtp4kbPageOffsetFromVA(t_vtp_clAddr va);
        return va[VTP_PT_4KB_PAGE_OFFSET_BITS-1 : 0];
    endfunction


    function automatic t_tlb_4kb_pa_page_idx vtp4kbPageIdxFromPA(t_vtp_clAddr pa);
        return pa[VTP_PT_4KB_PAGE_OFFSET_BITS +: VTP_PT_4KB_PA_PAGE_INDEX_BITS];
    endfunction

    function automatic t_tlb_4kb_page_offset vtp4kbPageOffsetFromPA(t_vtp_clAddr pa);
        return pa[VTP_PT_4KB_PAGE_OFFSET_BITS-1 : 0];
    endfunction


    //
    // Conversion functions between 4KB and 2MB page indices
    //
    function automatic t_tlb_2mb_va_page_idx vtp4kbTo2mbVA(t_tlb_4kb_va_page_idx p);
        return p[9 +: VTP_PT_2MB_VA_PAGE_INDEX_BITS];
    endfunction

    function automatic t_tlb_4kb_va_page_idx vtp2mbTo4kbVA(t_tlb_2mb_va_page_idx p);
        return {p, 9'b0};
    endfunction

    function automatic t_tlb_4kb_va_page_idx vtp2mbTo4kbVAx(t_tlb_2mb_va_page_idx p);
        return {p, 9'bx};
    endfunction

    function automatic t_tlb_2mb_pa_page_idx vtp4kbTo2mbPA(t_tlb_4kb_pa_page_idx p);
        return p[9 +: VTP_PT_2MB_PA_PAGE_INDEX_BITS];
    endfunction

    function automatic t_tlb_4kb_pa_page_idx vtp2mbTo4kbPA(t_tlb_2mb_pa_page_idx p);
        return {p, 9'b0};
    endfunction

    function automatic t_tlb_4kb_pa_page_idx vtp2mbTo4kbPAx(t_tlb_2mb_pa_page_idx p);
        return {p, 9'bx};
    endfunction


    // ====================================================================
    //
    // Translation data passed between an AFU's pipeline and the VTP
    // port wrapper modules. AFUs should first set the entire data
    // structure to 0 so that fields can be added in the future without
    // breaking existing AFUs.
    //
    // ====================================================================

    typedef struct packed
    {
        // Virtual address to translate
        t_vtp_clAddr addr;

        // Is the address virtual? When false, the original addr is returned
        // as the response. The ability to send untranslated requests through
        // the pipeline may simplify AFU logic, allowing it to keep requests
        // ordered.
        logic addrIsVirtual;

        // Is the request speculative? No hard errors are generated on
        // speculative translations. Failed translations raise the response
        // error bit.
        logic isSpeculative;

        // Is the request ordered (e.g. a write fence)? If so, the channel
        // logic will wait for all earlier requests to drain from the VTP
        // pipelines. It is illegal to set both reqAddrIsVirtual and
        // isOrdered.
        logic isOrdered;
    }
    t_mpf_vtp_port_wrapper_req;

    typedef struct packed
    {
        // Translated physical address (or original address if request's
        // addrIsVirtual was false).
        t_vtp_clAddr addr;

        // Translation error?
        logic error;
    }
    t_mpf_vtp_port_wrapper_rsp;


    // ====================================================================
    //
    // Interface from a VTP shim to the VTP translation service.  A single
    // service instance is shared by all VTP shims, even when multiple VTP
    // pipeline shims are allocated.
    //
    // ====================================================================

    // Multiple translation requests may be outstanding and they may be
    // returned out of order.  A tag matches responses to requests.
    // MPF_VTP_MAX_SVC_REQS sets the maximum number of requests that may
    // be in flight in a single VTP port.
    localparam MPF_VTP_MAX_SVC_REQS = 32;
    typedef logic [$clog2(MPF_VTP_MAX_SVC_REQS)-1 : 0] t_mpf_vtp_req_tag;

    typedef struct packed
    {
        // Virtual page to translate
        t_tlb_4kb_va_page_idx pageVA;

        // Is the request speculative? No hard errors on speculative translations.
        logic isSpeculative;

        // Dynamically unique tag for lookup request for associating out of order
        // responses with requests.
        t_mpf_vtp_req_tag tag;
    }
    t_mpf_vtp_lookup_req;

    typedef struct packed
    {
        // Translated physical address
        t_tlb_4kb_pa_page_idx pagePA;

        // Translation error?
        logic error;

        // Tag from lookup request
        t_mpf_vtp_req_tag tag;

        // Is translation a big page or just a 4KB page?
        logic isBigPage;

        // Is the translation cacheable?
        logic mayCache;
    }
    t_mpf_vtp_lookup_rsp;


    // ====================================================================
    //
    // Interface for TLB lookup.
    //
    //   The interface is always described in terms of 4KB pages,
    //   independent of whether the TLB is managing 4KB or 2MB pages.
    //   This normalizes the message passing among the VTP pipeline, a
    //   TLB and the page table walker.
    //
    // ====================================================================

    // For use only inside the TLB server. Clients should use
    // MPF_VTP_TLB_MIN_PIPE_STAGES.
    localparam MPF_VTP_TLB_NUM_INTERNAL_PIPE_STAGES = 5;
    // The minimum depth of the server's pipeline from the client's
    // perspective. The two extra cycles allow for registering both
    // incoming requests and outgoing responses.
    localparam MPF_VTP_TLB_MIN_PIPE_STAGES = MPF_VTP_TLB_NUM_INTERNAL_PIPE_STAGES + 2;


    // ====================================================================
    //
    //  Interface between the VTP service and the hardware page table
    //  walker.
    //
    // ====================================================================

    // Page walk requests may have associated metadata used by the client
    // to reorder responses.
    typedef logic [7 : 0] t_mpf_vtp_pt_walk_meta;


    // ====================================================================
    //
    //  Interface between the page table walker and the FIM.
    //
    // ====================================================================

    //
    // The interface supports multiple implementations of page table walkers.
    // A hardware page table walker needs reads. When page table management
    // is on the CPU then writes may be used to send messages to a
    // service running on the CPU.
    //

    typedef logic [63:0] t_mpf_vtp_pt_fim_wr_data;


    // ====================================================================
    //
    // CSR public parameters (used to configured mpf_services_gen_csr_if
    // for VTP).
    //
    // ====================================================================

    localparam MPF_VTP_CSR_N_ENTRIES = 16;
    localparam MPF_VTP_CSR_N_DATA_BITS = 64;

    //
    // CSR private types, used only in the VTP service.
    //
    // CCI_MPF_VTP_CSR_MODE -- see cci_mpf_csrs.h
    typedef struct packed {
        logic inval_translation_cache;
        logic enabled;
    } t_mpf_vtp_csr_in_mode;

    typedef struct packed {
        logic sw_translation_service;
        logic no_hw_page_walker;
        logic [1:0] reserved;
    } t_mpf_vtp_csr_out_mode;

    // VTP control (host to FPGA)
    typedef struct packed {
        t_mpf_vtp_csr_in_mode in_mode;

        // Page table base address (line address)
        t_vtp_clAddr page_table_base;
        logic        page_table_base_valid;
        // Invalidate the translation for one page
        t_vtp_clAddr inval_page;
        logic        inval_page_valid;

        // Physical address of the software page translation service
        // request ring buffer.
        t_vtp_clAddr page_translation_buf_paddr;
        logic page_translation_buf_paddr_valid;
        // Page translation response from the software service. When
        // page translation is handled by software, the address here is
        // the physical address corresponding to a translation request
        // for a virtual address.
        t_vtp_clAddr page_translation_rsp;
        logic page_translation_rsp_valid;
    } t_mpf_vtp_ctrl;

    // VTP TLB cache events
    typedef struct packed {
        logic hit_4kb;
        logic miss_4kb;
        logic hit_2mb;
        logic miss_2mb;
    } t_mpf_vtp_tlb_events;

    // VTP page table walker events
    typedef struct packed {
        logic busy;
        logic failed_translation;
        t_vtp_clAddr last_vaddr;
    } t_mpf_vtp_pt_walk_events;

endpackage // mpf_vtp_pkg
