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
// Manage L1 TLB lookup for a single port.
//
// A simple direct mapped cache is maintained as a first level TLB.
// The L1 TLB here filters translation requests in order to relieve
// pressure on the shared VTP TLB service.
//

`include "cci_mpf_if.vh"
`include "mpf_vtp.vh"

module mpf_svc_vtp_l1_lookup
  #(
    parameter THRESHOLD = CCI_TX_ALMOST_FULL_THRESHOLD,
    parameter N_LOCAL_4KB_CACHE_ENTRIES = 512,
    parameter N_LOCAL_2MB_CACHE_ENTRIES = 512,
    // Opaque state passed through the pipeline
    parameter N_OPAQUE_BITS = 0,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // A single request channel.
    input  logic reqEn,
    input  t_mpf_vtp_lookup_req req,
    input  logic [N_OPAQUE_BITS-1 : 0] reqOpaque,
    output logic almostFull,

    // Response channel. Responses are buffered internally by a FIFO and
    // must be dequeud explicitly with "deq".
    output logic notEmpty,
    // The original request.
    output t_mpf_vtp_lookup_req req_out,
    output logic [N_OPAQUE_BITS-1 : 0] reqOpaque_out,
    // Translation result. The error field is 0 when translation succeeds.
    output t_mpf_vtp_lookup_rsp rsp,
    input  logic deq,

    // Insert translation into L1 cache.  Like lookupVA, these addresses are
    // transformed internally for page sizes larger than 4KB.
    input  t_tlb_4kb_va_page_idx insertVA,
    input  t_tlb_4kb_pa_page_idx insertPA,
    input  en_insert_4kb,
    input  en_insert_2mb,

    // CSRs
    mpf_vtp_csrs_if.vtp csrs
    );

    // ====================================================================
    //
    //  State to be recorded through the pipeline while the L1 cache
    //  is read.
    //
    // ====================================================================

    // Struct for passing state through the pipeline
    typedef struct packed
    {
        // Input state
        logic reqEn;
        t_mpf_vtp_lookup_req req;
        logic [N_OPAQUE_BITS-1 : 0] reqOpaque;
    }
    t_vtp_shim_chan_l1_state;

    localparam MAX_STAGE = 3;
    t_vtp_shim_chan_l1_state state[0 : MAX_STAGE];

    always_comb
    begin
        state[0].reqEn = reqEn && ! reset;
        state[0].req = req;
        state[0].reqOpaque = reqOpaque;
    end

    genvar s;
    generate
        for (s = 1; s <= MAX_STAGE; s = s + 1)
        begin : st
            always_ff @(posedge clk)
            begin
                state[s].reqEn <= state[s - 1].reqEn;
                state[s].req <= state[s - 1].req;
                state[s].reqOpaque <= state[s - 1].reqOpaque;

                if (reset)
                begin
                    state[s].reqEn <= 1'b0;
                end
            end
        end
    endgenerate


    // ====================================================================
    //
    //  L1 TLB caches
    //
    // ====================================================================

    logic l1_hit_4kb;
    logic l1_hit_2mb;
    logic l1_hit;

    t_mpf_vtp_lookup_rsp l1_result;

    mpf_svc_vtp_l1_caches
      #(
        .N_LOCAL_4KB_CACHE_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      l1_caches
       (
        .clk,
        .reset,

        .lookupVA(state[0].req.pageVA),
        .T3_hit_4kb(l1_hit_4kb),
        .T3_hit_2mb(l1_hit_2mb),
        .T3_hit(l1_hit),
        .T3_hitPA(l1_result.pagePA),

        .insertVA,
        .insertPA,
        .en_insert_4kb,
        .en_insert_2mb,

        .csrs
        );

    assign l1_result.error = ! l1_hit;
    assign l1_result.isBigPage = l1_hit_2mb;


    // ====================================================================
    //
    //  Store request and translation in a FIFO.
    //
    // ====================================================================

    // Almost full has to account for requests in flight in the local pipeline.
    localparam FIFO_THRESHOLD = THRESHOLD + MAX_STAGE;

    t_vtp_shim_chan_l1_state fifo_state_out;
    t_mpf_vtp_lookup_rsp l1_result_out;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_vtp_shim_chan_l1_state) + $bits(t_mpf_vtp_lookup_rsp)),
        .N_ENTRIES(FIFO_THRESHOLD + 4),
        .THRESHOLD(FIFO_THRESHOLD),
        .REGISTER_OUTPUT(1),
        .BYPASS_TO_REGISTER(1)
        )
      fifo
       (
        .clk,
        .reset(reset),

        .enq_en(state[MAX_STAGE].reqEn),
        .enq_data({ state[MAX_STAGE], l1_result }),
        .notFull(),
        .almostFull(almostFull),

        .first({ fifo_state_out, l1_result_out }),
        .deq_en(deq),
        .notEmpty(notEmpty)
        );

    always_comb
    begin
        req_out = fifo_state_out.req;
        reqOpaque_out = fifo_state_out.reqOpaque;

        rsp = l1_result_out;
        // Restore the tag from the original request
        rsp.tag = fifo_state_out.req.tag;
        // If value is in L1 it is cacheable
        rsp.mayCache = 1'b1;
    end

endmodule // mpf_svc_vtp_l1_lookup
