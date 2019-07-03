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

//
// Deduplicate translation requests on a single client/server VTP stream
// between the private L1 and the shared L2 caches. It would be technically
// correct to allow duplicates, though a waste of L2 bandwidth. The
// page table walkers don't detect duplicate requests, either, which can
// be a performance problem without this filter.
//

`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

`include "cci_mpf_shim_vtp.vh"
`include "cci_mpf_config.vh"


module cci_mpf_svc_vtp_dedup
  #(
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    cci_mpf_shim_vtp_svc_if.server to_client,
    cci_mpf_shim_vtp_svc_if.client to_server
    );

    // ====================================================================
    //
    // Client to server requests
    //
    // ====================================================================

    logic next_req_valid;
    logic next_req_deq_en;
    logic next_req_addr_matches_prev;
    t_cci_mpf_shim_vtp_lookup_req next_req;

    assign next_req_deq_en = to_server.lookupRdy && next_req_valid;

    // Put the sequential address comparison at the incoming side of the FIFO
    // to reduce timing pressure on the output/decision side. The comparison
    // here isn't proof that the base tag is valid, just that the address matches.
    t_tlb_4kb_va_page_idx prev_req_pageVA;
    logic prev_req_isSpeculative;

    logic new_req_matches_prev;
    assign new_req_matches_prev =
        (prev_req_pageVA == to_client.lookupReq.pageVA) &&
        (prev_req_isSpeculative == to_client.lookupReq.isSpeculative);

    always_ff @(posedge clk)
    begin
        if (to_client.lookupEn)
        begin
            prev_req_pageVA <= to_client.lookupReq.pageVA;
            prev_req_isSpeculative <= to_client.lookupReq.isSpeculative;
        end

        if (reset)
        begin
            prev_req_pageVA <= t_tlb_4kb_pa_page_idx'(0);
            prev_req_isSpeculative <= 1'b0;
        end
    end

    // Incoming request FIFO
    cci_mpf_prim_fifo2
      #(
        .N_DATA_BITS(1 + $bits(t_cci_mpf_shim_vtp_lookup_req))
        )
      req_fifo
       (
        .clk,
        .reset,

        .enq_data({ new_req_matches_prev, to_client.lookupReq }),
        .enq_en(to_client.lookupEn),
        .notFull(to_client.lookupRdy),

        .first({ next_req_addr_matches_prev, next_req }),
        .deq_en(next_req_deq_en),
        .notEmpty(next_req_valid)
        );


    //
    // Track the most recent request and build a chain of duplicates.
    //

    logic cur_req_valid;
    t_cci_mpf_shim_vtp_req_tag cur_req_tag;
    t_cci_mpf_shim_vtp_req_tag cur_req_tail;

    logic next_req_is_dup;
    assign next_req_is_dup = cur_req_valid && next_req_addr_matches_prev;

    t_cci_mpf_shim_vtp_req_tag cur_rsp_tag, next_rsp_tag;
    t_cci_mpf_shim_vtp_req_tag rsp_tail_ptr_raddr, rsp_tail_ptr_rdata;

    // Two memories are used to track duplicate references. The next pointer forms
    // a linked list of duplicates, indexed by unique tags. The tail pointer is
    // stored at the index of the base reference -- the reference from which
    // duplicates will be filled. Putting the tail pointer there instead of
    // in another linked list simplifies write port management.
    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(CCI_MPF_SHIM_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_req_tag))
        )
      next_ptr
       (
        .clk,
        .reset,

        .raddr(cur_rsp_tag),
        .rdata(next_rsp_tag),

        .waddr(cur_req_tail),
        .wen(next_req_deq_en && next_req_is_dup),
        .wdata(next_req.tag)
        );

    // Tail pointers are valid only for base requests -- the requests that are not
    // duplicates and are forwarded to the server.
    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(CCI_MPF_SHIM_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_req_tag))
        )
      tail_ptr
       (
        .clk,
        .reset,

        .raddr(rsp_tail_ptr_raddr),
        .rdata(rsp_tail_ptr_rdata),

        .waddr(next_req_is_dup ? cur_req_tag : next_req.tag),
        .wen(next_req_deq_en),
        .wdata(next_req.tag)
        );

    // Track the current base request
    always_ff @(posedge clk)
    begin
        // New request that isn't a duplicate?
        if (next_req_deq_en && ! next_req_is_dup)
        begin
            // Not duplicate. The next request becomes the tracked one.
            cur_req_valid <= 1'b1;
            cur_req_tag <= next_req.tag;
        end
        else if (to_server.lookupRspValid &&
                 (to_server.lookupRsp.tag == cur_req_tag))
        begin
            // The response for the current base request has arrived. Time
            // to stop collecting duplicates. We use the incoming to_server
            // version instead of the FIFO below in order to ensure that
            // duplicate collection stops before the duplicate chain is
            // accessed.
            cur_req_valid <= 1'b0;
        end

        // The tail pointer is always updated as new requests arrive, even
        // requests that are duplicates. It is used to construct the linked
        // list of duplicates.
        if (next_req_deq_en)
        begin
            cur_req_tail <= next_req.tag;
        end
    end

    //
    // Forward non-duplicate requests to the server.
    always_comb
    begin
        to_server.lookupEn = next_req_deq_en && ! next_req_is_dup;
        to_server.lookupReq = next_req;
    end


    // ====================================================================
    //
    // Server to client responses
    //
    // ====================================================================

    t_cci_mpf_shim_vtp_lookup_rsp rsp_fifo_first;
    logic rsp_fifo_valid;
    logic rsp_fifo_deq_en;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_lookup_rsp)),
        .N_ENTRIES(CCI_MPF_SHIM_VTP_MAX_SVC_REQS),
        .REGISTER_OUTPUT(1),
        .BYPASS_TO_REGISTER(1)
        )
      rsp_fifo
       (
        .clk,
        .reset,

        .enq_data(to_server.lookupRsp),
        .enq_en(to_server.lookupRspValid),
        // FIFO is large enough so it can't fill
        .notFull(),
        .almostFull(),

        .first(rsp_fifo_first),
        .deq_en(rsp_fifo_deq_en),
        .notEmpty(rsp_fifo_valid)
        );

    logic cur_rsp_valid;
    t_cci_mpf_shim_vtp_lookup_rsp cur_rsp;
    t_cci_mpf_shim_vtp_req_tag cur_rsp_dedup_tail_tag;

    assign cur_rsp_tag = cur_rsp.tag;
    assign rsp_tail_ptr_raddr = rsp_fifo_first.tag;

    // A deduplication chain is active while the linked list starting with the
    // base request and ending with the tail tag is in flight.
    logic rsp_dedup_active;
    assign rsp_dedup_active = cur_rsp_valid && (cur_rsp_dedup_tail_tag != cur_rsp.tag);
    assign rsp_fifo_deq_en = rsp_fifo_valid && ! rsp_dedup_active;

    always_ff @(posedge clk)
    begin
        if (rsp_dedup_active)
        begin
            // In a dedup chain. Move to the next entry in the list.
            cur_rsp.tag <= next_rsp_tag;

            // Turn off the mayCache bit. The first response should already
            // have caused a fill.
            cur_rsp.mayCache <= 1'b0;
        end
        else if (rsp_fifo_valid)
        begin
            // Not processing a chain and a new response is available from
            // the server.
            cur_rsp <= rsp_fifo_first;
            cur_rsp_valid <= 1'b1;

            // Look up the tail of the dedup chain associated with this
            // response. An empty chain is indicated by a tail that points
            // to the response itself.
            cur_rsp_dedup_tail_tag <= rsp_tail_ptr_rdata;
        end
        else
        begin
            cur_rsp_valid <= 1'b0;
        end

        if (reset)
        begin
            cur_rsp_valid <= 1'b0;
        end
    end

    always_comb
    begin
        to_client.lookupRsp = cur_rsp;
        to_client.lookupRspValid = cur_rsp_valid;
    end


    // ====================================================================
    //
    //  Debug
    //
    // ====================================================================

    // synthesis translate_off
    always_ff @(posedge clk)
    begin
        if (DEBUG_MESSAGES && ! reset)
        begin
            if (to_server.lookupEn)
            begin
                $display("%m VTP DEDUP: %0t REQ new tag 0x%x, VA 0x%x",
                         $time,
                         to_server.lookupReq.tag,
                         {to_server.lookupReq.pageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
            end

            if (next_req_deq_en && next_req_is_dup)
            begin
                $display("%m VTP DEDUP: %0t REQ duplicate tag 0x%x, prev tag 0x%x, VA 0x%x",
                         $time,
                         next_req.tag,
                         cur_req_tail,
                         {next_req.pageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
            end

            if (rsp_dedup_active)
            begin
                $display("%m VTP DEDUP: %0t RESP duplicate tag 0x%x, PA 0x%x",
                         $time,
                         next_rsp_tag,
                         {cur_rsp.pagePA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
            end
            else if (rsp_fifo_valid)
            begin
                $display("%m VTP DEDUP: %0t RESP new tag 0x%x, PA 0x%x",
                         $time,
                         rsp_fifo_first.tag,
                         {rsp_fifo_first.pagePA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
            end
        end
    end
    // synthesis translate_on

endmodule // cci_mpf_svc_vtp_dedup

