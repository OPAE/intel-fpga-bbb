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

`include "cci_mpf_if.vh"
`include "mpf_vtp.vh"

//
// Virtual to physical pipeline shim performs address translation in
// an AFU -> FIU stream by forwarding translation requests to the VTP
// service.
//

module cci_mpf_shim_vtp
  #(
    parameter AFU_BUF_THRESHOLD = CCI_TX_ALMOST_FULL_THRESHOLD + 4,
    parameter VTP_HALT_ON_FAILURE = 1
    )
   (
    input  logic clk,

    // Connection toward the QA platform.  Reset comes in here.
    cci_mpf_if.to_fiu fiu,

    // Connections toward user code.
    cci_mpf_if.to_afu afu,

    // VTP service translation ports - one for each channel
    mpf_vtp_port_if.to_slave vtp_ports[2]
    );

    localparam DEBUG_MESSAGES = 0;

    // ====================================================================
    //
    //  Instantiate a buffer on the AFU request ports, needed to honor
    //  the translation pipeline flow control.
    //
    // ====================================================================

    cci_mpf_if afu_buf (.clk);

    logic deqC0Tx;
    logic deqC1Tx;

    cci_mpf_shim_buffer_afu
      #(
        .ENABLE_C0_BYPASS(1)
        )
      b
        (
         .clk,
         .afu_raw(afu),
         .afu_buf(afu_buf),
         .deqC0Tx(deqC0Tx),
         .deqC1Tx(deqC1Tx)
         );

    //
    // Almost full signals in the buffered input are ignored --
    // replaced by deq signals and the buffer state.  Set them
    // to 1 to be sure they are ignored.
    //
    assign afu_buf.c0TxAlmFull = 1'b1;
    assign afu_buf.c1TxAlmFull = 1'b1;

    logic reset = 1'b1;
    assign afu_buf.reset = reset;
    always @(posedge clk)
    begin
        reset <= fiu.reset;
    end


    // ====================================================================
    //
    //  Channel 0 (reads)
    //
    // ====================================================================

    t_mpf_vtp_port_wrapper_req c0chan_req;
    t_mpf_vtp_port_wrapper_rsp c0chan_rsp;

    logic c0chan_notFull;
    logic c0chan_outValid;
    t_if_cci_mpf_c0_Tx c0chan_outTx;
    logic error_fifo_almostFull;
    logic c0chan_deq_en;
    t_mpf_vtp_req_tag c0chan_reqIdx;
    t_mpf_vtp_req_tag c0chan_rspIdx;

    assign deqC0Tx = cci_mpf_c0TxIsValid(afu_buf.c0Tx) && c0chan_notFull;

    always_comb
    begin
        c0chan_req = '0;
        c0chan_req.addr = cci_mpf_c0_getReqAddr(afu_buf.c0Tx.hdr);
        c0chan_req.addrIsVirtual = cci_mpf_c0_getReqAddrIsVirtual(afu_buf.c0Tx.hdr);
        c0chan_req.isSpeculative = cci_mpf_c0TxIsSpecReadReq_noCheckValid(afu_buf.c0Tx) ||
                                   (VTP_HALT_ON_FAILURE == 0);
    end

    mpf_svc_vtp_port_wrapper_unordered
      tr_c0
       (
        .clk,
        .reset,

        .vtp_port(vtp_ports[0]),
        .reqEn(deqC0Tx),
        .req(c0chan_req),
        .notFull(c0chan_notFull),
        .reqIdx(c0chan_reqIdx),

        .rspValid(c0chan_outValid),
        .rsp(c0chan_rsp),
        .rspDeqEn(c0chan_deq_en),
        .rspIdx(c0chan_rspIdx)
        );

    // Hold the full c0Tx request during lookup. The VTP port wrapper provides
    // up to MPF_VTP_MAX_SVC_REQS indices.
    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_if_cci_mpf_c0_Tx))
        )
      tr_c0_meta
       (
        .clk,
        .reset,

        .raddr(c0chan_rspIdx),
        .rdata(c0chan_outTx),

        .wen(deqC0Tx),
        .waddr(c0chan_reqIdx),
        .wdata(afu_buf.c0Tx)
        );

    assign c0chan_deq_en = c0chan_outValid && !fiu.c0TxAlmFull && !error_fifo_almostFull;

    // Is the response an explicitly speculative load (e.g. a prefetch)?
    logic c0chan_rsp_is_speculative;
    assign c0chan_rsp_is_speculative = cci_mpf_c0TxIsSpecReadReq_noCheckValid(c0chan_outTx);

    // Raise an error if translation fails and the AFU has no error handler
    // or the request is explicitly speculative.
    logic c0chan_raise_error;
    assign c0chan_raise_error = c0chan_rsp.error &&
                                (c0chan_rsp_is_speculative || (VTP_HALT_ON_FAILURE != 0));

    // Route translated requests to the FIU
    always_ff @(posedge clk)
    begin
        fiu.c0Tx <= cci_mpf_c0TxMaskValids(c0chan_outTx,
                                           c0chan_deq_en && ! c0chan_raise_error);

        // Set the address to the translated result. The address might
        // still be virtual if translation failed.
        fiu.c0Tx.hdr.ext.addrIsVirtual <= c0chan_rsp.addrIsVirtual;
        fiu.c0Tx.hdr.base.address <= c0chan_rsp.addr;

`ifdef CCIP_ENCODING_HAS_RDLSPEC
        // If the read request is speculative and the FIU doesn't support
        // speculation (e.g. no IOMMU) then make the request non-speculative.
        // At this point it has already passed VTP and a valid translation
        // was found.
        if (cci_mpf_c0TxIsSpecReadReq_noCheckValid(c0chan_outTx) &&
            cci_mpf_c0_getReqAddrIsVirtual(c0chan_outTx.hdr) &&
            ! (ccip_cfg_pkg::C0_REQ_RDLSPEC_S & ccip_cfg_pkg::C0_SUPPORTED_REQS))
        begin
            fiu.c0Tx.hdr.base.req_type[1] <= 1'b0;
        end
`endif
    end


    //
    // Responses
    //

    // There are two sources of read responses: the normal path from the FIU and the
    // error path from failed translations of speculative loads. The FIFO holds
    // speculative failures and will be used to generate read error responses on
    // cycles when there is no FIU response.

    t_cci_c0_RspMemHdr c0_error_hdr_in, c0_error_hdr;
    logic c0_deq_error_hdr;
    logic c0_error_hdr_notEmpty;
    t_cci_clNum c0_error_hdr_cl_num;
    logic c0_error_last_cl;

    always_comb
    begin
        c0_error_hdr_in = cci_c0_genRspHdr(eRSP_RDLINE, c0chan_outTx.hdr.base.mdata);
        // Store the number of responses (lines) needed in the cl_len field.
        c0_error_hdr_in.cl_num = t_cci_clLen'(c0chan_outTx.hdr.base.cl_len);

        c0_error_hdr_in = cci_mpf_c0Rx_updEOP(c0_error_hdr_in, c0_error_last_cl);

        // Signal the translation error
`ifdef CCIP_ENCODING_HAS_RDLSPEC
        c0_error_hdr_in.error = 1'b1;
`endif
    end

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_cci_c0_RspMemHdr)),
        .N_ENTRIES(8),
        .THRESHOLD(4),
        .REGISTER_OUTPUT(1)
        )
      error_fifo
       (
        .clk,
        .reset(reset),

        .enq_en(c0chan_deq_en && c0chan_raise_error && c0chan_rsp_is_speculative),
        .enq_data(c0_error_hdr_in),
        .notFull(),
        .almostFull(error_fifo_almostFull),

        .first(c0_error_hdr),
        .deq_en(c0_deq_error_hdr),
        .notEmpty(c0_error_hdr_notEmpty)
        );


    // Track cl_num for multi-line speculative error responses
    always_ff @(posedge clk)
    begin
        if (reset || c0_deq_error_hdr)
        begin
            c0_error_hdr_cl_num <= t_cci_clNum'(0);
        end
        else if (c0_error_hdr_notEmpty && ! ccip_c0Rx_isValid(fiu.c0Rx))
        begin
            // Error response generated this cycle
            c0_error_hdr_cl_num <= c0_error_hdr_cl_num + t_cci_clNum'(1);
        end
    end

    // The standard c0 response path just forwards messages from the FIU.
    // When a speculation error is needed it will be injected in cycles
    // that aren't already occupied by FIU messages.
    always_ff @(posedge clk)
    begin
        afu_buf.c0Rx <= fiu.c0Rx;

        if (c0_error_hdr_notEmpty && ! ccip_c0Rx_isValid(fiu.c0Rx))
        begin
            afu_buf.c0Rx.rspValid <= 1'b1;
            afu_buf.c0Rx.hdr <= c0_error_hdr;
            afu_buf.c0Rx.hdr.cl_num <= c0_error_hdr_cl_num;
        end
    end

    // Done with the speculation error when responses are generated
    // for all lines.
    assign c0_error_last_cl = (c0_error_hdr_cl_num == c0_error_hdr.cl_num);
    assign c0_deq_error_hdr = c0_error_hdr_notEmpty && ! ccip_c0Rx_isValid(fiu.c0Rx) &&
                              c0_error_last_cl;


    //
    // Debugging
    //
    always_ff @(posedge clk)
    begin
        if (DEBUG_MESSAGES && ! reset)
        begin
            if (c0chan_deq_en && c0chan_rsp.error)
            begin
                $display("%m VTP: %0t Speculative load translation error from VA 0x%x",
                         $time,
                         {cci_mpf_c0_getReqAddr(c0chan_outTx.hdr), 6'b0});
            end
        end
    end


    // ====================================================================
    //
    //  Channel 1 (writes)
    //
    // ====================================================================

    t_mpf_vtp_port_wrapper_req c1chan_req;
    t_mpf_vtp_port_wrapper_rsp c1chan_rsp;

    logic c1chan_notFull;
    logic c1chan_outValid;
    t_if_cci_mpf_c1_Tx c1chan_outTx;
    logic c1chan_deq_en;
    t_mpf_vtp_req_tag c1chan_reqIdx;
    t_mpf_vtp_req_tag c1chan_rspIdx;

    assign deqC1Tx = cci_mpf_c1TxIsValid(afu_buf.c1Tx) && c1chan_notFull;

    always_comb
    begin
        c1chan_req = '0;
        c1chan_req.addr = cci_mpf_c1_getReqAddr(afu_buf.c1Tx.hdr);
        c1chan_req.addrIsVirtual = cci_mpf_c1_getReqAddrIsVirtual(afu_buf.c1Tx.hdr);
        c1chan_req.isSpeculative = (VTP_HALT_ON_FAILURE == 0);

        // Block order-sensitive requests until all previous translations are
        // complete so that they aren't reordered in the VTP channel pipeline.
        c1chan_req.isOrdered = cci_mpf_c1TxIsWriteFenceReq(afu_buf.c1Tx) ||
                               cci_mpf_c1TxIsInterruptReq(afu_buf.c1Tx);
    end

    mpf_svc_vtp_port_wrapper_unordered
      tr_c1
       (
        .clk,
        .reset,

        .vtp_port(vtp_ports[1]),
        .reqEn(deqC1Tx),
        .req(c1chan_req),
        .notFull(c1chan_notFull),
        .reqIdx(c1chan_reqIdx),

        .rspValid(c1chan_outValid),
        .rsp(c1chan_rsp),
        .rspDeqEn(c1chan_deq_en),
        .rspIdx(c1chan_rspIdx)
        );

    // Hold the full c1Tx request during lookup. The VTP port wrapper provides
    // up to MPF_VTP_MAX_SVC_REQS indices.
    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(MPF_VTP_MAX_SVC_REQS),
        .N_DATA_BITS($bits(t_if_cci_mpf_c1_Tx))
        )
      tr_c1_meta
       (
        .clk,
        .reset,

        .raddr(c1chan_rspIdx),
        .rdata(c1chan_outTx),

        .wen(deqC1Tx),
        .waddr(c1chan_reqIdx),
        .wdata(afu_buf.c1Tx)
        );

    assign c1chan_deq_en = c1chan_outValid && !fiu.c1TxAlmFull;

    // Raise an error if translation fails and the AFU has no error handler.
    logic c1chan_raise_error;
    assign c1chan_raise_error = c1chan_rsp.error && (VTP_HALT_ON_FAILURE != 0);

    // Route translated requests to the FIU
    always_ff @(posedge clk)
    begin
        fiu.c1Tx <= cci_mpf_c1TxMaskValids(c1chan_outTx,
                                           c1chan_deq_en && ! c1chan_raise_error);

        // Set the address to the translated result. The address might
        // still be virtual if translation failed.
        fiu.c1Tx.hdr.ext.addrIsVirtual <= c1chan_rsp.addrIsVirtual;
        fiu.c1Tx.hdr.base.address <= c1chan_rsp.addr;
    end


    //
    // Responses
    //
    assign afu_buf.c1Rx = fiu.c1Rx;


    //
    // Assertions
    //

    // synthesis translate_off
    always_ff @(negedge clk)
    begin
        if (! reset)
        begin
            assert((c1chan_outValid == 1'b0) || ! c1chan_raise_error) else
                $fatal(2, "** ERROR ** %m: Store channel should never raise a speculative translation error");
        end
    end
    // synthesis translate_on


    // ====================================================================
    //
    //  MMIO (c2Tx)
    //
    // ====================================================================

    assign fiu.c2Tx = afu_buf.c2Tx;

endmodule // cci_mpf_shim_vtp
