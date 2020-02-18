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
// Handle VTP level 1 private cache misses by forwarding them to the shared
// L2 TLB.
//

`include "mpf_vtp.vh"

module mpf_svc_vtp_l1_miss
  #(
    parameter N_LOCAL_4KB_CACHE_ENTRIES = 512,
    parameter N_LOCAL_2MB_CACHE_ENTRIES = 512,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Flow control
    output logic notFull,
    output logic notEmpty,

    // Incoming requests on the channel. Only requests needing virtual to
    // physical translation will be passed in.
    input  logic reqEn,
    input  t_mpf_vtp_lookup_req req,

    // Outbound channel containing translated requests.
    output logic rspValid,
    output t_mpf_vtp_lookup_rsp rsp,
    // Block responses when rspWaitRequest is asserted
    input  logic rspWaitRequest,

    // Send commands to the L1 cache to add a translation.
    output t_tlb_4kb_va_page_idx insertVA,
    output t_tlb_4kb_pa_page_idx insertPA,
    output logic en_insert_4kb,
    output logic en_insert_2mb,

    // Translation service connection
    mpf_vtp_l2_if.client vtp_svc,

    // CSRs
    mpf_vtp_csrs_if.vtp csrs
    );

    always_ff @(posedge clk)
    begin
        notFull <= vtp_svc.lookupRdy && csrs.vtp_ctrl.in_mode.enabled;
    end

    // ====================================================================
    //
    //  Heap for holding request state
    //
    // ====================================================================

    // Heap data is written in cycle 1. It is available in cycle 0 but
    // not needed yet, so waiting a cycle simplifies timing.
    logic reqEn_q;
    t_mpf_vtp_lookup_req req_q;

    always_ff @(posedge clk)
    begin
        reqEn_q <= reqEn;
        req_q <= req;
    end

    t_mpf_vtp_req_tag heap_read_idx;
    t_tlb_4kb_va_page_idx heap_read_pageVA;

    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_tlb_4kb_va_page_idx))
        )
      heap_ctx
       (
        .clk,
        .reset,

        .raddr(heap_read_idx),
        .rdata(heap_read_pageVA),

        .waddr(req_q.tag),
        .wen(reqEn_q),
        .wdata(req_q.pageVA)
        );


    // ====================================================================
    //
    //  Track cache invalidations (from the host)
    //
    // ====================================================================

    // In order to avoid caching stale data we set a poison bit on
    // L2 lookups that are in flight when an invalidation request arrives.
    // Poisoned L2 responses are not stored in the L1 cache.
    logic [MPF_VTP_MAX_SVC_REQS-1 : 0] heap_entry_not_poisoned;

    always_ff @(posedge clk)
    begin
        if (reqEn_q)
        begin
            heap_entry_not_poisoned[req_q.tag] <= 1'b1;
        end

        if (reset || csrs.vtp_ctrl.inval_page_valid)
        begin
            heap_entry_not_poisoned <= MPF_VTP_MAX_SVC_REQS'(0);
        end
    end


    // ====================================================================
    //
    //  Send translation requests to VTP server
    //
    // ====================================================================

    // Request TLB lookup
    always_ff @(posedge clk)
    begin
        vtp_svc.lookupEn <= reqEn_q;
        vtp_svc.lookupReq <= req_q;

        if (reset)
        begin
            vtp_svc.lookupEn <= 1'b0;
        end
    end

    //
    // TLB response timing is latency insensitive.  This FIFO collects
    // responses until they can be merged into the pipeline.
    //
    t_mpf_vtp_lookup_rsp tlb_lookup_rsp, tlb_lookup_rsp_q;
    logic tlb_lookup_rsp_rdy;
    logic tlb_lookup_deq;
    logic tlb_lookup_deq_q;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_mpf_vtp_lookup_rsp)),
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        .REGISTER_OUTPUT(1)
        )
      tlb_fifo_out
       (
        .clk,
        .reset,

        .enq_data(vtp_svc.lookupRsp),
        .enq_en(vtp_svc.lookupRspValid),
        .notFull(),
        .almostFull(),

        .first(tlb_lookup_rsp),
        .deq_en(tlb_lookup_deq),
        .notEmpty(tlb_lookup_rsp_rdy)
        );

    assign tlb_lookup_deq = tlb_lookup_rsp_rdy && ! rspWaitRequest;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            tlb_lookup_deq_q <= 1'b0;
        end
        else
        begin
            tlb_lookup_deq_q <= tlb_lookup_deq;
        end

        tlb_lookup_rsp_q <= tlb_lookup_rsp;
    end


    // ====================================================================
    //
    //  Responses.
    //
    // ====================================================================

    // Responses are "poisoned" if there was a TLB entry invalidation
    // during the lookup.
    logic not_poisoned;

    // Read the full request from the heap
    always_ff @(posedge clk)
    begin
        heap_read_idx <= tlb_lookup_rsp.tag;
        not_poisoned <= heap_entry_not_poisoned[tlb_lookup_rsp.tag];
    end

    always_ff @(posedge clk)
    begin
        rspValid <= tlb_lookup_deq_q;
        rsp <= tlb_lookup_rsp_q;

        if (reset)
        begin
            rspValid <= 1'b0;
        end
    end

    //
    // Set values for updating the local L1 cache.
    //
    logic en_insert;
    assign en_insert = tlb_lookup_deq_q && not_poisoned &&
                       tlb_lookup_rsp_q.mayCache &&
                       ! tlb_lookup_rsp_q.error;

    always_ff @(posedge clk)
    begin
        en_insert_4kb <= en_insert && ! tlb_lookup_rsp_q.isBigPage;
        en_insert_2mb <= en_insert && tlb_lookup_rsp_q.isBigPage;

        insertVA <= heap_read_pageVA;
        insertPA <= tlb_lookup_rsp_q.pagePA;
    end


    // ====================================================================
    //
    //  Track notEmpty by counting transactions
    //
    // ====================================================================

    logic [$clog2(MPF_VTP_MAX_SVC_REQS+1)-1 : 0] n_active;
    logic [$clog2(MPF_VTP_MAX_SVC_REQS+1)-1 : 0] n_active_next;

    always_comb
    begin
        if ((reqEn ^ rspValid) == 1'b0)
        begin
            // No change
            n_active_next = n_active;
        end
        else if (reqEn)
        begin
            // Only a new entry
            n_active_next = n_active + 1'b1;
        end
        else
        begin
            // Only completed an old entry
            n_active_next = n_active - 1'b1;
        end
    end

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            notEmpty <= 1'b0;
            n_active <= 0;
        end
        else
        begin
            notEmpty <= (n_active_next != 0);
            n_active <= n_active_next;
        end
    end

endmodule // mpf_svc_vtp_l1_miss
