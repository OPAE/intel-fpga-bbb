// ***************************************************************************
//                               INTEL CONFIDENTIAL
//
//        Copyright (C) 2008-2014 Intel Corporation All Rights Reserved.
//
// The source code contained or described herein and all  documents related to
// the  source  code  ("Material")  are  owned  by  Intel  Corporation  or its
// suppliers  or  licensors.    Title  to  the  Material  remains  with  Intel
// Corporation or  its suppliers  and licensors.  The Material  contains trade
// secrets  and  proprietary  and  confidential  information  of  Intel or its
// suppliers and licensors.  The Material is protected  by worldwide copyright
// and trade secret laws and treaty provisions. No part of the Material may be
// used,   copied,   reproduced,   modified,   published,   uploaded,  posted,
// transmitted,  distributed,  or  disclosed  in any way without Intel's prior
// express written permission.
//
// No license under any patent,  copyright, trade secret or other intellectual
// property  right  is  granted  to  or  conferred  upon  you by disclosure or
// delivery  of  the  Materials, either expressly, by implication, inducement,
// estoppel or otherwise.  Any license under such intellectual property rights
// must be express and approved by Intel in writing.
//
// Engineer :           Pratik Marolia
// Creation Date :    04-10-2014
// Last Modified :    Mon 20 Jun 2016 12:54:46 PM PDT
// Module Name :    ccip_front_end.sv
// Project :             
// Description :    implements common functionlity at each CCI port
//                  min latency = 1clk
//
// features:
//  1. Reconfig mode: Outputs=1, Inputs=0
//  2. CCI Reset
//  3. CCI Stop Req, Stop Ack protocol
//  4. Write Fence
//  5. CCI protocol checker
//  6. MMIO bar check
//  7. Interrupt range checker
//  8. instantiate user clk pll
// ***************************************************************************
import ccip_if_pkg::*;
`include "vendor_defines.vh"
module ccip_front_end #(parameter ADD_ALMOST_FULL_THRESHOLD=0)
(
    input   wire                    pClk,
    input   wire                    pClkDiv2,
    input   wire                    SystemReset,       // master reset
    input   t_if_ccip_Rx            up_RxPort,          // upstream Rx response
    output  t_if_ccip_Tx            up_TxPort,          // upstream Tx request
    output  logic                   up_C0TxValid,       // C0 output valid
    output  logic                   up_C1TxValid,       // C1 output valid
    output  logic                   up_CfgTxValid,      // Cfg output valid
    output  logic                   up_C1TxBlockMode,   // C1 block mode header
   
    output  t_if_ccip_Rx            afu_RxPort,          // downstream AFU Rx response
    input   t_if_ccip_Tx            afu_TxPort,          // downstream AFU Tx request
    input   logic                   up_C0TxAck,         // C0 Ack
    input   logic                   up_C1TxAck,         // C1 Ack
    input   logic                   ALM_FULL_PULL,         // C1 Ack
    input   logic                   up_CfgTxAck         // Cfg Ack
);
localparam L_BLK_SIZE = 2;
wire        internal_SoftReset_n = ~SystemReset;
wire        C0Tx_fifo_AlmFull    , C1Tx_fifo_AlmFull;
wire        up_C0TxValid_x      , up_C1TxValid_x;
logic       up_C0Tx_mask        , up_C1Tx_mask;
logic       up_RxPort_c0TxAlmFull_q  , up_RxPort_c1TxAlmFull_q;

logic       C1Tx_fifo_dout_v;

// Rx
//-----------------------------------------------------
t_if_ccip_Rx afu_RxPort_c;          // downstream AFU Rx response

    always_comb
    begin

        afu_RxPort_c = up_RxPort;

        afu_RxPort_c.c0TxAlmFull = C0Tx_fifo_AlmFull;
        afu_RxPort_c.c1TxAlmFull = C1Tx_fifo_AlmFull;

        if(SystemReset)
        begin
            afu_RxPort_c.c0.mmioWrValid = 0;
            afu_RxPort_c.c0.mmioRdValid = 0;
        end

    end

    always_ff @(posedge pClk)
    begin
        afu_RxPort <= afu_RxPort_c;
    end

// Tx
//-----------------------------------------------------
wire    C0Tx_fifo_full, C1Tx_fifo_full;
wire    C0Tx_fifo_empty, C1Tx_fifo_empty;
assign  up_C0TxValid       = up_C0TxValid_x & ~up_C0Tx_mask;
assign  up_C1TxValid       = up_C1TxValid_x & ~up_C1Tx_mask;
assign  up_TxPort.c0.valid = up_C0TxValid;
assign  up_TxPort.c1.valid = up_C1TxValid;
wire    afu_C0TxValid       = afu_TxPort.c0.valid;
wire    afu_C1TxValid       = afu_TxPort.c1.valid;
wire    C0Tx_fifo_rdack     = up_C0TxValid & up_C0TxAck;
wire    C1Tx_fifo_rdack     = up_C1TxValid & up_C1TxAck;


parameter L_C0TX_FIFO_DEPTH = $clog2(CCIP_TX_ALMOST_FULL_THRESHOLD + ADD_ALMOST_FULL_THRESHOLD + 3)+ 1;
// Account for :
// 2 clk TxPort ccip_interface_reg register delay
// 1 clk RxPort TxAlmFull register delay
localparam L_C0TX_FULL_THRESH = 2**L_C0TX_FIFO_DEPTH - CCIP_TX_ALMOST_FULL_THRESHOLD - ADD_ALMOST_FULL_THRESHOLD - 2-1 ;
         sync_C1Tx_fifo #(
        .DATA_WIDTH  ( CCIP_C0TX_HDR_WIDTH),
        .CTL_WIDTH   ( 0                  ),
        .DEPTH_BASE2 ( L_C0TX_FIFO_DEPTH  ),
        .GRAM_MODE   ( 3                  ),               // uses optional output register. Dout 2 clks behin Control/Dout_v
        .FULL_THRESH ( L_C0TX_FULL_THRESH )                // fifo_almFull will be asserted if there are more entries than FULL_THRESH
        )
        inst_C0Tx_fifo(
        .Resetb         ( internal_SoftReset_n)      , // Active low reset
        .Clk            ( pClk)                      , // global clock
        .fifo_din       ( afu_TxPort.c0.hdr)         ,      // Data input to the FIFO tail
        .fifo_ctlin     ()                           ,     // Control input
        .fifo_wen       ( afu_C0TxValid)            ,      // Write to the tail
        .fifo_rdack     ( C0Tx_fifo_rdack )         ,      // Read ack, pop the next entry
                                                           // --------------------- Output  -----------------
        .T2_fifo_dout   ( up_TxPort.c0.hdr)        ,    // FIFO read data out
        .T0_fifo_ctlout ()                          ,      // FIFO control data out
        .T0_fifo_dout_v ( up_C0TxValid_x)          ,      // FIFO data out is valid
        .T0_fifo_empty  ( C0Tx_fifo_empty)          ,      // FIFO is empty
        .T0_fifo_full   ( C0Tx_fifo_full )          ,      // FIFO is full
        .T0_fifo_count  ( )                         ,      // Number of entries in the FIFO
        .T0_fifo_almFull( C0Tx_fifo_AlmFull)        ,      // fifo_count > FULL_THRESH
        .T0_fifo_underflow()                        ,      // fifo underflow
        .T0_fifo_overflow ()                               // fifo overflow
        );
        // 1. Detect Block Mode writes- blockMode_c set to 1 for block transfers. CVL arbiter must
        //    allow contiguous transfer of data payload for a block transfer. 
        // 2. Front End module should collect entire Data payload, before a block mode transfer is started
        //    Check for credit on the data buffer
        // 3. If selected interface is almost Full, then suppress subsequent requests from the AFU port

        parameter L_C1TX_FIFO_DEPTH = $clog2(CCIP_TX_ALMOST_FULL_THRESHOLD + ADD_ALMOST_FULL_THRESHOLD + 3)+ 1;
        // Account for :
        // 1 clk TxPort ccip_interface_reg register delay
        // 1 clk RxPort TxAlmFull register delay
        localparam L_C1TX_FULL_THRESH = 2**L_C1TX_FIFO_DEPTH - CCIP_TX_ALMOST_FULL_THRESHOLD - ADD_ALMOST_FULL_THRESHOLD - 3;

        wire [L_BLK_SIZE-1:0]  cl_len_c    = afu_TxPort.c1.hdr.cl_len;
        wire                   sop_c       = afu_TxPort.c1.hdr.sop;
        reg  [L_BLK_SIZE-1:0]  clCount_c, clCount;
        reg                    blockMode_c, blockMode;

        // Collect Data credits
        // 1 credit per complete data payload
        // for multi-CL request the credit is accumulated when last CL is received from AFU
        logic [L_C1TX_FIFO_DEPTH:0]  data_credit;
        logic incr_data_credit, decr_data_credit;
        logic C1Tx_data_avail;
        always_comb
        begin
            incr_data_credit =(blockMode_c==0 
                              )&& afu_TxPort.c1.valid;
            decr_data_credit = up_C1TxBlockMode==0 && C1Tx_fifo_rdack;
        end

        always_ff @(posedge pClk)
        begin
            case({incr_data_credit, decr_data_credit})
                2'b01: begin 
                            data_credit <= data_credit - 1'b1;
                            if(data_credit==1'b1)
                                C1Tx_data_avail <= 1'b0;
                       end
                2'b10: begin
                            data_credit <= data_credit + 1'b1;
                            C1Tx_data_avail <= 1'b1;
                        end
                default: data_credit <= data_credit;
            endcase

            if(SystemReset)
            begin
                data_credit <= 0;
                C1Tx_data_avail <= 1'b0;
            end

        end

        // State Machine generates a level signal blockMode which stays asserted for a multi-CL transfer, 
        // for all but the last CL
        always_comb
        begin
            blockMode_c = blockMode;
            clCount_c   = clCount;

            case(blockMode)
                1'b0:begin
                    if(afu_TxPort.c1.valid && sop_c && cl_len_c!=0)
                    begin
                        blockMode_c  = 1'b1;
                        clCount_c    = cl_len_c;
                    end
                end
                1'b1:begin
                    if(afu_TxPort.c1.valid)
                    begin
                        clCount_c    = clCount - 1'b1;
                        if(clCount==1'b1)
                            blockMode_c  = 1'b0;
                    end
                end
            endcase

            up_C0Tx_mask = up_RxPort_c0TxAlmFull_q;
            up_C1Tx_mask = up_RxPort_c1TxAlmFull_q & ALM_FULL_PULL;
            
        end

        always_ff @(posedge pClk)
        begin
            blockMode <= blockMode_c;
            clCount   <= clCount_c;

            up_RxPort_c0TxAlmFull_q <= up_RxPort.c0TxAlmFull;

            // Block Writes- do not stall in between block transfer.
            // AlmostFull threshold does allow upto 4 CL transfer.
            case(up_RxPort_c1TxAlmFull_q)
            1'b0:
            up_RxPort_c1TxAlmFull_q <= ( (~up_C1TxBlockMode & up_C1TxAck)
                                            |~up_C1TxAck 
                                        );
            1'b1:begin
                if(ALM_FULL_PULL==0)
                    up_RxPort_c1TxAlmFull_q <= 0;
            end
            default:
                up_RxPort_c1TxAlmFull_q<=0;
            endcase
            
            if(SystemReset)
            begin
                blockMode <= 0;
                clCount   <= 0;
            end
        end

        assign up_C1TxValid_x = C1Tx_fifo_dout_v && C1Tx_data_avail;
        sync_C1Tx_fifo #(
        .DATA_WIDTH  ( CCIP_C1TX_HDR_WIDTH+CCIP_CLDATA_WIDTH ),
        .CTL_WIDTH   ( 1 ),
        .DEPTH_BASE2 ( L_C1TX_FIFO_DEPTH  ),
        .GRAM_MODE   ( 3 ),
        .FULL_THRESH ( L_C1TX_FULL_THRESH )                // fifo_almFull will be asserted if there are more entries than FULL_THRESH
        )
        inst_C1Tx_fifo (
        .Resetb         ( internal_SoftReset_n)       ,    // Active low reset
        .Clk            ( pClk)                       ,    // global clock
        .fifo_din       ( {afu_TxPort.c1.data,
                           afu_TxPort.c1.hdr} )       ,    // Data input to the FIFO tail
        .fifo_ctlin     ( blockMode_c )               ,    // Control input
        .fifo_wen       ( afu_C1TxValid       )       ,    // Write to the tail
        .fifo_rdack     ( C1Tx_fifo_rdack )           ,    // Read ack, pop the next entry
                                                           // --------------------- Output  -----------------
        .T2_fifo_dout   ( {up_TxPort.c1.data,
                           up_TxPort.c1.hdr})        ,    // FIFO read data out
        .T0_fifo_ctlout (  up_C1TxBlockMode )        ,    // FIFO control data out
        .T0_fifo_dout_v ( C1Tx_fifo_dout_v    )       ,    // FIFO data out is valid
        .T0_fifo_empty  ( C1Tx_fifo_empty )           ,    // FIFO is empty
        .T0_fifo_full   ( C1Tx_fifo_full  )           ,    // FIFO is full
        .T0_fifo_count  ( )                           ,    // Number of entries in the FIFO
        .T0_fifo_almFull( C1Tx_fifo_AlmFull)          ,    // fifo_count > FULL_THRESH
        .T0_fifo_underflow()                          ,    // fifo underflow
        .T0_fifo_overflow ()                               // fifo overflow
        );
        logic CfgTx_fifo_full ;
        logic CfgTx_emty ;
        assign up_CfgTxValid = ~CfgTx_emty;
        // Cfg Channel
        // need a fifo to arbitrate between cfg reads from various agents
           scfifo  scfifo_component (
                 .aclr (SystemReset),
                 .data ({afu_TxPort.c2.data, 
                         afu_TxPort.c2.hdr}),
                 .rdreq (up_CfgTxAck),
                 .clock (pClk),
                 .wrreq (afu_TxPort.c2.mmioRdValid),
                 .q ({up_TxPort.c2.data,
                      up_TxPort.c2.hdr}),
                 .empty(CfgTx_emty)
                 );
     defparam
     scfifo_component.enable_ecc  = "FALSE",
     scfifo_component.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
     scfifo_component.lpm_numwords  = 2**8,
     scfifo_component.lpm_showahead  = "ON",
     scfifo_component.lpm_type  = "scfifo",
     scfifo_component.lpm_width  = CCIP_MMIODATA_WIDTH+CCIP_C2TX_HDR_WIDTH,
     scfifo_component.lpm_widthu  = 8,
     scfifo_component.overflow_checking  = "ON",
     scfifo_component.underflow_checking  = "ON",
     scfifo_component.use_eab  = "ON";
      
    // Request tracker
    //--------------------------------------------------------------------------------------------------------
    logic [12:0] num_rd_pend;
    logic [12:0]  num_wr_pend;
    logic C0Rx_recvd_q, C1Rx_recvd_q;
    logic C0Tx_sent_q, C0Tx_sent_qq, C0Tx_sent_qqq;
    logic C1Tx_sent_q, C1Tx_sent_qq, C1Tx_sent_qqq;
    logic [L_BLK_SIZE:0] C0Tx_cl_length_qqq;

    // Track outstanding Read  requests
    logic C0Rx_rd_recvd_q;
    logic C0Tx_rd_sent_q, C0Tx_rd_sent_qq, C0Tx_rd_sent_qqq;
    always @(posedge pClk)
    begin
        C0Tx_rd_sent_q    <= C0Tx_fifo_rdack;
        C0Tx_rd_sent_qq   <= C0Tx_rd_sent_q;
        C0Tx_rd_sent_qqq  <= C0Tx_rd_sent_qq;
        C0Tx_cl_length_qqq <= up_TxPort.c0.hdr.cl_len + 1'b1;

        C0Rx_rd_recvd_q   <= afu_RxPort_c.c0.rspValid && afu_RxPort_c.c0.hdr.resp_type==eRSP_RDLINE;

        case ({C0Tx_rd_sent_qqq, C0Rx_rd_recvd_q})
            2'b10: num_rd_pend <= num_rd_pend + C0Tx_cl_length_qqq;
            2'b11: num_rd_pend <= num_rd_pend + C0Tx_cl_length_qqq - 1'b1;
            2'b01: num_rd_pend <= num_rd_pend - 1'b1;
        endcase

        if(SystemReset)
            num_rd_pend <= 0;
    end


    // Track outstanding Write requests
    logic [2:0] num_wr_decr, num_wr_incr;
    logic C1Rx_wr_recvd_q;
    logic C1Tx_wr_sent_q;
    logic [L_BLK_SIZE:0] C1Rx_cl_length_q;
    always @(posedge pClk)
    begin
        C1Tx_wr_sent_q    <= C1Tx_fifo_rdack;
        C1Rx_wr_recvd_q   <= afu_RxPort_c.c1.rspValid;
        // REsponse header
        // Format= 0 - unpacked     - from QPI & PCIe
        // Format= 1 - packed       - from PCIe only
        // C0Rx Header cl_length is always 1, since it is either 1CL Wr Response or a Read Response which is always unpacked
        
        case(afu_RxPort_c.c1.hdr.format)
            1'b1: C1Rx_cl_length_q <= afu_RxPort_c.c1.hdr.cl_num + 1'b1;
            1'b0: C1Rx_cl_length_q <= 1'b1;
        endcase

        num_wr_incr <= C1Tx_wr_sent_q;
 
        if(C1Rx_wr_recvd_q)
            num_wr_decr <= C1Rx_cl_length_q;
        else 
            num_wr_decr <= 0;

        num_wr_pend <= num_wr_pend + num_wr_incr - num_wr_decr;

        if(SystemReset)
        begin
            num_wr_decr <= 0;
            num_wr_incr <= 0;
            num_wr_pend <= 0;
        end
    end

    // Error Detection Logic
    //--------------------------------------------------------------------------------------------------------
    
    t_if_ccip_Rx    DEBUG_up_RxPort;
    t_if_ccip_Tx    DEBUG_afu_TxPort;
    logic           DEBUG_C0Tx_fifo_full, DEBUG_C1Tx_fifo_full, DEBUG_CfgTx_fifo_full;
    logic [31:0]    error_vector;
    
    always @(posedge pClk)
    begin
    
        // synthesis translate_off
        if(|error_vector)
            $finish();
        // synthesis translate_on
        // RW1CS behavior to clear the errors. This module will create an error pulse. The attributes will be implemented by the CSR module.
        error_vector     <= 0;
        DEBUG_up_RxPort <= up_RxPort;
        DEBUG_afu_TxPort <= afu_TxPort;
        DEBUG_CfgTx_fifo_full <= CfgTx_fifo_full;
    
        // Cfg Error
        if(DEBUG_CfgTx_fifo_full && DEBUG_afu_TxPort.c2.mmioRdValid)
        begin
            //synthesis translate_off
            $display("%m \m ERROR: C2 MMio Resp Fifo overflow detected");
                 //synthesis translate_on
            error_vector [2] <= 1'b1;
        end
    
        // Misc Errors
        if(num_rd_pend[12]==1'b1 || num_wr_pend[12]==1'b1)    // non-fatal
        begin
            //synthesis translate_off
            $display("%m \m ERROR: Num request pending counter overflow");
            //synthesis translate_on
            error_vector [3] <= 1'b1;
        end
    
        if(SystemReset)
            error_vector <= 0;
    
    end
endmodule
