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
`include "cci_mpf_shim_vtp.vh"

`include "cci_mpf_config.vh"

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
    cci_mpf_shim_vtp_svc_if.client vtp_svc[0 : 1],

    // CSRs
    cci_mpf_csrs.vtp csrs
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

    // Pass TX requests through a translation pipeline
    cci_mpf_shim_vtp_chan_lookup
      #(
        .THRESHOLD(AFU_BUF_THRESHOLD),
        .CTX_NUMBER(0),
        .N_CTX_BITS($bits(t_if_cci_mpf_c0_Tx)),
        .N_LOCAL_4KB_CACHE_ENTRIES(`VTP_N_C0_L1_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(`VTP_N_C0_L1_2MB_CACHE_ENTRIES)
        )
      c0_vtp
       (
        .clk,
        .reset,

        .almostFullToAFU(afu.c0TxAlmFull),
        .cTxValid(cci_mpf_c0TxIsValid(afu.c0Tx)),
        .cTx(afu.c0Tx),
        .cTxAddrIsVirtual(cci_mpf_c0_getReqAddrIsVirtual(afu.c0Tx.hdr)),
        .cTxReqIsSpeculative(cci_mpf_c0TxIsSpecReadReq_noCheckValid(afu.c0Tx)),
        .cTxReqIsOrdered(1'b0),

        .cTxValid_out(c0chan_outValid),
        .cTx_out(c0chan_outTx),
        .cTxError_out(c0chan_outError),
        .cTxPhysAddr_out(c0chan_outPhysAddr),
        .cTxAddrIsBigPage_out(c0chan_outAddrIsBigPage),
        .almostFullFromFIU(fiu.c0TxAlmFull || error_fifo_almostFull),

        .vtp_svc(vtp_svc[0]),
        .csrs
        );

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

`ifdef CCIP_RDLSPEC_AVAIL
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
`ifdef CCIP_RDLSPEC_AVAIL
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

    // Pass TX requests through a translation pipeline
    cci_mpf_shim_vtp_chan_lookup
      #(
        .THRESHOLD(AFU_BUF_THRESHOLD),
        .CTX_NUMBER(1),
        .N_CTX_BITS($bits(t_if_cci_mpf_c1_Tx)),
        .N_LOCAL_4KB_CACHE_ENTRIES(`VTP_N_C1_L1_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(`VTP_N_C1_L1_2MB_CACHE_ENTRIES),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      c1_vtp
       (
        .clk,
        .reset,

        .almostFullToAFU(afu.c1TxAlmFull),
        .cTxValid(cci_mpf_c1TxIsValid(afu.c1Tx)),
        .cTx(afu.c1Tx),
        .cTxAddrIsVirtual(cci_mpf_c1_getReqAddrIsVirtual(afu.c1Tx.hdr)),
        .cTxReqIsSpeculative(1'b0),
        .cTxReqIsOrdered(c1_order_sensitive),

        .cTxValid_out(c1chan_outValid),
        .cTx_out(c1chan_outTx),
        .cTxError_out(c1chan_outError),
        .cTxPhysAddr_out(c1chan_outPhysAddr),
        .cTxAddrIsBigPage_out(c1chan_outAddrIsBigPage),
        .almostFullFromFIU(fiu.c1TxAlmFull),

        .vtp_svc(vtp_svc[1]),
        .csrs
        );

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


//
// This macro instantiates a function named get_4kb_va_page_idx within pipelines
// below. It allows a single module implementations to handle either c0 (load)
// or c1 (store) pipelines. Weak SystemVerilog macros make this mess necessary.
//
`define CCI_MPF_VTP_CHAN_PAGE_IDX_FUNC \
    function automatic t_tlb_4kb_va_page_idx get_4kb_va_page_idx(logic [N_CTX_BITS-1 : 0] cTx); \
        t_cci_clAddr addr; \
        if (CTX_NUMBER == 0) \
        begin \
            // Cast to c0 and get the address \
            t_if_cci_mpf_c0_Tx c0Tx = t_if_cci_mpf_c0_Tx'(cTx); \
            addr = cci_mpf_c0_getReqAddr(c0Tx.hdr); \
        end \
        else \
        begin \
            // Cast to c1 and get the address \
            t_if_cci_mpf_c1_Tx c1Tx = t_if_cci_mpf_c1_Tx'(cTx); \
            addr = cci_mpf_c1_getReqAddr(c1Tx.hdr); \
        end \
        return vtp4kbPageIdxFromVA(addr); \
    endfunction // get_4kb_va_page_idx


//
// TLB lookup for a single channel. The code is independent of the request
// channel data structures so many be instantiated for either.
//
module cci_mpf_shim_vtp_chan_lookup
  #(
    parameter THRESHOLD = CCI_TX_ALMOST_FULL_THRESHOLD,
    parameter CTX_NUMBER = 0,
    parameter N_CTX_BITS = 0,
    parameter N_LOCAL_4KB_CACHE_ENTRIES = 512,
    parameter N_LOCAL_2MB_CACHE_ENTRIES = 512,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    output logic almostFullToAFU,
    // A single TX channel.
    input  logic cTxValid,
    input  logic [N_CTX_BITS-1 : 0] cTx,
    input  logic cTxAddrIsVirtual,
    // Is the request a speculative translation?
    input  logic cTxReqIsSpeculative,
    // Is the request ordered (e.g. a write fence)? If so, the channel logic
    // will wait for all earlier requests to drain from the VTP pipelines.
    // It is illegal to set both cTxAddrIsVirtual and cTxReqIsOrdered.
    input  logic cTxReqIsOrdered,

    // Outbound TX channel. Requests are present when cTxValid_out is set.
    output logic cTxValid_out,
    // Unchanged from the value passed to cTx above.
    output logic [N_CTX_BITS-1 : 0] cTx_out,
    // Failed translation. This error may be raised only if cTxReqIsSpeculative
    // was set.
    output logic cTxError_out,
    // A translated physical address if cTxAddr is virtual.
    output t_tlb_4kb_pa_page_idx cTxPhysAddr_out,
    output logic cTxAddrIsBigPage_out,
    input  logic almostFullFromFIU,

    // Translation service connection
    cci_mpf_shim_vtp_svc_if.client vtp_svc,

    // CSRs
    cci_mpf_csrs.vtp csrs
    );

    // Register incoming almost full for timing. The FIFOs below respond quickly
    // enough despite the delay.
    logic almostFullFromFIU_q;
    always_ff @(posedge clk)
    begin
        almostFullFromFIU_q <= almostFullFromFIU;
    end

    // L1 lookup result wires
    logic l1_fifo_deq;
    logic l1_fifo_notEmpty;
    logic [N_CTX_BITS-1 : 0] l1_cTx_out;
    logic l1_cTxReqIsSpeculative_out;
    logic l1_cTxReqIsOrdered_out;
    logic l1_cTxAddrIsVirtual_out;
    logic l1_cTxAddrTranslationValid_out;
    t_tlb_4kb_pa_page_idx l1_cTxPhysAddr_out;
    logic l1_cTxAddrIsBigPage_out;

    // L1 insertion request wires
    t_tlb_4kb_va_page_idx insertVA;
    t_tlb_4kb_pa_page_idx insertPA;
    logic en_insert_4kb;
    logic en_insert_2mb;

    // Forward a successful L1 lookup to the FIU?
    logic l1_fwd_to_fiu;
    // Forward an unsuccessful L1 lookup to the L2 pipeline?
    logic l1_fwd_to_l2;

    //
    // Lookup in local L1 TLB. There is an internal FIFO, so requests
    // sit inside the module until explicitly dequeued.
    //
    cci_mpf_shim_vtp_chan_l1_lookup
      #(
        .THRESHOLD(THRESHOLD),
        .CTX_NUMBER(CTX_NUMBER),
        // Extra bits in the payload hold cTxReq flags
        .N_CTX_BITS(N_CTX_BITS + 2),
        .N_LOCAL_4KB_CACHE_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      l1tlb
       (
        .clk,
        .reset,

        .almostFull(almostFullToAFU),
        .cTxValid,
        .cTx({ cTxReqIsSpeculative, cTxReqIsOrdered, cTx }),
        .cTxAddrIsVirtual,

        .notEmpty(l1_fifo_notEmpty),
        // cTx must be the low bits of cTx_out so that get_4kb_va_page_idx() works.
        .cTx_out({ l1_cTxReqIsSpeculative_out, l1_cTxReqIsOrdered_out, l1_cTx_out }),
        .cTxAddrIsVirtual_out(l1_cTxAddrIsVirtual_out),
        .cTxAddrTranslationValid_out(l1_cTxAddrTranslationValid_out),
        .cTxPhysAddr_out(l1_cTxPhysAddr_out),
        .cTxAddrIsBigPage_out(l1_cTxAddrIsBigPage_out),
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

    logic l2_cTxValid_out;
    logic [N_CTX_BITS-1 : 0] l2_cTx_out;
    logic l2_cTxError_out;
    t_tlb_4kb_pa_page_idx l2_cTxPhysAddr_out;
    logic l2_cTxAddrIsBigPage_out;

    cci_mpf_shim_vtp_chan_l2_lookup
      #(
        .CTX_NUMBER(CTX_NUMBER),
        .N_CTX_BITS(N_CTX_BITS),
        .N_LOCAL_4KB_CACHE_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      l2tlb
       (
        .clk,
        .reset,

        .notFull(l2_notFull),
        .notEmpty(l2_notEmpty),

        // Send to L2 when L1 translation fails
        .cTxValid(l1_fwd_to_l2),
        .cTx(l1_cTx_out),
        .cTxReqIsSpeculative(l1_cTxReqIsSpeculative_out),

        .cTxValid_out(l2_cTxValid_out),
        .cTx_out(l2_cTx_out),
        .cTxError_out(l2_cTxError_out),
        .cTxPhysAddr_out(l2_cTxPhysAddr_out),
        .cTxAddrIsBigPage_out(l2_cTxAddrIsBigPage_out),
        .cTxAlmostFull(almostFullFromFIU_q),

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
        l1_fwd_to_fiu = 1'b0;
        l1_fwd_to_l2 = 1'b0;

        // Forward L1 lookup output? In addition to having valid data,
        // we must block if the request is ordered (e.g. a fence) and
        // other requests are still flowing through the VTP L2.
        if (l1_fifo_notEmpty && ! (l1_cTxReqIsOrdered_out && l2_notEmpty) && ! reset)
        begin
            // No L1 translation needed or translation is valid?
            if (! l1_cTxAddrIsVirtual_out || l1_cTxAddrTranslationValid_out)
            begin
                // Yes: forward directly to FIU unless there is conflicting
                // output from the L2 pipeline.
                l1_fwd_to_fiu = ! almostFullFromFIU_q && ! l2_cTxValid_out;
            end
            else
            begin
                // L2 lookup needed.
                l1_fwd_to_l2 = l2_notFull;
            end
        end

        l1_fifo_deq = l1_fwd_to_fiu || l1_fwd_to_l2;
    end

    //
    // Merge L1 and L2 pipeline toward FIU.
    //
    always_ff @(posedge clk)
    begin
        cTxValid_out <= l1_fwd_to_fiu || l2_cTxValid_out;

        if (l1_fwd_to_fiu)
        begin
            cTx_out <= l1_cTx_out;
            cTxError_out <= 1'b0;
            cTxPhysAddr_out <= l1_cTxPhysAddr_out;
            cTxAddrIsBigPage_out <= l1_cTxAddrIsBigPage_out;
        end
        else
        begin
            cTx_out <= l2_cTx_out;
            cTxError_out <= l2_cTxError_out;
            cTxPhysAddr_out <= l2_cTxPhysAddr_out;
            cTxAddrIsBigPage_out <= l2_cTxAddrIsBigPage_out;
        end

        if (reset)
        begin
            cTxValid_out <= 1'b0;
        end
    end

endmodule // cci_mpf_shim_vtp_chan_lookup


//
// L1 TLB lookup for a single channel.
//
// A simple direct mapped cache is maintained as a first level TLB.
// The L1 TLB here filters translation requests in order to relieve
// pressure on the shared VTP TLB service.
//
module cci_mpf_shim_vtp_chan_l1_lookup
  #(
    parameter THRESHOLD = CCI_TX_ALMOST_FULL_THRESHOLD,
    parameter CTX_NUMBER = 0,
    parameter N_CTX_BITS = 0,
    parameter N_LOCAL_4KB_CACHE_ENTRIES = 512,
    parameter N_LOCAL_2MB_CACHE_ENTRIES = 512,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // A single TX channel. The request in cTx is just buffered here along
    // with any address translation, which is derived from cTxAddr.
    output logic almostFull,
    input  logic cTxValid,
    input  logic [N_CTX_BITS-1 : 0] cTx,
    input  logic cTxAddrIsVirtual,

    // Outbound TX channel. Requests are buffered internally by a FIFO and
    // must be dequeud explicitly with "deq".
    output logic notEmpty,
    // Unchanged from the value passed to cTx above.
    output logic [N_CTX_BITS-1 : 0] cTx_out,
    output logic cTxAddrIsVirtual_out,
    // Is the translated address valid? If not then the L2 TLB will have to
    // be queried.
    output logic cTxAddrTranslationValid_out,
    // A translated physical address when cTxAddrTranslationValid_out is set.
    output t_tlb_4kb_pa_page_idx cTxPhysAddr_out,
    output logic cTxAddrIsBigPage_out,
    input  logic deq,

    // Insert translation into L1 cache.  Like lookupVA, these addresses are
    // transformed internally for page sizes larger than 4KB.
    input  t_tlb_4kb_va_page_idx insertVA,
    input  t_tlb_4kb_pa_page_idx insertPA,
    input  en_insert_4kb,
    input  en_insert_2mb,

    // CSRs
    cci_mpf_csrs.vtp csrs
    );

    // Instantiate a function that can parse cTx as the proper type. The macro
    // is defined above.
    `CCI_MPF_VTP_CHAN_PAGE_IDX_FUNC

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
        logic cTxValid;
        logic [N_CTX_BITS-1 : 0] cTx;
        logic cTxAddrIsVirtual;
    }
    t_vtp_shim_chan_l1_state;

    localparam MAX_STAGE = 3;
    t_vtp_shim_chan_l1_state state[0 : MAX_STAGE];

    always_comb
    begin
        state[0].cTxValid = cTxValid && ! reset;
        state[0].cTx = cTx;
        state[0].cTxAddrIsVirtual = cTxAddrIsVirtual;
    end

    genvar s;
    generate
        for (s = 1; s <= MAX_STAGE; s = s + 1)
        begin : st
            always_ff @(posedge clk)
            begin
                state[s].cTxValid <= state[s - 1].cTxValid;
                state[s].cTx <= state[s - 1].cTx;
                state[s].cTxAddrIsVirtual <= state[s - 1].cTxAddrIsVirtual;

                if (reset)
                begin
                    state[s].cTxValid <= 1'b0;
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

    typedef struct packed
    {
        logic hit;
        t_tlb_4kb_pa_page_idx pa;
        logic isBigPage;
    }
    t_vtp_shim_l1_result;

    t_vtp_shim_l1_result l1_result;

    cci_mpf_shim_vtp_chan_l1_caches
      #(
        .N_LOCAL_4KB_CACHE_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_LOCAL_2MB_CACHE_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      l1_caches
       (
        .clk,
        .reset,

        .lookupVA(get_4kb_va_page_idx(state[0].cTx)),
        .T3_hit_4kb(l1_hit_4kb),
        .T3_hit_2mb(l1_hit_2mb),
        .T3_hit(l1_result.hit),
        .T3_hitPA(l1_result.pa),

        .insertVA,
        .insertPA,
        .en_insert_4kb,
        .en_insert_2mb,

        .csrs
        );

    assign l1_result.isBigPage = l1_hit_2mb;


    // ====================================================================
    //
    //  Store request and translation in a FIFO.
    //
    // ====================================================================

    // Almost full has to account for requests in flight in the local pipeline.
    localparam FIFO_THRESHOLD = THRESHOLD + MAX_STAGE;

    t_vtp_shim_chan_l1_state fifo_state_out;
    t_vtp_shim_l1_result l1_result_out;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_vtp_shim_chan_l1_state) + $bits(t_vtp_shim_l1_result)),
        .N_ENTRIES(FIFO_THRESHOLD + 4),
        .THRESHOLD(FIFO_THRESHOLD),
        .REGISTER_OUTPUT(1),
        // Bypass to save a cycle on c0 (reads), don't bother for writes.
        .BYPASS_TO_REGISTER((CTX_NUMBER == 0) ? 1 : 0)
        )
      fifo
       (
        .clk,
        .reset(reset),

        .enq_en(state[MAX_STAGE].cTxValid),
        .enq_data({ state[MAX_STAGE], l1_result }),
        .notFull(),
        .almostFull(almostFull),

        .first({ fifo_state_out, l1_result_out }),
        .deq_en(deq),
        .notEmpty(notEmpty)
        );

    always_comb
    begin
        cTx_out = fifo_state_out.cTx;
        cTxAddrIsVirtual_out = fifo_state_out.cTxAddrIsVirtual;
        cTxAddrTranslationValid_out = l1_result_out.hit;
        cTxPhysAddr_out = l1_result_out.pa;
        cTxAddrIsBigPage_out = l1_result_out.isBigPage;
    end

endmodule // cci_mpf_shim_vtp_chan_l1_lookup


//
// This module defines a path taken only by requests that miss in the L1 TLB.
//
module cci_mpf_shim_vtp_chan_l2_lookup
  #(
    parameter CTX_NUMBER = 0,
    parameter N_CTX_BITS = 0,
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
    input  logic cTxValid,
    input  logic [N_CTX_BITS-1 : 0] cTx,
    input  logic cTxReqIsSpeculative,

    // Outbound TX channel containing translated requests. The only flow
    // control here is cTxAlmostFull. The parent is expected to handle
    // requests any time cTxValid_out is set.
    output logic cTxValid_out,
    output logic [N_CTX_BITS-1 : 0] cTx_out,
    output t_tlb_4kb_pa_page_idx cTxPhysAddr_out,
    output logic cTxError_out,
    output logic cTxAddrIsBigPage_out,
    input  logic cTxAlmostFull,

    // Send commands to the L1 cache to add a translation.
    output t_tlb_4kb_va_page_idx insertVA,
    output t_tlb_4kb_pa_page_idx insertPA,
    output logic en_insert_4kb,
    output logic en_insert_2mb,

    // Translation service connection
    cci_mpf_shim_vtp_svc_if.client vtp_svc,

    // CSRs
    cci_mpf_csrs.vtp csrs
    );

    // Instantiate a function that can parse cTx as the proper type. The macro
    // is defined above.
    `CCI_MPF_VTP_CHAN_PAGE_IDX_FUNC

    // ====================================================================
    //
    //  Heap for holding TX state
    //
    // ====================================================================

    t_cci_mpf_shim_vtp_req_tag allocIdx;
    t_cci_mpf_shim_vtp_req_tag freeIdx;
    logic heap_notFull;

    logic lookup_rdy;
    assign notFull = heap_notFull && lookup_rdy;

    always_ff @(posedge clk)
    begin
        lookup_rdy <= vtp_svc.lookupRdy && csrs.vtp_in_mode.enabled;
    end

    // Heap index manager
    cci_mpf_prim_heap_ctrl
      #(
        .N_ENTRIES(CCI_MPF_SHIM_VTP_MAX_SVC_REQS)
        )
      heap_ctrl
       (
        .clk,
        .reset,

        .enq(cTxValid),
        .notFull(heap_notFull),
        .allocIdx,

        .free(cTxValid_out),
        .freeIdx
        );


    // Heap data is written in cycle 1. It is available in cycle 0 but
    // not needed yet, so waiting a cycle simplifies timing.
    t_cci_mpf_shim_vtp_req_tag allocIdx_q;
    logic cTxValid_q;
    logic [N_CTX_BITS-1 : 0] cTx_q;
    logic cTxReqIsSpeculative_q;

    always_ff @(posedge clk)
    begin
        allocIdx_q <= allocIdx;
        cTxValid_q <= cTxValid;
        cTx_q <= cTx;
        cTxReqIsSpeculative_q <= cTxReqIsSpeculative;
    end

    t_cci_mpf_shim_vtp_req_tag readIdx;
    logic [N_CTX_BITS-1 : 0] read_cTx_out;
    logic cur_req_epoch;
    logic read_epoch_out;

    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(CCI_MPF_SHIM_VTP_MAX_SVC_REQS),
        .N_DATA_BITS(N_CTX_BITS + 1)
        )
      heap_ctx
       (
        .clk,
        .reset,

        .raddr(readIdx),
        .rdata({ read_epoch_out, read_cTx_out }),

        .waddr(allocIdx_q),
        .wen(cTxValid_q),
        .wdata({ cur_req_epoch, cTx_q })
        );

    always_ff @(posedge clk)
    begin
        freeIdx <= readIdx;
    end


    // ====================================================================
    //
    //  Send translation requests to VTP server
    //
    // ====================================================================

    logic allow_fills;

    // Request TLB lookup
    always_ff @(posedge clk)
    begin
        vtp_svc.lookupEn <= cTxValid_q;
        vtp_svc.lookupReq.pageVA <= get_4kb_va_page_idx(cTx_q);
        vtp_svc.lookupReq.isSpeculative <= cTxReqIsSpeculative_q;
        vtp_svc.lookupReq.tag <= allocIdx_q;

        vtp_svc.invalComplete <= allow_fills;

        if (reset)
        begin
            vtp_svc.lookupEn <= 1'b0;
        end
    end

    //
    // TLB response timing is latency insensitive.  This FIFO collects
    // responses until they can be merged into the pipeline.
    //
    t_cci_mpf_shim_vtp_lookup_rsp tlb_lookup_rsp;
    t_cci_mpf_shim_vtp_lookup_rsp tlb_lookup_rsp_q;
    logic tlb_lookup_rsp_rdy;
    logic tlb_lookup_deq;
    logic tlb_lookup_deq_q;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_cci_mpf_shim_vtp_lookup_rsp)),
        .N_ENTRIES(CCI_MPF_SHIM_VTP_MAX_SVC_REQS)
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

    assign tlb_lookup_deq = tlb_lookup_rsp_rdy && ! cTxAlmostFull;

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

    // Read the full request from the heap
    always_ff @(posedge clk)
    begin
        readIdx <= tlb_lookup_rsp.tag;
    end

    always_ff @(posedge clk)
    begin
        cTxValid_out <= tlb_lookup_deq_q;
        cTxPhysAddr_out <= tlb_lookup_rsp_q.pagePA;
        cTxError_out <= tlb_lookup_rsp_q.error;
        cTxAddrIsBigPage_out <= tlb_lookup_rsp_q.isBigPage;
        cTx_out <= read_cTx_out;

        if (reset)
        begin
            cTxValid_out <= 1'b0;
        end
    end

    //
    // Set values for updating the local L1 cache.
    //
    logic en_insert;
    assign en_insert = tlb_lookup_deq_q && allow_fills && ! tlb_lookup_rsp_q.error;

    always_ff @(posedge clk)
    begin
        en_insert_4kb <= en_insert && ! tlb_lookup_rsp_q.isBigPage;
        en_insert_2mb <= en_insert && tlb_lookup_rsp_q.isBigPage;

        insertVA <= get_4kb_va_page_idx(read_cTx_out);
        insertPA <= tlb_lookup_rsp_q.pagePA;
    end


    // ====================================================================
    //
    //  Track notEmpty by counting transactions
    //
    // ====================================================================

    logic [$clog2(CCI_MPF_SHIM_VTP_MAX_SVC_REQS+1)-1 : 0] n_active;
    logic [$clog2(CCI_MPF_SHIM_VTP_MAX_SVC_REQS+1)-1 : 0] n_active_next;

    always_comb
    begin
        if ((cTxValid ^ cTxValid_out) == 1'b0)
        begin
            // No change
            n_active_next = n_active;
        end
        else if (cTxValid)
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


    // ====================================================================
    //
    //  Track invalidation epoch. When software invalidates a translation
    //  entry, this logic tracks the number of outstanding L2 requests
    //  that were generated before the invalidation. Since L2 responses
    //  may sit in FIFOs with stale translations we wait until all
    //  pre-invalidation responses in order to avoid filling with state
    //  translations.
    //
    // ====================================================================

    logic epoch_allow_fills;
    assign allow_fills = epoch_allow_fills && ! csrs.vtp_in_inval_page_valid;

    cci_mpf_shim_vtp_chan_inval_epoch
      #(
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      epoch_trk
       (
        .clk,
        .reset,
        .sendReq(cTxValid_q),
        .reqEpoch(cur_req_epoch),
        .recvRsp(tlb_lookup_deq_q),
        .recvEpoch(read_epoch_out),
        .newEpoch(csrs.vtp_in_inval_page_valid),
        .allowFills(epoch_allow_fills)
        );

endmodule // cci_mpf_shim_vtp_chan_l2_lookup


module cci_mpf_shim_vtp_chan_l1_caches
  #(
    parameter N_LOCAL_4KB_CACHE_ENTRIES = 512,
    parameter N_LOCAL_2MB_CACHE_ENTRIES = 512,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Lookup address.  The incoming address is the index of a 4KB page.
    // Larger page size lookups will just drop low address bits.
    input  t_tlb_4kb_va_page_idx lookupVA,
    output logic T3_hit_4kb,
    output logic T3_hit_2mb,
    // Or of all size-specific hits
    output logic T3_hit,
    output t_tlb_4kb_pa_page_idx T3_hitPA,

    // Insert translation in cache.  Like lookupVA, these addresses are
    // transformed internally for page sizes larger than 4KB.
    input  t_tlb_4kb_va_page_idx insertVA,
    input  t_tlb_4kb_pa_page_idx insertPA,
    input  en_insert_4kb,
    input  en_insert_2mb,

    // CSRs
    cci_mpf_csrs.vtp csrs
    );

    //
    // The local cache is direct mapped.  Break a VA into cache index
    // and tag.
    //
    typedef logic [$clog2(N_LOCAL_4KB_CACHE_ENTRIES)-1 : 0] t_vtp_tlb_4kb_cache_idx;
    typedef logic [$bits(t_tlb_4kb_va_page_idx)-$bits(t_vtp_tlb_4kb_cache_idx)-1 : 0]
        t_vtp_tlb_4kb_cache_tag;

    typedef logic [$clog2(N_LOCAL_2MB_CACHE_ENTRIES)-1 : 0] t_vtp_tlb_2mb_cache_idx;
    typedef logic [$bits(t_tlb_2mb_va_page_idx)-$bits(t_vtp_tlb_2mb_cache_idx)-1 : 0]
        t_vtp_tlb_2mb_cache_tag;


    //
    // Functions to extract cache index and tag from a 4KB virtual page address
    //
    function automatic t_vtp_tlb_4kb_cache_idx cacheIdx4KB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_4kb_cache_tag tag;
        t_vtp_tlb_4kb_cache_idx idx;
        {tag, idx} = va;
        return idx;
    endfunction

    function automatic t_vtp_tlb_4kb_cache_tag cacheTag4KB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_4kb_cache_tag tag;
        t_vtp_tlb_4kb_cache_idx idx;
        {tag, idx} = va;
        return tag;
    endfunction

    function automatic t_vtp_tlb_2mb_cache_idx cacheIdx2MB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_2mb_cache_tag tag;
        t_vtp_tlb_2mb_cache_idx idx;
        {tag, idx} = vtp4kbTo2mbVA(va);
        return idx;
    endfunction

    function automatic t_vtp_tlb_2mb_cache_tag cacheTag2MB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_2mb_cache_tag tag;
        t_vtp_tlb_2mb_cache_idx idx;
        {tag, idx} = vtp4kbTo2mbVA(va);
        return tag;
    endfunction


    // ====================================================================
    //
    // Reset (invalidate) the TLB when requested by SW.
    // inval_translation_cache is held for only one cycle.
    //
    // ====================================================================

    logic vtp_enabled;
    logic n_reset_tlb, n_reset_tlb_q;
    always @(posedge clk)
    begin
        vtp_enabled <= csrs.vtp_in_mode.enabled;
        n_reset_tlb <= ~csrs.vtp_in_mode.inval_translation_cache;
        n_reset_tlb_q <= n_reset_tlb;

        if (reset)
        begin
            vtp_enabled <= 1'b0;
            n_reset_tlb <= 1'b0;
            n_reset_tlb_q <= 1'b0;
        end
    end


    // ====================================================================
    //
    //  Lookup state pipeline
    //
    // ====================================================================

    t_tlb_4kb_va_page_idx lookup_va[1:2];

    // The pipeline runs whether or not the underlying cache is ready.
    // Record whether a lookup may be valid.
    logic lookup_valid[1:2];
    logic rdy;

    always_ff @(posedge clk)
    begin
        lookup_va[1] <= lookupVA;
        lookup_va[2] <= lookup_va[1];

        lookup_valid[1] <= rdy && n_reset_tlb && n_reset_tlb_q && vtp_enabled;
        lookup_valid[2] <= lookup_valid[1];
    end


    // ====================================================================
    //
    //  Local L1 cache of 4KB page translations.
    //
    // ====================================================================

    logic cache_4kb_rdy;
    t_tlb_4kb_pa_page_idx cache_4kb_pa, T3_cache_4kb_pa;
    t_vtp_tlb_4kb_cache_tag cache_4kb_tag;
    logic cache_4kb_valid;

    logic wen_4kb;

    t_tlb_4kb_va_page_idx insert_va;
    t_tlb_4kb_pa_page_idx insert_pa;
    logic insert_addr_is_valid;

    cci_mpf_prim_ram_simple_init
      #(
        .N_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_DATA_BITS($bits(t_tlb_4kb_pa_page_idx) + $bits(t_vtp_tlb_4kb_cache_tag) + 1),
        .INIT_VALUE({ t_tlb_4kb_pa_page_idx'('x), t_vtp_tlb_4kb_cache_tag'('x), 1'b0 }),
        .N_OUTPUT_REG_STAGES(1)
        )
      cache4kb
       (
        .clk,
        .reset(~n_reset_tlb_q),
        .rdy(cache_4kb_rdy),

        .wen(wen_4kb),
        .waddr(cacheIdx4KB(insert_va)),
        .wdata({ insert_pa, cacheTag4KB(insert_va), insert_addr_is_valid }),

        // Cache read is initiated in pipeline cycle 0
        .raddr(cacheIdx4KB(lookupVA)),
        .rdata({ cache_4kb_pa, cache_4kb_tag, cache_4kb_valid })
        );

    // Cache read data arrives in cycle 2
    always_ff @(posedge clk)
    begin
        T3_hit_4kb <= (cacheTag4KB(lookup_va[2]) == cache_4kb_tag) &&
                      cache_4kb_valid &&
                      lookup_valid[2];
        T3_cache_4kb_pa <= cache_4kb_pa;
    end


    // ====================================================================
    //
    //  Local L1 cache of 2MB page translations.
    //
    // ====================================================================

    logic cache_2mb_rdy;
    t_tlb_2mb_pa_page_idx cache_2mb_pa, T3_cache_2mb_pa;
    t_vtp_tlb_2mb_cache_tag cache_2mb_tag;
    logic cache_2mb_valid;

    logic wen_2mb;

    cci_mpf_prim_ram_simple_init
      #(
        .N_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        .N_DATA_BITS($bits(t_tlb_2mb_pa_page_idx) + $bits(t_vtp_tlb_2mb_cache_tag) + 1),
        .INIT_VALUE({ t_tlb_2mb_pa_page_idx'('x), t_vtp_tlb_2mb_cache_tag'('x), 1'b0 }),
        .N_OUTPUT_REG_STAGES(1)
        )
      cache2mb
       (
        .clk,
        .reset(~n_reset_tlb_q),
        .rdy(cache_2mb_rdy),

        .wen(wen_2mb),
        .waddr(cacheIdx2MB(insert_va)),
        .wdata({ vtp4kbTo2mbPA(insert_pa), cacheTag2MB(insert_va), insert_addr_is_valid }),

        // Cache read is initiated in pipeline cycle 0
        .raddr(cacheIdx2MB(lookupVA)),
        .rdata({ cache_2mb_pa, cache_2mb_tag, cache_2mb_valid })
        );

    // Cache read data arrives in cycle 2
    always_ff @(posedge clk)
    begin
        T3_hit_2mb <= (cacheTag2MB(lookup_va[2]) == cache_2mb_tag) &&
                      cache_2mb_valid &&
                      lookup_valid[2];
        T3_cache_2mb_pa <= cache_2mb_pa;
    end


    // ====================================================================
    //
    //  Merged lookup response
    //
    // ====================================================================

    always_comb
    begin
        T3_hit = T3_hit_4kb || T3_hit_2mb;

        if (T3_hit_4kb)
        begin
            T3_hitPA = T3_cache_4kb_pa;
        end
        else
        begin
            T3_hitPA = vtp2mbTo4kbPAx(T3_cache_2mb_pa);
        end
    end

    always_ff @(posedge clk)
    begin
        rdy <= cache_4kb_rdy && cache_2mb_rdy;
        if (reset)
        begin
            rdy <= 1'b0;
        end
    end


    // ====================================================================
    //
    //  Set values for updating the local cache.
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        insert_addr_is_valid <= 1'b1;
        insert_va <= insertVA;
        insert_pa <= insertPA;

        //
        // Invalidation requested by host? Invalidation has higher priority
        // than TLB fill. It's ok to drop a normal fill request since the
        // address can just go through translation again.
        //
        if (csrs.vtp_in_inval_page_valid)
        begin
            insert_addr_is_valid <= 1'b0;
            insert_va <= vtp4kbPageIdxFromVA(csrs.vtp_in_inval_page);
        end

        wen_4kb <= en_insert_4kb || csrs.vtp_in_inval_page_valid;
        wen_2mb <= en_insert_2mb || csrs.vtp_in_inval_page_valid;

        if (reset)
        begin
            wen_4kb <= 1'b0;
            wen_2mb <= 1'b0;
        end
    end


    // ====================================================================
    //
    //  Debug
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        if (DEBUG_MESSAGES && ! reset)
        begin
            if (wen_4kb)
            begin
                if (insert_addr_is_valid)
                begin
                    $display("%m VTP: %0t 4KB: Insert idx %0d, VA 0x%x, PA 0x%x",
                             $time,
                             cacheIdx4KB(insert_va),
                             {insert_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                             {insert_pa, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
                end
                else
                begin
                    $display("%m VTP: %0t 4KB: Remove idx %0d", $time, cacheIdx4KB(insert_va));
                end
            end

            if (wen_2mb)
            begin
                if (insert_addr_is_valid)
                begin
                    $display("%m VTP: %0t 2MB: Insert idx %0d, VA 0x%x, PA 0x%x",
                             $time,
                             cacheIdx2MB(insert_va),
                             {vtp4kbTo2mbVA(insert_va), CCI_PT_2MB_PAGE_OFFSET_BITS'(0), 6'b0},
                             {insert_pa, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
                end
                else
                begin
                    $display("%m VTP: %0t 2MB: Remove idx %0d", $time, cacheIdx2MB(insert_va));
                end
            end
        end
    end

endmodule // cci_mpf_shim_vtp_chan_l1_caches


module cci_mpf_shim_vtp_chan_inval_epoch
  #(
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    input  logic sendReq,
    output logic reqEpoch,

    input  logic recvRsp,
    input  logic recvEpoch,

    input  logic newEpoch,
    output logic allowFills
    );

    typedef logic [$clog2(CCI_MPF_SHIM_VTP_MAX_SVC_REQS+1)-1 : 0] t_req_cnt;

    logic cur_epoch;

    always_ff @(posedge clk)
    begin
        // Fills are allowed as long as the current epoch matches the request
        // epoch.
        allowFills <= (reqEpoch == cur_epoch) && ! newEpoch;
    end

    t_req_cnt active_reqs[2];
    logic new_req_for_epoch[2];
    logic new_rsp_for_epoch[2];

    genvar i;
    generate
        for (i = 0; i <= 1; i = i + 1)
        begin : cnt
            // Sending a new outbound request in epoch "i"?
            assign new_req_for_epoch[i] = sendReq && (reqEpoch == 1'(i));
            // Receiving an inbound response for epoch "i"?
            assign new_rsp_for_epoch[i] = recvRsp && (recvEpoch == 1'(i));

            // Update the count of outstanding requests for epoch "i".
            always_ff @(posedge clk)
            begin
                case ({ new_req_for_epoch[i], new_rsp_for_epoch[i] })
                    2'b01: active_reqs[i] <= active_reqs[i] - t_req_cnt'(1);
                    2'b10: active_reqs[i] <= active_reqs[i] + t_req_cnt'(1);
                    default: active_reqs[i] <= active_reqs[i];
                endcase

                if (reset)
                begin
                    active_reqs[i] <= t_req_cnt'(0);
                end
            end
        end
    endgenerate

    always_ff @(posedge clk)
    begin
        //
        // Start a new epoch when newEpoch is set.
        //
        reqEpoch <= reqEpoch ^ newEpoch;

        if (reset)
        begin
            reqEpoch <= 1'b0;
        end
    end

    always_ff @(posedge clk)
    begin
        //
        // The current epoch may transition to match the request epoch as long
        // as no requests are outstanding for the current epoch. Most of the
        // time, cur_epoch already matches reqEpoch, since epoch transitions are
        // rare -- triggered by TLB invalidation requests.
        //
        if (active_reqs[cur_epoch] == t_req_cnt'(0))
        begin
            cur_epoch <= reqEpoch;
        end

        if (reset)
        begin
            cur_epoch <= 1'b0;
        end
    end


    //
    // Debugging
    //
    // synthesis translate_off
    logic cur_epoch_q;
    logic new_epoch_q;

    always_ff @(posedge clk)
    begin
        cur_epoch_q <= cur_epoch;
        new_epoch_q <= newEpoch;

        if (DEBUG_MESSAGES && ! reset)
        begin
            if (new_epoch_q)
            begin
                $display("%m VTP: %0t New epoch %0d requested, %0d outstanding requests",
                         $time, cur_epoch, active_reqs[cur_epoch]);
            end

            if (cur_epoch != cur_epoch_q)
            begin
                $display("%m VTP: %0t Switch to epoch %0d", $time, cur_epoch);
            end
        end
    end
    // synthesis translate_on

endmodule // cci_mpf_shim_vtp_chan_inval_epoch
