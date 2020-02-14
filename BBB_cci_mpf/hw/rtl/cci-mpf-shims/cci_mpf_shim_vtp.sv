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
    parameter AFU_BUF_THRESHOLD = CCI_TX_ALMOST_FULL_THRESHOLD + 4
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

    logic reset = 1'b1;
    assign afu.reset = reset;
    always @(posedge clk)
    begin
        reset <= fiu.reset;
    end

    localparam DEBUG_MESSAGES = 0;

    // ====================================================================
    //
    //  Channel 0 (reads)
    //
    // ====================================================================

    logic c0chan_outValid;
    t_if_cci_mpf_c0_Tx c0chan_outTx;
    logic c0chan_outError;
    t_tlb_4kb_pa_page_idx c0chan_outPhysAddr;
    logic c0chan_outAddrIsBigPage;
    logic error_fifo_almostFull;

    assign afu.c0TxAlmFull = vtp_ports[0].almostFullToAFU;
    assign vtp_ports[0].cTxValid = cci_mpf_c0TxIsValid(afu.c0Tx);
    assign vtp_ports[0].cTx = afu.c0Tx;
    assign vtp_ports[0].cTxAddrIsVirtual = cci_mpf_c0_getReqAddrIsVirtual(afu.c0Tx.hdr);
    assign vtp_ports[0].cTxReqIsSpeculative = cci_mpf_c0TxIsSpecReadReq_noCheckValid(afu.c0Tx);
    assign vtp_ports[0].cTxReqIsOrdered = 1'b0;

    assign c0chan_outValid = vtp_ports[0].cTxValid_out;
    assign c0chan_outTx = vtp_ports[0].cTx_out;
    assign c0chan_outError = vtp_ports[0].cTxError_out;
    assign c0chan_outPhysAddr = vtp_ports[0].cTxPhysAddr_out;
    assign c0chan_outAddrIsBigPage = vtp_ports[0].cTxAddrIsBigPage_out;
    assign vtp_ports[0].almostFullFromFIU = fiu.c0TxAlmFull || error_fifo_almostFull;

    // Route translated requests to the FIU
    always_ff @(posedge clk)
    begin
        fiu.c0Tx <= cci_mpf_c0TxMaskValids(c0chan_outTx, c0chan_outValid && ! c0chan_outError);

        // Set the physical address. The page comes from the TLB and the
        // offset from the original memory request.
        fiu.c0Tx.hdr.ext.addrIsVirtual <= 1'b0;
        if (cci_mpf_c0_getReqAddrIsVirtual(c0chan_outTx.hdr))
        begin
            if (c0chan_outAddrIsBigPage)
            begin
                // 2MB page
                fiu.c0Tx.hdr.base.address <=
                    t_cci_clAddr'({ vtp4kbTo2mbPA(c0chan_outPhysAddr),
                                    vtp2mbPageOffsetFromVA(cci_mpf_c0_getReqAddr(c0chan_outTx.hdr)) });
            end
            else
            begin
                // 4KB page
                fiu.c0Tx.hdr.base.address <=
                    t_cci_clAddr'({ c0chan_outPhysAddr,
                                    vtp4kbPageOffsetFromVA(cci_mpf_c0_getReqAddr(c0chan_outTx.hdr)) });
            end

`ifdef CCIP_ENCODING_HAS_RDLSPEC
            // If the read request is speculative and the FIU doesn't support
            // speculation (e.g. no IOMMU) then make the request non-speculative.
            // At this point it has already passed VTP and a valid translation
            // was found.
            if (cci_mpf_c0TxIsSpecReadReq_noCheckValid(c0chan_outTx) &&
                ! (ccip_cfg_pkg::C0_REQ_RDLSPEC_S & ccip_cfg_pkg::C0_SUPPORTED_REQS))
            begin
                fiu.c0Tx.hdr.base.req_type[1] <= 1'b0;
            end
`endif
        end
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

        .enq_en(c0chan_outValid && c0chan_outError),
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
        afu.c0Rx <= fiu.c0Rx;

        if (c0_error_hdr_notEmpty && ! ccip_c0Rx_isValid(fiu.c0Rx))
        begin
            afu.c0Rx.rspValid <= 1'b1;
            afu.c0Rx.hdr <= c0_error_hdr;
            afu.c0Rx.hdr.cl_num <= c0_error_hdr_cl_num;
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
            if (c0chan_outValid && c0chan_outError)
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

    // Block order-sensitive requests until all previous translations are
    // complete so that they aren't reordered in the VTP channel pipeline.
    logic c1_order_sensitive;
    assign c1_order_sensitive = cci_mpf_c1TxIsWriteFenceReq(afu.c1Tx) ||
                                cci_mpf_c1TxIsInterruptReq(afu.c1Tx);

    logic c1chan_outValid;
    t_if_cci_mpf_c1_Tx c1chan_outTx;
    logic c1chan_outError;
    t_tlb_4kb_pa_page_idx c1chan_outPhysAddr;
    logic c1chan_outAddrIsBigPage;

    assign afu.c1TxAlmFull = vtp_ports[1].almostFullToAFU;
    assign vtp_ports[1].cTxValid = cci_mpf_c1TxIsValid(afu.c1Tx);
    assign vtp_ports[1].cTx = afu.c1Tx;
    assign vtp_ports[1].cTxAddrIsVirtual = cci_mpf_c1_getReqAddrIsVirtual(afu.c1Tx.hdr);
    assign vtp_ports[1].cTxReqIsSpeculative = 1'b0;
    assign vtp_ports[1].cTxReqIsOrdered = c1_order_sensitive;

    assign c1chan_outValid = vtp_ports[1].cTxValid_out;
    assign c1chan_outTx = vtp_ports[1].cTx_out;
    assign c1chan_outError = vtp_ports[1].cTxError_out;
    assign c1chan_outPhysAddr = vtp_ports[1].cTxPhysAddr_out;
    assign c1chan_outAddrIsBigPage = vtp_ports[1].cTxAddrIsBigPage_out;
    assign vtp_ports[1].almostFullFromFIU = fiu.c1TxAlmFull;

    // Route translated requests to the FIU
    always_ff @(posedge clk)
    begin
        fiu.c1Tx <= cci_mpf_c1TxMaskValids(c1chan_outTx, c1chan_outValid);

        // Set the physical address. The page comes from the TLB and the
        // offset from the original memory request.
        fiu.c1Tx.hdr.ext.addrIsVirtual <= 1'b0;
        if (cci_mpf_c1_getReqAddrIsVirtual(c1chan_outTx.hdr))
        begin
            if (c1chan_outAddrIsBigPage)
            begin
                // 2MB page
                fiu.c1Tx.hdr.base.address <=
                    t_cci_clAddr'({ vtp4kbTo2mbPA(c1chan_outPhysAddr),
                                    vtp2mbPageOffsetFromVA(cci_mpf_c1_getReqAddr(c1chan_outTx.hdr)) });
            end
            else
            begin
                // 4KB page
                fiu.c1Tx.hdr.base.address <=
                    t_cci_clAddr'({ c1chan_outPhysAddr,
                                    vtp4kbPageOffsetFromVA(cci_mpf_c1_getReqAddr(c1chan_outTx.hdr)) });
            end
        end
    end


    //
    // Responses
    //
    assign afu.c1Rx = fiu.c1Rx;


    //
    // Assertions
    //
    always_ff @(posedge clk)
    begin
        if (! reset)
        begin
            assert((c1chan_outValid == 1'b0) || (c1chan_outError == 1'b0)) else
                $fatal(2, "cci_mpf_shim_vtp.sv: Store channel should never raise a speculative translation error");
        end
    end


    // ====================================================================
    //
    //  MMIO (c2Tx)
    //
    // ====================================================================

    assign fiu.c2Tx = afu.c2Tx;

endmodule // cci_mpf_shim_vtp
