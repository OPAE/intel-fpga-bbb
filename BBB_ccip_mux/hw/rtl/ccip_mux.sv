
// ***************************************************************************
//                               INTEL CONFIDENTIAL
//
//        Copyright (C) 2008-2012 Intel Corporation All Rights Reserved.
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
// Engineer :       Pratik Marolia
// Creation Date :  09-08-2014
// Last Modified :    Tue 12 Jul 2016 11:23:30 AM PDT
// Module Name :    ccip_mux.sv
// Project :        ccip mux
// Description :    This unit implements an arbiter to connect 4 AFU ports
//                  to a single CCI-P interface
//
//                                                                           
//      +-------+  +-------+  +-------+  +-------+                                                         
//      | Port 0|  | Port 1|  | Port 2|  | Port 3|                                                         
//      +-------+  +-------+  +-------+  +-------+                                                         
//          |          |          |          |                               
//        +-----------------------------------+                              
//        |           Fair Arbiter            |                              
//        +-----------------------------------+                              
//                        |                                                  
//                       CCI-P                                             
//                                                                           
// Capabilities:
// 1. block Mode & 1 CL mode       - DONE
//      - Block Mode: arbiter locks up to the selected AFU port until block transfer completed
// 
// 2. Hirerchial MUX connection supported 
//                                                                          
// 3. UMsg -  Supported
// 
// 4. Multi-CL request supported
//                                                                           
//***************************************************************************
import ccip_if_pkg::*;
`include "vendor_defines.vh"
module ccip_mux # (parameter NUM_SUB_AFUS=8, NUM_PIPE_STAGES=0)
(
    input   wire                    pClk,
    input   wire                    pClkDiv2,
    /* upstream ports */
    input   wire                    SoftReset,                          // upstream reset
    input   wire                    up_Error,
    input   wire                    up_PwrState,
    input   t_if_ccip_Rx            up_RxPort,                          // upstream Rx response port
    output  t_if_ccip_Tx            up_TxPort,                          // upstream Tx request port
    /* downstream ports */
    output  logic                   afu_SoftReset [NUM_SUB_AFUS-1:0],
    output  logic [1:0]             afu_PwrState  [NUM_SUB_AFUS-1:0],
    output  logic                   afu_Error     [NUM_SUB_AFUS-1:0],
    output  t_if_ccip_Rx            afu_RxPort    [NUM_SUB_AFUS-1:0],        // downstream Rx response AFU
    input   t_if_ccip_Tx            afu_TxPort    [NUM_SUB_AFUS-1:0]         // downstream Tx request  AFU

);

localparam LNUM_SUB_AFUS = $clog2(NUM_SUB_AFUS);

t_if_ccip_Tx     fe_TxPort[NUM_SUB_AFUS-1:0];
t_if_ccip_Tx     fe_TxPort_d[NUM_SUB_AFUS-1:0];
t_if_ccip_Rx     fe_RxPort_c[NUM_SUB_AFUS-1:0];
t_if_ccip_Rx     fe_RxPort[NUM_SUB_AFUS-1:0];
t_if_ccip_Tx     up_TxPort_T2_c;
t_if_ccip_Tx     afu_TxPort_Tn[NUM_SUB_AFUS-1:0];
t_if_ccip_Rx     afu_RxPort_Tn[NUM_SUB_AFUS-1:0];
logic [1:0]      afu_PwrState_Tn [NUM_SUB_AFUS-1:0];
logic            afu_Error_Tn [NUM_SUB_AFUS-1:0];

wire  [NUM_SUB_AFUS-1:0]              fe_C0Tx_Ack, fe_C1Tx_Ack;
(* `KEEP_WIRE *) wire  [NUM_SUB_AFUS-1:0]              fe_CfgTx_Ack;
logic [NUM_SUB_AFUS-1:0]              fe_C0Tx_Valid, fe_C1Tx_Valid, fe_CfgTx_Valid;
logic [NUM_SUB_AFUS-1:0]              fe_C1Tx_BlockMode;
logic [LNUM_SUB_AFUS-1:0]             arb_C0Tx_Select, arb_C1Tx_Select, arb_CfgTx_Select,arb_CfgTx_Select_d;
logic [LNUM_SUB_AFUS-1:0]             arb_C0Tx_Select_T1, arb_C1Tx_Select_T1;
logic [LNUM_SUB_AFUS-1:0]             arb_C0Tx_Select_T2,arb_C0Tx_Select_T2_d, arb_C1Tx_Select_T2,arb_C1Tx_Select_T2_d;
logic                            arb_C0Tx_Valid_T1, arb_C1Tx_Valid_T1;
logic                            arb_C0Tx_Valid_T2,arb_C0Tx_Valid_T2_d, arb_C1Tx_Valid_T2;
logic                            C0Tx_outValid, C1Tx_outValid, CfgTx_outValid,CfgTx_outValid_d;
logic                            arb_C0Tx_Valid, arb_C1Tx_Valid,arb_C1Tx_Valid_T2_d;
logic [LNUM_SUB_AFUS-1:0]             rx_C0Id, rx_C1Id, rx_CfgId;

(* `NO_RETIMING *) t_if_ccip_Tx  up_TxPort_T3;
t_if_ccip_c2_Tx pckd2_mmioTx;

// Fan out reset
logic reset = 1'b1;
logic [NUM_SUB_AFUS-1 : 0] reset_afu = {NUM_SUB_AFUS{1'b1}};
always @(posedge pClk)
begin
    reset <= SoftReset;
    for (int i=0; i<NUM_SUB_AFUS;i++)
    begin
        reset_afu[i] <= reset;
    end
end

t_ccip_c0_ReqMmioHdr   mmio_req_hdr;
always @(*)
begin
    for (int i=0; i<NUM_SUB_AFUS;i++)
    begin
        afu_PwrState_Tn[i] = up_PwrState;
        afu_Error_Tn[i]    = up_Error;
        afu_SoftReset[i]   = reset_afu[i];
    end
    // Tx : AFU to Link
    //------------------------------------------------------------
    up_TxPort = up_TxPort_T3;
    // Channel 0
    // -- same clk --
    arb_C0Tx_Valid = C0Tx_outValid;
    // -- 1clk late --
    up_TxPort_T2_c.c0.valid                     = arb_C0Tx_Valid_T2_d;
    up_TxPort_T2_c.c0.hdr                       = fe_TxPort_d[arb_C0Tx_Select_T2_d].c0.hdr;
    up_TxPort_T2_c.c0.hdr.mdata[15-:LNUM_SUB_AFUS]   = arb_C0Tx_Select_T2_d;

    // Channel 1
    // -- same clk --
    arb_C1Tx_Valid = C1Tx_outValid;
    // -- 1clk late --
    up_TxPort_T2_c.c1.valid                     = arb_C1Tx_Valid_T2_d;
    up_TxPort_T2_c.c1.hdr                       = fe_TxPort_d[arb_C1Tx_Select_T2_d].c1.hdr;
    up_TxPort_T2_c.c1.data                      = fe_TxPort_d[arb_C1Tx_Select_T2_d].c1.data;
    up_TxPort_T2_c.c1.hdr.mdata[15-:LNUM_SUB_AFUS]   = arb_C1Tx_Select_T2_d;

    // Cfg Channel
    // Control and data for config channel are aligned in same clock cycle
    up_TxPort_T2_c.c2.mmioRdValid               = pckd2_mmioTx.mmioRdValid;
    up_TxPort_T2_c.c2.hdr                       = pckd2_mmioTx.hdr;
    up_TxPort_T2_c.c2.data                      = pckd2_mmioTx.data;



    // Rx : Link to AFU
    //------------------------------------------------------------
    mmio_req_hdr = t_ccip_c0_ReqMmioHdr'(up_RxPort.c0.hdr);
    for(int i=0;i<NUM_SUB_AFUS;i++)
    begin
        fe_RxPort_c[i].c0.rspValid     = 0;
        fe_RxPort_c[i].c1.rspValid     = 0;
        fe_RxPort_c[i].c0.mmioRdValid  = 0;
        fe_RxPort_c[i].c0.mmioWrValid  = 0;
        fe_RxPort_c[i].c0.hdr          = up_RxPort.c0.hdr;
        fe_RxPort_c[i].c1.hdr          = up_RxPort.c1.hdr;
        fe_RxPort_c[i].c0.data         = up_RxPort.c0.data;
        fe_RxPort_c[i].c0TxAlmFull     = up_RxPort.c0TxAlmFull;
        fe_RxPort_c[i].c1TxAlmFull     = up_RxPort.c1TxAlmFull;
    end

    rx_C0Id     = up_RxPort.c0.hdr.mdata[15-:LNUM_SUB_AFUS];
    rx_C1Id     = up_RxPort.c1.hdr.mdata[15-:LNUM_SUB_AFUS];
    rx_CfgId    = mmio_req_hdr.address[CCIP_MMIOADDR_WIDTH-1-:LNUM_SUB_AFUS];

    //UMSG packets are broadcasted to all SUB_AFUS; 
    //AFU designer should decide weather the UMSG packet belong to the SUB_AFU

    if(up_RxPort.c0.hdr.resp_type==eRSP_UMSG) begin
    for(int umsg_itr=0; umsg_itr<NUM_SUB_AFUS ;umsg_itr++)
        begin
            fe_RxPort_c[umsg_itr].c0.rspValid     = up_RxPort.c0.rspValid;
        end
    end
    else begin
        fe_RxPort_c[rx_C0Id].c0.rspValid     = up_RxPort.c0.rspValid;
    end
    
        fe_RxPort_c[rx_C1Id].c1.rspValid     = up_RxPort.c1.rspValid;
        fe_RxPort_c[rx_CfgId].c0.mmioRdValid = up_RxPort.c0.mmioRdValid;
        fe_RxPort_c[rx_CfgId].c0.mmioWrValid = up_RxPort.c0.mmioWrValid;
end

always @(posedge pClk)
begin
    CfgTx_outValid_d        <=  CfgTx_outValid;
    arb_CfgTx_Select_d      <=  arb_CfgTx_Select;
    arb_C1Tx_Valid_T2_d     <=  arb_C1Tx_Valid_T2;
    arb_C0Tx_Valid_T2_d     <=  arb_C0Tx_Valid_T2;
    arb_C1Tx_Select_T2_d    <=  arb_C1Tx_Select_T2;
    arb_C0Tx_Select_T2_d    <=  arb_C0Tx_Select_T2;
    
    for(int d=0;d<NUM_SUB_AFUS;d++)
    begin
        fe_TxPort_d[d].c2.hdr   <=  fe_TxPort[d].c2.hdr;
        fe_TxPort_d[d].c1.hdr   <=  fe_TxPort[d].c1.hdr;
        fe_TxPort_d[d].c0.hdr   <=  fe_TxPort[d].c0.hdr;
        fe_TxPort_d[d].c2.data  <=  fe_TxPort[d].c2.data;
        fe_TxPort_d[d].c1.data  <=  fe_TxPort[d].c1.data;
    end
    
    pckd2_mmioTx.mmioRdValid    <=  CfgTx_outValid_d;
    pckd2_mmioTx.hdr            <=  fe_TxPort_d[arb_CfgTx_Select_d].c2.hdr;
    pckd2_mmioTx.data           <=  fe_TxPort_d[arb_CfgTx_Select_d].c2.data;
end

always @(posedge pClk)
begin
    up_TxPort_T3      <= up_TxPort_T2_c;
    fe_RxPort          <= fe_RxPort_c;
    arb_C0Tx_Valid_T1  <= arb_C0Tx_Valid;
    arb_C1Tx_Valid_T1  <= arb_C1Tx_Valid;
    arb_C0Tx_Valid_T2  <= arb_C0Tx_Valid_T1;
    arb_C1Tx_Valid_T2  <= arb_C1Tx_Valid_T1;
    arb_C0Tx_Select_T1 <= arb_C0Tx_Select;
    arb_C1Tx_Select_T1 <= arb_C1Tx_Select;
    arb_C0Tx_Select_T2 <= arb_C0Tx_Select_T1;
    arb_C1Tx_Select_T2 <= arb_C1Tx_Select_T1;

    if(reset)
    begin
        up_TxPort_T3.c0.valid    <= 0;
        up_TxPort_T3.c2.mmioRdValid    <= 0;
        up_TxPort_T3.c1.valid    <= 0;
        for(int i=0;i<NUM_SUB_AFUS;i++)
        begin
            fe_RxPort[i].c0.rspValid     <= 0; 
            fe_RxPort[i].c1.rspValid     <= 0;

            fe_RxPort[i].c0.mmioRdValid  <= 0;
            fe_RxPort[i].c0.mmioWrValid  <= 0;
        end
    end
end

generate    
genvar n;
for(n=0;n<NUM_SUB_AFUS;n++)
begin: gen_ccip_ports

    // 2x pipe stages bcoz we added pipe stages to Tx path and Rx.AlmostFull
    ccip_front_end #(
        .ADD_ALMOST_FULL_THRESHOLD(2*NUM_PIPE_STAGES)
    )
    inst_ccip_front_end
    ( 
        .pClk             ( pClk),
        .pClkDiv2         ( pClkDiv2),
        .SystemReset      ( reset),
        .up_RxPort        ( fe_RxPort[n]),     // from Link
        .up_TxPort        ( fe_TxPort[n]),     // to Link
        .up_C0TxValid     ( fe_C0Tx_Valid[n]),     // 1 clk earlier than fe_TxPort
        .up_C1TxValid     ( fe_C1Tx_Valid[n]),     // 1 clk earlier than fe_TxPort
        .up_CfgTxValid    ( fe_CfgTx_Valid[n]),    // same clk as fe_TxPort.Cfg*
        .up_C1TxBlockMode ( fe_C1Tx_BlockMode[n]),
  
        .afu_RxPort        ( afu_RxPort_Tn[n]),   // to AFU
        .afu_TxPort        ( afu_TxPort_Tn[n]),   // from AFU
        .up_C0TxAck       ( fe_C0Tx_Ack[n]),
        .up_C1TxAck       ( fe_C1Tx_Ack[n]),
        .up_CfgTxAck      ( fe_CfgTx_Ack[n]),
        .ALM_FULL_PULL     (up_RxPort.c1TxAlmFull)

    );

    ccip_intf_regs #(
        .NUM_PIPE_STAGES(NUM_PIPE_STAGES)
    )
    inst_ccip_intf_regs 
    (
        .pClk               (pClk),             
    
        .pck_up_pwrState    (afu_PwrState_Tn[n]),
        .pck_up_error       (afu_Error_Tn[n]),  
        .pck_up_sRx         (afu_RxPort_Tn[n]),    
        .pck_up_sTx         (afu_TxPort_Tn[n]),    
    
        .pck_dn_pwrState    (afu_PwrState[n]),
        .pck_dn_error       (afu_Error[n]),
        .pck_dn_sRx         (afu_RxPort[n]),
        .pck_dn_sTx         (afu_TxPort[n])
    );

end
endgenerate

fair_arbiter #(
    .NUM_INPUTS(NUM_SUB_AFUS),
    .LNUM_INPUTS(LNUM_SUB_AFUS)
)
inst_C0TxArb
(
    .clk        (pClk),
    .reset      (reset),
    .in_valid   (fe_C0Tx_Valid),
    .hold_priority('0),
    .out_select (arb_C0Tx_Select),
    .out_select_1hot(fe_C0Tx_Ack),
    .out_valid  (C0Tx_outValid)
);

fair_arbiter #(
    .NUM_INPUTS(NUM_SUB_AFUS),
    .LNUM_INPUTS(LNUM_SUB_AFUS)
)
inst_C1TxArb
(
    .clk        (pClk),
    .reset      (reset),
    .in_valid   (fe_C1Tx_Valid),
    .hold_priority(fe_C1Tx_BlockMode),
    .out_select (arb_C1Tx_Select),
    .out_select_1hot(fe_C1Tx_Ack),
    .out_valid  (C1Tx_outValid)
);
        
fair_arbiter #(
    .NUM_INPUTS(NUM_SUB_AFUS),
    .LNUM_INPUTS(LNUM_SUB_AFUS)
)
scfifo_CfgTxArb
(
    .clk        (pClk),
    .reset      (reset),
    .in_valid   (fe_CfgTx_Valid),
    .hold_priority('0),
    .out_select (arb_CfgTx_Select),
    .out_select_1hot(fe_CfgTx_Ack),
    .out_valid  (CfgTx_outValid)
);

endmodule
