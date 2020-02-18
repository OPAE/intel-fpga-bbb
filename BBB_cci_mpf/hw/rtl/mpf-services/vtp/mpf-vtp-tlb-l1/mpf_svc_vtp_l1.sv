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
// VTP translation port. The private L1 is the entry point for each VTP
// translation port exposed to the AFU from the VTP service. Misses in the L1
// are forwarded by logic here to the shared L2 TLB.
//

`include "cci_mpf_if.vh"
`include "mpf_vtp.vh"
`include "cci_mpf_config.vh"


module mpf_svc_vtp_l1
  #(
    parameter THRESHOLD = CCI_TX_ALMOST_FULL_THRESHOLD,
    parameter N_LOCAL_4KB_CACHE_ENTRIES = `VTP_N_C0_L1_4KB_CACHE_ENTRIES,
    parameter N_LOCAL_2MB_CACHE_ENTRIES = `VTP_N_C0_L1_2MB_CACHE_ENTRIES,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    mpf_vtp_port_if.to_master vtp_port,

    // Shared L2 translation service connection
    mpf_vtp_l2_if.client vtp_svc,

    // CSRs
    mpf_vtp_csrs_if.vtp csrs
    );

    // Register incoming almost full for timing. The FIFOs below respond quickly
    // enough despite the delay.
    logic almostFullFromFIU_q;
    always_ff @(posedge clk)
    begin
        almostFullFromFIU_q <= vtp_port.almostFullFromFIU;
    end

    // L1 lookup result wires
    logic l1_fifo_deq;
    logic l1_fifo_notEmpty;
    t_mpf_vtp_lookup_req l1_req_out;
    logic l1_reqIsOrdered_out;
    logic l1_reqAddrIsVirtual_out;
    t_mpf_vtp_lookup_rsp l1_rsp;

    // L1 insertion request wires
    t_tlb_4kb_va_page_idx insertVA;
    t_tlb_4kb_pa_page_idx insertPA;
    logic en_insert_4kb;
    logic en_insert_2mb;

    // Respond with a successful L1 lookup?
    logic l1_rspValid;
    // Forward an unsuccessful L1 lookup to the L2 pipeline?
    logic l1_fwd_to_l2;

    //
    // Lookup in local L1 TLB. There is an internal FIFO, so requests
    // sit inside the module until explicitly dequeued.
    //
    mpf_svc_vtp_l1_lookup
      #(
        .THRESHOLD(THRESHOLD),
        .N_LOCAL_4KB_CACHE_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        // Extra state passed through the pipeline
        .N_OPAQUE_BITS(2),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      l1tlb
       (
        .clk,
        .reset,

        .almostFull(vtp_port.almostFullToAFU),
        .reqEn(vtp_port.reqEn),
        .req(vtp_port.req),
        .reqOpaque({ vtp_port.reqAddrIsVirtual, vtp_port.reqIsOrdered }),

        .notEmpty(l1_fifo_notEmpty),
        .req_out(l1_req_out),
        .reqOpaque_out({ l1_reqAddrIsVirtual_out, l1_reqIsOrdered_out }),
        .rsp(l1_rsp),
        .deq(l1_fifo_deq),

        .insertVA,
        .insertPA,
        .en_insert_4kb,
        .en_insert_2mb,

        .csrs
        );


    //
    // L2 handles translation misses in the L1.
    //
    logic l2_notFull;
    logic l2_notEmpty;

    logic l2_rspValid;
    t_mpf_vtp_lookup_rsp l2_rsp;

    mpf_svc_vtp_l1_miss
      #(
        .N_LOCAL_4KB_CACHE_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      l1miss
       (
        .clk,
        .reset,

        .notFull(l2_notFull),
        .notEmpty(l2_notEmpty),

        // Send to L2 when L1 translation fails
        .reqEn(l1_fwd_to_l2),
        .req(l1_req_out),

        .rspValid(l2_rspValid),
        .rsp(l2_rsp),
        .rspWaitRequest(almostFullFromFIU_q),

        .insertVA,
        .insertPA,
        .en_insert_4kb,
        .en_insert_2mb,

        .vtp_svc,
        .csrs
        );


    //
    // L1 control
    //
    always_comb
    begin
        l1_rspValid = 1'b0;
        l1_fwd_to_l2 = 1'b0;

        // Forward L1 lookup output? In addition to having valid data,
        // we must block if the request is ordered (e.g. a fence) and
        // other requests are still flowing through the VTP L2.
        if (l1_fifo_notEmpty && ! (l1_reqIsOrdered_out && l2_notEmpty) && ! reset)
        begin
            // No L1 translation needed or translation is valid?
            if (! l1_reqAddrIsVirtual_out || ! l1_rsp.error)
            begin
                // Yes: forward directly to FIU unless there is conflicting
                // output from the L2 pipeline.
                l1_rspValid = ! almostFullFromFIU_q && ! l2_rspValid;
            end
            else
            begin
                // L2 lookup needed.
                l1_fwd_to_l2 = l2_notFull;
            end
        end

        l1_fifo_deq = l1_rspValid || l1_fwd_to_l2;
    end

    //
    // Merge L1 and L2 pipeline toward FIU.
    //
    always_ff @(posedge clk)
    begin
        vtp_port.rspValid <= l1_rspValid || l2_rspValid;
        vtp_port.rsp <= l1_rspValid ? l1_rsp : l2_rsp;

        if (reset)
        begin
            vtp_port.rspValid <= 1'b0;
        end
    end

endmodule // mpf_svc_vtp_l1
