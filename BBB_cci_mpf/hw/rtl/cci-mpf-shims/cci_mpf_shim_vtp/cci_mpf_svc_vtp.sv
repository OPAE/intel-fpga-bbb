//
// Copyright (c) 2015, Intel Corporation
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

`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

`include "cci_mpf_shim_vtp.vh"
`include "cci_mpf_config.vh"


//
// Construct the VTP translation service, instantiating a TLB and page table
// walker.  Each VTP client will get a pair of ports to this service: one
// for c0 and one for c1.  Though this service is pipelined, at most one
// address is translated each cycle.  Clients are expected to cache responses
// to reduce the number of requests to this service.
//

module cci_mpf_svc_vtp
  #(
    parameter N_VTP_PORTS = 0,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Clients
    cci_mpf_shim_vtp_svc_if.server vtp_svc[N_VTP_PORTS],

    // Page table walker bus
    cci_mpf_shim_vtp_pt_walk_if.client pt_walk,

    // CSRs
    cci_mpf_csrs.vtp csrs,
    cci_mpf_csrs.vtp_events events
    );

    typedef logic [$clog2(N_VTP_PORTS)-1 : 0] t_cci_mpf_shim_vtp_port_idx;

    // ====================================================================
    //
    //   Turn multiple incoming request channels into a single stream.
    //
    // ====================================================================

    //
    // Buffer incoming requests in small FIFOs.
    //
    t_cci_mpf_shim_vtp_lookup_req new_req[0 : N_VTP_PORTS-1];
    logic [N_VTP_PORTS-1 : 0] arb_grant;
    logic [N_VTP_PORTS-1 : 0] arb_grant_q;
    logic [N_VTP_PORTS-1 : 0] new_req_rdy;
    logic merged_fifo_almFull;

    // Select a new request if granted arbitration and a request is ready.
    // The test for a request being ready is required because arbitration
    // results are registered and are thus a cycle out of date.
    logic [N_VTP_PORTS-1 : 0] new_req_sel;
    assign new_req_sel = arb_grant_q & new_req_rdy;

    genvar p;
    generate
        for (p = 0; p < N_VTP_PORTS; p = p + 1)
        begin : inp
            // Construct the FIFO so that the incoming lookup request
            // can be registered, governed by lookupRdy. Using almostFull
            // and a threshold of 2 leaves a slot available for the
            // incoming registered request.
            logic almost_full;
            assign vtp_svc[p].lookupRdy = ! almost_full;

            cci_mpf_prim_fifo_lutram
              #(
                .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_lookup_req)),
                .N_ENTRIES(CCI_MPF_SHIM_VTP_MAX_SVC_REQS),
                .THRESHOLD(2)
                )
              in_fifo
               (
                .clk,
                .reset,

                .enq_data(vtp_svc[p].lookupReq),
                .enq_en(vtp_svc[p].lookupEn),
                .notFull(),
                .almostFull(almost_full),

                .first(new_req[p]),
                .deq_en(new_req_sel[p]),
                .notEmpty(new_req_rdy[p])
                );

            always_ff @(posedge clk)
            begin
                // synthesis translate_off
                if (! reset && DEBUG_MESSAGES)
                begin
                    if (vtp_svc[p].lookupEn)
                    begin
                        $display("VTP SVC %0t: Incoming REQ VA 0x%x (line 0x%x), tag (%0d, %0d)",
                                 $time,
                                 {vtp_svc[p].lookupReq.pageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                                 {vtp_svc[p].lookupReq.pageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0)},
                                 p, vtp_svc[p].lookupReq.tag);
                    end
                end
                // synthesis translate_on
            end
        end
    endgenerate


    //
    // Fair arbitration for new requests
    //
    t_cci_mpf_shim_vtp_port_idx arb_grant_idx;
    t_cci_mpf_shim_vtp_port_idx arb_grant_idx_q;

    cci_mpf_prim_arb_rr
      #(
        .NUM_CLIENTS(N_VTP_PORTS)
        )
      arb
       (
        .clk,
        .reset,

        .ena(! merged_fifo_almFull),
        .request(new_req_rdy),
        .grant(arb_grant),
        .grantIdx(arb_grant_idx)
        );

    always_ff @(posedge clk)
    begin
        arb_grant_q <= arb_grant;
        arb_grant_idx_q <= arb_grant_idx;
    end


    //
    // Post-arbitration, unified FIFO
    //
    t_cci_mpf_shim_vtp_lookup_req winner_req;
    logic winner_req_en;
    t_cci_mpf_shim_vtp_port_idx winner_req_port_idx;

    t_cci_mpf_shim_vtp_lookup_req first;
    t_cci_mpf_shim_vtp_port_idx first_port_idx;
    logic first_rdy;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            winner_req_en <= 1'b0;
        end
        else
        begin
            winner_req_en <= new_req_sel[arb_grant_idx_q];
        end

        winner_req <= new_req[arb_grant_idx_q];
        winner_req_port_idx <= arb_grant_idx_q;
    end

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_lookup_req) +
                     $bits(t_cci_mpf_shim_vtp_port_idx)),
        .N_ENTRIES(4),
        .THRESHOLD(2),
        .REGISTER_OUTPUT(1)
        )
      merged_fifo
       (
        .clk,
        .reset,

        .enq_data({ winner_req, winner_req_port_idx }),
        .enq_en(winner_req_en),
        .notFull(),
        .almostFull(merged_fifo_almFull),

        .first({ first, first_port_idx }),
        .deq_en(tlb_if.lookupEn),
        .notEmpty(first_rdy)
        );

    always_ff @(posedge clk)
    begin
        // synthesis translate_off
        if (! reset && DEBUG_MESSAGES)
        begin
            if (winner_req_en)
            begin
                $display("VTP SVC %0t: Arb winner REQ VA 0x%x (line 0x%x), tag (%0d, %0d)",
                         $time,
                         {winner_req.pageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         {winner_req.pageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0)},
                         winner_req_port_idx, winner_req.tag);
            end
        end
        // synthesis translate_on
    end


    // ====================================================================
    //
    //  Construct a unified TLB lookup interface here, composed of
    //  parallel pipelines for each page size.
    //
    // ====================================================================

    // Interface to the TLB
    cci_mpf_shim_vtp_tlb_if tlb_if();

    cci_mpf_svc_vtp_multi_size_tlb
      #(
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      tlb
       (
        .clk,
        .reset,
        .tlb_if,
        .csrs,
        .events
        );


    // ====================================================================
    //
    //  Pass requests to the TLB and store responses in a FIFO.
    //
    // ====================================================================

    //
    // A FIFO holds the requests passed to the TLB in case the TLB does
    // not hold the requested translation. In that case, the request
    // must be forwarded to the page miss handler.
    //
    // The FIFO is large enough to hold all requests outstanding in the
    // TLB. The almost full signal in the FIFO limits traffic to the
    // TLB pipeline.
    //
    logic tlb_lookup_rsp_deq_en;
    logic tlb_almostFull;
    t_cci_mpf_shim_vtp_lookup_req tlb_processed_req;
    t_cci_mpf_shim_vtp_port_idx tlb_processed_port;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_lookup_req) +
                     $bits(t_cci_mpf_shim_vtp_port_idx)),
        .N_ENTRIES(CCI_MPF_SHIM_VTP_TLB_MIN_PIPE_STAGES + 4),
        .THRESHOLD(3),
        .REGISTER_OUTPUT(1)
        )
      processed_reqs
       (
        .clk,
        .reset,

        .enq_data({ first, first_port_idx }),
        .enq_en(tlb_if.lookupEn),
        .almostFull(tlb_almostFull),

        .first({ tlb_processed_req, tlb_processed_port }),
        .deq_en(tlb_lookup_rsp_deq_en),
        // Ignored since TLB will respond only when there is an entry here
        .notEmpty(),
        .notFull()
        );

    //
    // Send requests to the TLB.
    //
    always_comb
    begin
        tlb_if.lookupEn = first_rdy && ! tlb_almostFull && tlb_if.lookupRdy;
        tlb_if.lookupPageVA = first.pageVA;
        tlb_if.lookupIsSpeculative = first.isSpeculative;
    end

    always_ff @(posedge clk)
    begin
        // synthesis translate_off
        if (! reset && DEBUG_MESSAGES)
        begin
            if (tlb_if.lookupEn)
            begin
                $display("VTP SVC %0t: TLB lookup REQ VA 0x%x (line 0x%x), tag (%0d, %0d)%0s",
                         $time,
                         {tlb_if.lookupPageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         {tlb_if.lookupPageVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0)},
                         first_port_idx, first.tag,
                         (first.isSpeculative ? ", speculative" : ""));
            end
        end
        // synthesis translate_on
    end

    //
    // Store TLB responses in a FIFO. Dequeues from the FIFO may stall
    // if there are a lot of TLB misses and the page walker pipeline
    // fills. As a consequence, the FIFO here must be at least as deep
    // as the processed_reqs FIFO.
    //
    typedef struct packed
    {
        t_tlb_4kb_pa_page_idx pagePA;
        logic tlbHit;
        logic tlbMiss;
        logic isBigPage;
        logic notPresent;    // Failed speculative translation (not in page table)
    }
    t_cci_mpf_shim_vtp_tlb_rsp;

    t_cci_mpf_shim_vtp_tlb_rsp tlb_rsp_in, tlb_lookup_rsp;
    logic tlb_lookup_rsp_valid;

    always_ff @(posedge clk)
    begin
        tlb_rsp_in.pagePA <= tlb_if.lookupRspPagePA;
        tlb_rsp_in.tlbHit <= tlb_if.lookupRspHit;
        tlb_rsp_in.tlbMiss <= tlb_if.lookupMiss;
        tlb_rsp_in.isBigPage <= tlb_if.lookupRspIsBigPage;
        tlb_rsp_in.notPresent <= tlb_if.lookupRspNotPresent;
    end

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_tlb_rsp)),
        .N_ENTRIES(CCI_MPF_SHIM_VTP_TLB_MIN_PIPE_STAGES + 4),
        .THRESHOLD(3),
        .REGISTER_OUTPUT(1)
        )
      processed_rsps
       (
        .clk,
        .reset,

        .enq_data(tlb_rsp_in),
        .enq_en(tlb_rsp_in.tlbHit || tlb_rsp_in.tlbMiss),
        // Ignored. Space is managed by processed_reqs FIFO.
        .almostFull(),

        .first(tlb_lookup_rsp),
        .deq_en(tlb_lookup_rsp_deq_en),
        .notEmpty(tlb_lookup_rsp_valid),
        .notFull()
        );

    always_ff @(posedge clk)
    begin
        // synthesis translate_off
        if (! reset && DEBUG_MESSAGES)
        begin
            if (tlb_rsp_in.tlbHit)
            begin
                $display("VTP SVC %0t: TLB lookup RESP hit PA 0x%x (line 0x%x), %0s page%0s",
                         $time,
                         {tlb_rsp_in.pagePA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         {tlb_rsp_in.pagePA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0)},
                         (tlb_rsp_in.isBigPage ? "2MB" : "4KB"),
                         (tlb_rsp_in.notPresent ? " [NOT PRESENT]" : ""));
            end
            if (tlb_rsp_in.tlbMiss)
            begin
                $display("VTP SVC %0t: TLB lookup RESP miss", $time);
            end
        end
        // synthesis translate_on
    end


    // ====================================================================
    //
    //   Page walker.
    //
    // ====================================================================

    logic pt_walk_req_valid;
    logic pt_walk_rsp_valid;
    t_cci_mpf_shim_vtp_lookup_rsp pt_walk_rsp;
    t_cci_mpf_shim_vtp_port_idx pt_walk_rsp_port_idx;
    logic pt_walk_notFull;

    cci_mpf_svc_vtp_do_pt_walk
      #(
        .N_VTP_PORTS(N_VTP_PORTS),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      do_pt_walk
       (
        .clk,
        .reset,

        .pt_walk_req_valid,
        .pt_walk_req(tlb_processed_req),
        .pt_walk_req_port_idx(tlb_processed_port),

        .pt_walk_rsp_valid,
        .pt_walk_rsp,
        .pt_walk_rsp_port_idx,
        .pt_walk_notFull,

        .tlb_if(tlb_if),
        .pt_walk(pt_walk),
        .csrs(csrs)
        );

    assign pt_walk_req_valid = tlb_lookup_rsp_valid && tlb_lookup_rsp.tlbMiss &&
                               pt_walk_notFull;


    // ====================================================================
    //
    //   Route responses to clients.
    //
    // ====================================================================

    //
    // Responses may come either directly from the TLB caches or from
    // the page walker.
    //

    // Is there a TLB response to forward back to the client? The page
    // walker has precedence.
    logic do_tlb_hit_rsp;
    assign do_tlb_hit_rsp = tlb_lookup_rsp_valid && tlb_lookup_rsp.tlbHit &&
                            ! pt_walk_rsp_valid;

    assign tlb_lookup_rsp_deq_en = do_tlb_hit_rsp || pt_walk_req_valid;

    t_cci_mpf_shim_vtp_lookup_rsp rsp_data;
    logic [N_VTP_PORTS-1 : 0] rsp_port_onehot;
    logic pt_walk_rsp_valid_q;

    // Merge the two possible response paths (TLB cache and page table walker).
    always_ff @(posedge clk)
    begin
        rsp_port_onehot <= {N_VTP_PORTS{1'b0}};
        pt_walk_rsp_valid_q <= pt_walk_rsp_valid;

        if (pt_walk_rsp_valid)
        begin
            // Response from page table walker
            rsp_port_onehot[pt_walk_rsp_port_idx] <= 1'b1;
            rsp_data <= pt_walk_rsp;
        end
        else
        begin
            // Response from TLB cache
            rsp_port_onehot[tlb_processed_port] <= tlb_lookup_rsp_valid && tlb_lookup_rsp.tlbHit;
            rsp_data.pagePA <= tlb_lookup_rsp.pagePA;
            rsp_data.isBigPage <= tlb_lookup_rsp.isBigPage;
            rsp_data.mayCache <= 1'b1;
            rsp_data.tag <= tlb_processed_req.tag;
            rsp_data.error <= tlb_lookup_rsp.notPresent;
        end
    end

    // Forward responses back to the clients.
    generate
        for (p = 0; p < N_VTP_PORTS; p = p + 1)
        begin : rsp
            always_comb
            begin
                vtp_svc[p].lookupRspValid = rsp_port_onehot[p];
                vtp_svc[p].lookupRsp = rsp_data;
            end

            always_ff @(posedge clk)
            begin
                // synthesis translate_off
                if (! reset && DEBUG_MESSAGES)
                begin
                    if (rsp_port_onehot[p])
                    begin
                        $display("VTP SVC %0t: Completed %sRESP (from %0s) PA 0x%x (line 0x%x), tag (%0d, %0d), %0s",
                                 $time,
                                 (rsp_data.error ? "ERROR " : ""),
                                 (pt_walk_rsp_valid_q ? "PT" : "TLB"),
                                 {rsp_data.pagePA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                                 {rsp_data.pagePA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0)},
                                 p, rsp_data.tag,
                                 (rsp_data.isBigPage ? "2MB" : "4KB"));
                    end
                end
                // synthesis translate_on
            end
        end
    endgenerate

endmodule // cci_mpf_svc_vtp


//
// TLB cache lookup interface that checks all pages sizes in parallel.
//
module cci_mpf_svc_vtp_multi_size_tlb
  #(
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // TLB lookup
    cci_mpf_shim_vtp_tlb_if.server tlb_if,

    // CSRs
    cci_mpf_csrs.vtp csrs,
    cci_mpf_csrs.vtp_events events
    );

    //
    // Allocate two TLBs.  One manages 4KB pages and the other manages
    // 2MB pages.
    //

    cci_mpf_shim_vtp_tlb_if tlb_if_4kb();

    cci_mpf_svc_vtp_tlb
      #(
        .CCI_PT_PAGE_OFFSET_BITS(CCI_PT_4KB_PAGE_OFFSET_BITS),
        .NUM_TLB_SETS(`VTP_N_TLB_4KB_SETS),
        .NUM_TLB_SET_WAYS(`VTP_N_TLB_4KB_WAYS),
        .DEBUG_MESSAGES(DEBUG_MESSAGES),
        .DEBUG_NAME("4KB")
        )
      tlb4kb
       (
        .clk,
        .reset,
        .tlb_if(tlb_if_4kb),
        .csrs
        );


    cci_mpf_shim_vtp_tlb_if tlb_if_2mb();

    cci_mpf_svc_vtp_tlb
      #(
        .CCI_PT_PAGE_OFFSET_BITS(CCI_PT_2MB_PAGE_OFFSET_BITS),
        .NUM_TLB_SETS(`VTP_N_TLB_2MB_SETS),
        .NUM_TLB_SET_WAYS(`VTP_N_TLB_2MB_WAYS),
        .DEBUG_MESSAGES(DEBUG_MESSAGES),
        .DEBUG_NAME("2MB")
        )
      tlb2mb
       (
        .clk,
        .reset,
        .tlb_if(tlb_if_2mb),
        .csrs
        );

    // When the pipeline requests a TLB lookup do it on both pipelines.
    assign tlb_if_4kb.lookupPageVA = tlb_if.lookupPageVA;
    assign tlb_if_4kb.lookupEn = tlb_if.lookupEn;
    assign tlb_if_4kb.lookupIsSpeculative = tlb_if.lookupIsSpeculative;

    assign tlb_if_2mb.lookupPageVA = tlb_if.lookupPageVA;
    assign tlb_if_2mb.lookupEn = tlb_if.lookupEn;
    assign tlb_if_2mb.lookupIsSpeculative = tlb_if.lookupIsSpeculative;

    assign tlb_if.lookupRdy = tlb_if_4kb.lookupRdy && tlb_if_2mb.lookupRdy;

    // The TLB pipeline is fixed length, so responses arrive together.
    // At most one TLB should have a translation for a given address.
    assign tlb_if.lookupRspHit = tlb_if_4kb.lookupRspHit ||
                                 tlb_if_2mb.lookupRspHit;
    assign tlb_if.lookupRspIsBigPage = tlb_if_2mb.lookupRspHit;
    assign tlb_if.lookupRspPagePA =
        tlb_if_4kb.lookupRspHit ? tlb_if_4kb.lookupRspPagePA :
                                  tlb_if_2mb.lookupRspPagePA;
    assign tlb_if.lookupRspNotPresent =
        tlb_if_4kb.lookupRspHit ? tlb_if_4kb.lookupRspNotPresent :
                                  tlb_if_2mb.lookupRspNotPresent;

    // Read the page table if both TLBs miss
    assign tlb_if.lookupMiss = tlb_if_4kb.lookupMiss && tlb_if_2mb.lookupMiss;
    assign tlb_if.lookupMissVA = tlb_if_4kb.lookupMissVA;

    // Validation
    always_ff @(posedge clk)
    begin
        if (! reset)
        begin
            assert(! tlb_if_4kb.lookupRspHit || ! tlb_if_2mb.lookupRspHit) else
                $fatal("cci_mpf_svc_vtp: Both TLBs valid!");

            if (tlb_if.lookupMiss)
            begin
                assert(vtp4kbTo2mbVA(tlb_if_4kb.lookupMissVA) ==
                       vtp4kbTo2mbVA(tlb_if_2mb.lookupMissVA)) else
                    $fatal("cci_mpf_svc_vtp: Both TLBs missed but addresses different!");
            end
        end
    end


    //
    // Direct fills to the appropriate TLB depending on the page size
    //
    always_ff @(posedge clk)
    begin
        tlb_if_4kb.fillEn <= tlb_if.fillEn && ! tlb_if.fillBigPage;
        tlb_if_2mb.fillEn <= tlb_if.fillEn && tlb_if.fillBigPage;

        tlb_if_4kb.fillVA <= tlb_if.fillVA;
        tlb_if_4kb.fillPA <= tlb_if.fillPA;
        tlb_if_2mb.fillVA <= tlb_if.fillVA;
        tlb_if_2mb.fillPA <= tlb_if.fillPA;

        tlb_if_4kb.fillBigPage <= 1'b0;
        tlb_if_2mb.fillBigPage <= 1'b1;

        tlb_if_4kb.fillNotPresent <= tlb_if.fillNotPresent;
        tlb_if_2mb.fillNotPresent <= tlb_if.fillNotPresent;

        if (reset)
        begin
            tlb_if_4kb.fillEn <= 1'b0;
            tlb_if_2mb.fillEn <= 1'b0;
        end
    end


    // Statistics
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            events.vtp_out_event_4kb_hit <= 1'b0;
            events.vtp_out_event_2mb_hit <= 1'b0;

            events.vtp_out_event_4kb_miss <= 1'b0;
            events.vtp_out_event_2mb_miss <= 1'b0;
        end
        else
        begin
            events.vtp_out_event_4kb_hit <= tlb_if_4kb.lookupRspHit;
            events.vtp_out_event_2mb_hit <= tlb_if_2mb.lookupRspHit;

            // Wait to record misses until the corresponding fill. Until the
            // fill we don't know whether it was a 4KB or a 2MB page miss.
            events.vtp_out_event_4kb_miss <= tlb_if_4kb.fillEn;
            events.vtp_out_event_2mb_miss <= tlb_if_2mb.fillEn;
        end
    end

endmodule // cci_mpf_svc_vtp_multi_size_tlb


module cci_mpf_svc_vtp_do_pt_walk
  #(
    parameter N_VTP_PORTS = 0,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Incoming requests
    input  logic pt_walk_req_valid,
    input  t_cci_mpf_shim_vtp_lookup_req pt_walk_req,
    input  logic [$clog2(N_VTP_PORTS)-1 : 0] pt_walk_req_port_idx,
    output logic pt_walk_notFull,

    // Outgoing walk responses
    output logic pt_walk_rsp_valid,
    output t_cci_mpf_shim_vtp_lookup_rsp pt_walk_rsp,
    output logic [$clog2(N_VTP_PORTS)-1 : 0] pt_walk_rsp_port_idx,

    // Outgoing fill messages to the TLBs
    cci_mpf_shim_vtp_tlb_if.fill tlb_if,

    // Page table walker bus
    cci_mpf_shim_vtp_pt_walk_if.client pt_walk,

    // CSRs
    cci_mpf_csrs.vtp csrs
    );

    typedef logic [$clog2(N_VTP_PORTS)-1 : 0] t_cci_mpf_shim_vtp_port_idx;

    //
    // Push incoming requests to a FIFO. This allows the primary TLB pipeline
    // to flow around multiple translations that miss.
    //
    logic first_rdy;
    t_cci_mpf_shim_vtp_lookup_req first;
    t_cci_mpf_shim_vtp_port_idx first_port_idx;
    logic deq_first;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_lookup_req) +
                     $bits(t_cci_mpf_shim_vtp_port_idx)),
        .N_ENTRIES(8),
        .REGISTER_OUTPUT(1)
        )
      merged_fifo
       (
        .clk,
        .reset,

        .enq_data({ pt_walk_req, pt_walk_req_port_idx }),
        .enq_en(pt_walk_req_valid),
        .notFull(pt_walk_notFull),
        .almostFull(),

        .first({ first, first_port_idx }),
        .deq_en(deq_first),
        .notEmpty(first_rdy)
        );


    //
    // Forward requests to the page walker.
    //
    assign deq_first = first_rdy && pt_walk.reqRdy && ! pt_walk.reqEn;

    always_ff @(posedge clk)
    begin
        pt_walk.reqEn <= deq_first;
        pt_walk.reqVA <= first.pageVA;
        pt_walk.reqMeta <= t_cci_mpf_shim_vtp_pt_walk_meta'(first_port_idx);
        pt_walk.reqIsSpeculative <= first.isSpeculative;
        pt_walk.reqTag <= first.tag;

        if (reset)
        begin
            pt_walk.reqEn <= 1'b0;
        end
    end


    //
    // Return responses from the page walker.
    //
    always_ff @(posedge clk)
    begin
        pt_walk_rsp_valid <= pt_walk.rspEn &&
                             // rspNotPresent is a fatal error unless the request is
                             // speculative.
                             (! pt_walk.rspNotPresent || pt_walk.rspIsSpeculative);

        pt_walk_rsp.pagePA <= pt_walk.rspPA;
        pt_walk_rsp.error <= pt_walk.rspNotPresent;
        pt_walk_rsp.tag <= pt_walk.rspTag;
        pt_walk_rsp.isBigPage <= pt_walk.rspIsBigPage;
        pt_walk_rsp.mayCache <= pt_walk.rspIsCacheable;
        pt_walk_rsp_port_idx <= t_cci_mpf_shim_vtp_port_idx'(pt_walk.rspMeta);

        if (reset)
        begin
            pt_walk_rsp_valid <= 1'b0;
        end
    end


    //
    // Insert new translations in the TLB.
    //
    always_ff @(posedge clk)
    begin
        tlb_if.fillEn <= pt_walk.rspEn && pt_walk.rspIsCacheable;
        tlb_if.fillVA <= pt_walk.rspVA;
        tlb_if.fillPA <= pt_walk.rspPA;
        tlb_if.fillBigPage <= pt_walk.rspIsBigPage;
        tlb_if.fillNotPresent <= pt_walk.rspNotPresent;

        if (reset)
        begin
            tlb_if.fillEn <= 1'b0;
        end
    end


    always_ff @(posedge clk)
    begin
        // synthesis translate_off
        if (! reset && DEBUG_MESSAGES)
        begin
            if (pt_walk.reqEn)
            begin
                $display("VTP SVC %0t: REQ page walk VA 0x%x, tag (%0d, %0d)",
                         $time,
                         {pt_walk.reqVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         pt_walk.reqMeta, pt_walk.reqTag);
            end

            if (pt_walk_rsp_valid)
            begin
                $display("VTP SVC %0t: %sRESP page walk PA 0x%x, %0s, tag (%0d, %0d)",
                         $time,
                         (pt_walk_rsp.error ? "ERROR " : ""),
                         {pt_walk_rsp.pagePA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         (pt_walk_rsp.isBigPage ? "2MB" : "4KB"),
                         pt_walk_rsp_port_idx, pt_walk_rsp.tag);
            end

            if (tlb_if.fillEn)
            begin
                $display("VTP SVC %0t: TLB fill VA 0x%x (line 0x%x), PA 0x%x (line 0x%x), %0s%0s",
                         $time,
                         {tlb_if.fillVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         {tlb_if.fillVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0)},
                         {tlb_if.fillPA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         {tlb_if.fillPA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0)},
                         (tlb_if.fillBigPage ? "2MB" : "4KB"),
                         (tlb_if.fillNotPresent ? " [NOT PRESENT]" : ""));
            end
        end
        // synthesis translate_on
    end

    // Detect errors
    always_ff @(posedge clk)
    begin
        if (! reset)
        begin
            assert (! pt_walk.rspEn || ! pt_walk.rspNotPresent || pt_walk.rspIsSpeculative) else
                $fatal("cci_mpf_svc_vtp: VA 0x%x not present in page table",
                       {pt_walk.rspVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
        end
    end

endmodule // cci_mpf_svc_vtp_do_pt_walk
