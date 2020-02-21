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

`include "mpf_vtp.vh"


module mpf_svc_vtp_port_wrapper_unordered
   (
    input  logic clk,
    input  logic reset,

    // Translation port
    mpf_vtp_port_if.to_slave vtp_port,

    //
    // Lookup requests
    //
    input  logic reqEn,
    input  t_mpf_vtp_port_wrapper_req req,
    output logic notFull,
    // The reqIdx is a unique index assigned to a new request. (Up to
    // MPF_VTP_MAX_SVC_REQS, which is used to derive t_mpf_vtp_req_tag's
    // size.) The parent module may use this unique value to store
    // details of a request in a memory, using the matching rspIdx
    // on return.
    output t_mpf_vtp_req_tag reqIdx,

    //
    // Responses
    //
    // A response is ready
    output logic rspValid,
    output t_mpf_vtp_port_wrapper_rsp rsp,
    // Parent accepts the response
    input  logic rspDeqEn,
    // See reqIdx above
    output t_mpf_vtp_req_tag rspIdx
    );


    // ====================================================================
    //
    //  Allocate a unique transaction ID and store request state
    //
    // ====================================================================

    logic heap_notFull;
    t_mpf_vtp_req_tag alloc_idx;
    assign reqIdx = alloc_idx;

    t_mpf_vtp_req_tag free_idx;
    logic free_en;

    always_ff @(posedge clk)
    begin
        notFull <= heap_notFull && ! vtp_port.almostFullToAFU;
    end

    //
    // Heap index manager
    //
    cci_mpf_prim_heap_ctrl
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        // Reserve a slot so notFull can be registered
        .MIN_FREE_SLOTS(2)
        )
      heap_ctrl
       (
        .clk,
        .reset,

        .enq(reqEn),
        .notFull(heap_notFull),
        .allocIdx(alloc_idx),

        .free(free_en),
        .freeIdx(free_idx)
        );

    //
    // Heap data
    //

    logic req_en_q;
    t_mpf_vtp_req_tag alloc_idx_q;
    t_mpf_vtp_port_wrapper_req req_q;

    always_ff @(posedge clk)
    begin
        req_en_q <= reqEn;
        alloc_idx_q <= alloc_idx;
        req_q <= req;
    end

    t_mpf_vtp_port_wrapper_req orig_req;

    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_mpf_vtp_port_wrapper_req))
        )
      heap_data
       (
        .clk,
        .reset,

        .raddr(rspIdx),
        .rdata(orig_req),

        .wen(req_en_q),
        .waddr(alloc_idx_q),
        .wdata(req_q)
        );

    always_ff @(posedge clk)
    begin
        free_en <= rspDeqEn;
        free_idx <= rspIdx;
    end


    // ====================================================================
    //
    //  Send translation requests to the VTP service. Responses may be
    //  out of order. The unique alloc_idx tag will be used to associate
    //  requests and responses.
    //
    // ====================================================================

    assign vtp_port.reqEn = reqEn;
    assign vtp_port.req.tag = alloc_idx;
    assign vtp_port.req.pageVA = vtp4kbPageIdxFromVA(req.addr);
    assign vtp_port.req.isSpeculative = req.isSpeculative;
    assign vtp_port.reqAddrIsVirtual = req.addrIsVirtual;
    assign vtp_port.reqIsOrdered = req.isOrdered;


    // ====================================================================
    //
    //  Responses
    //
    // ====================================================================

    t_mpf_vtp_lookup_rsp lookup_rsp;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_mpf_vtp_lookup_rsp)),
        .N_ENTRIES(8),
        .THRESHOLD(4),
        .REGISTER_OUTPUT(1)
        )
      tlb_fifo_out
       (
        .clk,
        .reset,

        .enq_data(vtp_port.rsp),
        .enq_en(vtp_port.rspValid),
        .notFull(),
        .almostFull(vtp_port.almostFullFromFIU),

        .first(lookup_rsp),
        .deq_en(rspDeqEn),
        .notEmpty(rspValid)
        );

    assign rspIdx = lookup_rsp.tag;
    assign rsp.error = lookup_rsp.error;

    assign rsp.isSpeculative = orig_req.isSpeculative;
    assign rsp.isOrdered = orig_req.isOrdered;

    // The address on response is virtual iff it was virtual on input
    // and translation failed.
    assign rsp.addrIsVirtual = orig_req.addrIsVirtual && lookup_rsp.error;

    always_comb
    begin
        if (! orig_req.addrIsVirtual)
        begin
            // The incoming address wasn't virtual. Keep the original address.
            rsp.addr = orig_req.addr;
        end
        else if (lookup_rsp.isBigPage)
        begin
            // 2MB page
            rsp.addr = t_vtp_clAddr'({ vtp4kbTo2mbPA(lookup_rsp.pagePA),
                                       vtp2mbPageOffsetFromVA(orig_req.addr) });
        end
        else
        begin
            // 4KB page
            rsp.addr = t_vtp_clAddr'({ lookup_rsp.pagePA,
                                       vtp4kbPageOffsetFromVA(orig_req.addr) });
        end
    end

endmodule // mpf_svc_vtp_port_wrapper_unordered


module mpf_svc_vtp_port_wrapper_ordered
   (
    input  logic clk,
    input  logic reset,

    // Translation port
    mpf_vtp_port_if.to_slave vtp_port,

    //
    // Lookup requests
    //
    input  logic reqEn,
    input  t_mpf_vtp_port_wrapper_req req,
    output logic notFull,
    // The reqIdx is a unique index assigned to a new request. (Up to
    // MPF_VTP_MAX_SVC_REQS, which is used to derive t_mpf_vtp_req_tag's
    // size.) The parent module may use this unique value to store
    // details of a request in a memory, using the matching rspIdx
    // on return.
    output t_mpf_vtp_req_tag reqIdx,

    //
    // Responses
    //
    // A response is ready
    output logic rspValid,
    output t_mpf_vtp_port_wrapper_rsp rsp,
    // Parent accepts the response
    input  logic rspDeqEn,
    // See reqIdx above
    output t_mpf_vtp_req_tag rspIdx
    );


    // ====================================================================
    //
    //  Allocate a unique transaction ID and store request state
    //
    // ====================================================================

    logic rob_notFull;
    t_mpf_vtp_req_tag alloc_idx;
    assign reqIdx = alloc_idx;

    always_ff @(posedge clk)
    begin
        notFull <= rob_notFull && ! vtp_port.almostFullToAFU;
    end

    //
    // Reorder buffer control structure allocates unique IDs and maintains
    // a scoreboard so operations that internally complete out of order
    // can be sorted.
    //
    // The indices managed by the ROB are used to assign locations within
    // this module's heap data.
    //
    cci_mpf_prim_rob_ctrl
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        // Reserve a slot so notFull can be registered
        .MIN_FREE_SLOTS(2)
        )
      rob_ctrl
       (
        .clk,
        .reset,

        .alloc(reqEn),
        .notFull(rob_notFull),
        .allocIdx(alloc_idx),

        .enqData_en(vtp_port.rspValid),
        .enqDataIdx(vtp_port.rsp.tag),

        .deq_en(rspDeqEn),
        .notEmpty(rspValid),
        .deqIdx(rspIdx)
        );

    //
    // Heap data
    //

    logic req_en_q;
    t_mpf_vtp_req_tag alloc_idx_q;
    t_mpf_vtp_port_wrapper_req req_q;

    always_ff @(posedge clk)
    begin
        req_en_q <= reqEn;
        alloc_idx_q <= alloc_idx;
        req_q <= req;
    end

    t_mpf_vtp_port_wrapper_req orig_req;

    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_mpf_vtp_port_wrapper_req))
        )
      heap_data
       (
        .clk,
        .reset,

        .raddr(rspIdx),
        .rdata(orig_req),

        .wen(req_en_q),
        .waddr(alloc_idx_q),
        .wdata(req_q)
        );


    // ====================================================================
    //
    //  Send translation requests to the VTP service. Responses may be
    //  out of order. The unique alloc_idx tag will be used to associate
    //  requests and responses.
    //
    // ====================================================================

    assign vtp_port.reqEn = reqEn;
    assign vtp_port.req.tag = alloc_idx;
    assign vtp_port.req.pageVA = vtp4kbPageIdxFromVA(req.addr);
    assign vtp_port.req.isSpeculative = req.isSpeculative;
    assign vtp_port.reqAddrIsVirtual = req.addrIsVirtual;
    assign vtp_port.reqIsOrdered = req.isOrdered;

    // The ROB must have storage for all outstanding requests
    assign vtp_port.almostFullFromFIU = 1'b0;


    // ====================================================================
    //
    //  Responses
    //
    // ====================================================================

    t_mpf_vtp_lookup_rsp lookup_rsp;

    // Save response data in position associated with its ROB entry
    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_mpf_vtp_lookup_rsp))
        )
      heap_rsp
       (
        .clk,
        .reset,

        .raddr(rspIdx),
        .rdata(lookup_rsp),

        .wen(vtp_port.rspValid),
        .waddr(vtp_port.rsp.tag),
        .wdata(vtp_port.rsp)
        );


    assign rsp.error = lookup_rsp.error;

    assign rsp.isSpeculative = orig_req.isSpeculative;
    assign rsp.isOrdered = orig_req.isOrdered;

    // The address on response is virtual iff it was virtual on input
    // and translation failed.
    assign rsp.addrIsVirtual = orig_req.addrIsVirtual && lookup_rsp.error;

    always_comb
    begin
        if (! orig_req.addrIsVirtual)
        begin
            // The incoming address wasn't virtual. Keep the original address.
            rsp.addr = orig_req.addr;
        end
        else if (lookup_rsp.isBigPage)
        begin
            // 2MB page
            rsp.addr = t_vtp_clAddr'({ vtp4kbTo2mbPA(lookup_rsp.pagePA),
                                       vtp2mbPageOffsetFromVA(orig_req.addr) });
        end
        else
        begin
            // 4KB page
            rsp.addr = t_vtp_clAddr'({ lookup_rsp.pagePA,
                                       vtp4kbPageOffsetFromVA(orig_req.addr) });
        end
    end

endmodule // mpf_svc_vtp_port_wrapper_ordered
