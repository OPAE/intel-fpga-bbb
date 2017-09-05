// ***************************************************************************
//                               INTEL CONFIDENTIAL
//
//        Copyright (C) 2008-2011 Intel Corporation All Rights Reserved.
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
// Engineer:            Pratik Marolia
// Create Date:         Fri Jul 29 14:45:20 PDT 2011
// Module Name:         sbv_gfifo.v
// Project:             NLB AFU 
// Description:
//
// ***************************************************************************

//-----------------------------------------------------------------
//  (C) Copyright Intel Corporation, 2008.  All Rights Reserved.
//-----------------------------------------------------------------
//
//  
//---------------------------------------------------------------------------------------------------------------------------------------------------
//                                        sbv_gfifo with Read Store & Read-Write forwarding
//---------------------------------------------------------------------------------------------------------------------------------------------------
// 22-4-2010 : Renamed cci_hdr_fifo into sb_gfifo
// 26-4-2011 : Derived sbv_gfifo from sb_gfifo.
//	       The read engine in the fifo presents valid data on output ports. When data out is used, rdack should be asserted.
//	       This is different from a traditional fifo where the fifo pops out a new data in response to a rden in the previous Clk.
//	       Instead this fifo presents the valid data on output port & expects a rdack in the same Clk when data is consumed.
// 27-6-2012 : Redesigned the sbv_gfifo to have registered outputs. The design consists of BRAM based fifo with 2 register stages in front
//             of it. The second register stage is required to hide the BRAM write to read latency of 1. 
// 10-10-2014: Edited the fifo with output register stage. Validated in JKT environment. Stratix 5 max frequency = 579MHz
// 10-13-2014: Mapped to Distributed memory with registered output. Fifo dout 1 clk delayed after fifo_dout_v
// Write  to Read latency = 1, i.e. fifo_wen t0 fifo_dout_v latency = 1clk
// fifo_dout 1 cycle after fifo_dout_v
// 04-09-2015: derived from gfifo_2d
//             Control will be 2clks ahead of Data
//             Write to Read Control latency = 1clk
//             Write to Read Data latency = 3clks
//
//      |Write 1|T0     |       |T2     |
//      |       |Dout_v1|       |Dout   |
//      |       |(ctl)  |       |(data) |
//      |       |       |       |       |
//
// Full thresh          - value should be less than/ euqual to 2**DEPTH_BASE2. If # entries more than threshold than fifo_almFull is set
//
// 
//

`include "vendor_defines.vh"
module sync_C1Tx_fifo #(parameter DATA_WIDTH      =51,
                        CTL_WIDTH       =0,           // control data width
                        DEPTH_BASE2     =3, 
                        GRAM_STYLE      =`GRAM_AUTO,
                        GRAM_MODE       =3,        // Uses registered RAM outputs. Write to Read Data out Lantecy = 2clks
                        FULL_THRESH     =0          // fifo_almFull will be asserted if there are more entries than FULL_THRESH
                       )
                (
                Resetb,            //Active low reset
                Clk,               //global clock
                fifo_din,          //Data input to the FIFO tail
                fifo_ctlin,        //control input
                fifo_wen,          //Write to the tail
                fifo_rdack,        //Read ack, pop the next entry
                                   //--------------------- Output  ------------------
                T2_fifo_dout,         //FIFO read data out     
                T0_fifo_ctlout,       //FIFO control output
                T0_fifo_dout_v,       //FIFO data out is valid 
                T0_fifo_empty,        //FIFO is empty
                T0_fifo_full,         //FIFO is full
                T0_fifo_count,        //Number of entries in the FIFO
                T0_fifo_almFull,      //fifo_count > FULL_THRESH
                T0_fifo_underflow,    // fifo underflow
                T0_fifo_overflow      // fifo overflow
            )/* synthesis maxfan=128 */;

input                    Resetb;           // Active low reset
input                    Clk;              // global clock    
input  [DATA_WIDTH-1:0]  fifo_din;         // FIFO write data in
input  [CTL_WIDTH-1:0]   fifo_ctlin;
input                    fifo_wen;         // FIFO write enable
(* noprune *)          reg          Debug_fifo_wen;         // FIFO write enable
input                    fifo_rdack;       // Read ack, pop the next entry

output [DATA_WIDTH-1:0]  T2_fifo_dout;        // FIFO read data out
output [CTL_WIDTH-1:0]   T0_fifo_ctlout;
output                   T0_fifo_dout_v;      // FIFO data out is valid 
output                   T0_fifo_empty;       // set when FIFO is empty
output                   T0_fifo_full;        // set if Fifo full
output [DEPTH_BASE2-1:0] T0_fifo_count;       // Number of entries in the fifo
output                   T0_fifo_almFull;
output                   T0_fifo_underflow;
output                   T0_fifo_overflow;
//------------------------------------------------------------------------------------

reg                             T0_fifo_underflow;
reg                             T0_fifo_overflow;
reg                             bram_wen, bram_full, bram_empty;
reg     [DATA_WIDTH-1:0]        bram_wdin;
wire    [DATA_WIDTH-1:0]        bram_rdout;
reg     [DEPTH_BASE2-1:0]       bram_raddr_next;
reg     [DEPTH_BASE2-1:0]       bram_raddr_d;
(* `NO_RETIMING *)              reg                         dram_v;
(* maxfan=150 *)                reg     [DEPTH_BASE2-1:0]   bram_waddr, bram_raddr;
(* ramstyle = "logic" *)        reg     [CTL_WIDTH:0]       ctl_reg    [2**DEPTH_BASE2-1:0];
(* `NO_RETIMING, maxfan=7 *)    reg     [DEPTH_BASE2:0]     bram_count;
(* `NO_RETIMING, `NO_MERGE *)   reg                         bram_rena;
(* `NO_RETIMING, `NO_MERGE *)   reg                         bram_renb;

wire                    T0_fifo_dout_v     = dram_v;
wire [DATA_WIDTH-1:0]   T2_fifo_dout       = bram_rdout;
wire                    T0_fifo_full       = bram_count[DEPTH_BASE2];
reg                     T0_fifo_almFull;
reg  [CTL_WIDTH-1:0]    T0_fifo_ctlout;
wire [DEPTH_BASE2-1:0]  T0_fifo_count      = bram_count[DEPTH_BASE2-1:0];
wire                    T0_fifo_empty      = bram_empty;

// Data out shift register
// Shifts in data from either fifo_din or gram_rdata
always @(posedge Clk)
begin
        if(fifo_wen)
            ctl_reg[bram_waddr][0] <= fifo_ctlin;

        case(dram_v)
            1'b0:begin
                if(fifo_wen)
                begin
                    T0_fifo_ctlout <= fifo_ctlin;
                    dram_v <= 1'b1;
                end
            end
            1'b1:begin
                if(bram_rena  &&  ~fifo_wen && bram_count==1'b1)
                    dram_v   <= 1'b0;
                if(bram_rena && fifo_wen && bram_count==1'b1)
                    T0_fifo_ctlout <= fifo_ctlin;
                else if(bram_rena)
                    T0_fifo_ctlout <= ctl_reg[bram_raddr_next][0];
            end
        endcase

        if(CTL_WIDTH==0)
            T0_fifo_ctlout  <= 0;

        if(T0_fifo_empty & fifo_rdack )
            T0_fifo_underflow   <= 1'b1;
        if(T0_fifo_full & fifo_wen)
            T0_fifo_overflow    <= 1'b1;

        if(!Resetb)
        begin
                dram_v <= 0;
                T0_fifo_underflow <= 0;
                T0_fifo_overflow <= 0;
        end
end

always @(*)
begin
        bram_wen  = fifo_wen;
        bram_rena = fifo_rdack;
        bram_renb = fifo_rdack;
        bram_wdin = fifo_din;
        bram_full = bram_count[DEPTH_BASE2];
end

always @(posedge Clk)
begin
        if(bram_wen & ~bram_full)
                bram_waddr <= bram_waddr + 1'b1;
        if(bram_renb & ~bram_empty)
        begin
                bram_raddr <= bram_raddr + 1'b1;
                bram_raddr_next <= bram_raddr+2'h2;
        end

        bram_count      <= bram_count + (~bram_full & bram_wen) - (~bram_empty & bram_renb);
        
        case(bram_empty)
                1'b0: if(bram_count==1'b1 && ~bram_wen && bram_renb)
                        bram_empty      <= 1'b1;
                1'b1: if(bram_wen)
                        bram_empty      <= 1'b0;
        endcase
        
      
        if(!Resetb)
        begin
                bram_waddr      <= 0;
                bram_raddr      <= 0;
                bram_raddr_next <= 1'b1;
                bram_count      <= 0;
                bram_empty      <= 1'b1;
        end
end

// generate programmable full only when required
generate if (FULL_THRESH>0)
begin : GEN_ENABLE_fifo_almFull
        always @(posedge Clk)
        begin
                if (!Resetb)
                        T0_fifo_almFull <= 0;
                else 
                begin
                        casex ({(bram_rena  && ~T0_fifo_empty), (fifo_wen && ~T0_fifo_full)})
                        2'b10:        T0_fifo_almFull       <= (bram_count-1'b1) >= FULL_THRESH;
                        2'b01:        T0_fifo_almFull       <= (bram_count+1'b1) >= FULL_THRESH;
                        default:      T0_fifo_almFull       <= T0_fifo_almFull;
                        endcase
                end
        end
end
endgenerate

//------------------------------------------------------------------------------------
// instantiate gram with mode 3. Uses output register stage
// read to data out latency = 2clks
// we on critical path. Optimization- always write to the ram, when we==1, the wraddr is incremented
// this preserves the last write data to ram
// When fifo_full, it will corrupt the 0th data, current raddr. Therefore drop wren when fifo_full.

gram_sdp #(.BUS_SIZE_ADDR(DEPTH_BASE2), 
              .BUS_SIZE_DATA (DATA_WIDTH),
              .GRAM_MODE     (GRAM_MODE), 
              .GRAM_STYLE    (GRAM_STYLE)
            ) 
inst_gram_sdp (
          .clk  (Clk),
          .we   (~bram_full),
          .waddr(bram_waddr),
          .din  (bram_wdin),
          .raddr(bram_raddr),
          .dout (bram_rdout)
        );

//---------------------------------------------------------------------------------------------------------------------
//              Error Logic
//---------------------------------------------------------------------------------------------------------------------
/*synthesis translate_off */
always @(*)
begin
        assert(T0_fifo_underflow==0) else $fatal("ERROR: fifo underflow detected. \n Module Name: %m");
        assert(T0_fifo_overflow==0) else $fatal("ERROR: fifo overflow detected. \n Module Name: %m");
end
/*synthesis translate_on */
endmodule 


