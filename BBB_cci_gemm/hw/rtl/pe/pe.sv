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
/* 
* So this is a systolic PE that performs a dot product on two 256bit vector inputs.
* The core functaionally is:
* - Perform a Dot Product on the two input vectors
* - Cache storage for intermetidate results.
* - Control for intermetidate results accumulation
* - Allow for systolic output of the input vectors
* - A drain memory to collect the result of the block
* - A systloc drain connect for taking the output results
* - Handle systolic input of the drain result
* 
*/



module pe #(
  DATA_WIDTH = 8,
  ACCU_WIDTH = 10,
  VECTOR_LENGTH = 32,
  PE_LATENCY = 1,
  ROW_NUM = 1
)
(
  clk,

  // Input Control
  rst_in,
  ena_in,
  acc_fin_in,
  acc_res_in,
  acc_stop_in,

  // Input Data
  a_in,
  b_in,
  drain_res_in,

  // Output Control
  rst_out,
  ena_out,
  acc_fin_out,
  acc_res_out,
  acc_stop_out,

  // Output Data
  a_out,
  b_out,
  drain_res_out,

  // Systolic Drain Signals
  drain_neig_valid,
  drain_neig_rdy,
  drain_valid,
  drain_rdy
);

  // --------------------------------------------------------------------------

  //localparam OUT_WIDTH = (DATA_WIDTH == 1) ? 32 : DATA_WIDTH*2;
  localparam OUT_WIDTH = 32;

  // -------------------
  // Pipeline Parameters
  // -------------------
  localparam INPUT_DELAY = 1;
  localparam RES_DELAY = 1;
  
  `ifdef GEMM_MODE_32
    `ifdef CHAIN_8_DSP
		localparam MULT_LATENCY = 10 ; 
	`else
		localparam MULT_LATENCY = 15;
	`endif
	localparam OUT_DELAY = 0;
	localparam TREE_DELAY = 0;
  `else
	localparam MULT_LATENCY= 3;
	localparam TREE_DELAY = 1;
	localparam OUT_DELAY = 1;
   `endif
   
  // --------------------------------------------------------s------------------

  input wire	clk;

  // Input Control
  input wire	rst_in;
  input wire	ena_in;
  input wire  acc_fin_in;
  input wire  acc_res_in;
  input wire  acc_stop_in;

  // Input Data    
  input wire	[DATA_WIDTH*VECTOR_LENGTH-1:0]  a_in;
  input wire	[DATA_WIDTH*VECTOR_LENGTH-1:0]  b_in;
  input wire  [ACCU_WIDTH-1:0]              drain_res_in;

  // Output Control
  output reg  rst_out;
  output reg  ena_out;
  output reg  acc_fin_out;
  output reg  acc_res_out;
  output reg  acc_stop_out;

  // Output Data
  output reg	[DATA_WIDTH*VECTOR_LENGTH-1:0]  a_out;
  output reg	[DATA_WIDTH*VECTOR_LENGTH-1:0]  b_out;
  output wire  [ACCU_WIDTH-1:0]              drain_res_out;

  // Systolic Drain Signals
  input wire  drain_neig_valid;
  input wire  drain_neig_rdy;
  output wire drain_valid;
  output wire drain_rdy;

  // --------------------------------------------------------------------------
  // -------------------
  // Dot Product Control
  // -------------------
  wire pe_data_ctl_dot_ena;

  // ---------------------
  // Feedback FIFO Control
  // ---------------------
  wire pe_data_ctl_feed_wrreq;
  wire pe_data_ctl_feed_rdreq;
  wire pe_data_ctl_feed_full;
  wire pe_data_ctl_feed_empty;
  wire pe_data_ctl_feed_almfull;

  wire [9:0] pe_data_ctl_feed_usedw;

  // ------------------
  // Drain FIFO Control
  // ------------------ 
  wire pe_data_ctl_drain_wrreq;
  wire pe_data_ctl_drain_rdreq;
  wire pe_data_ctl_drain_valid;
  wire pe_data_ctl_drain_full;
  wire pe_data_ctl_drain_empty;
  wire pe_data_ctl_drain_almfull;

  wire [9:0] pe_data_ctl_drain_usedw;

  // -------------
  // Drain Control
  // -------------
  wire pe_data_ctl_acc_fin;
  wire pe_data_ctl_drain_neig;

  // ------------------------
  // Drain Output and Control
  // ------------------------
  wire [ACCU_WIDTH-1:0] pe_data_drain_out;
  wire pe_ctl_drain_valid;
  wire pe_ctl_drain_rdy;
  wire drain_valid_t;

  // --------------------------------------------------------------------------
  // ---------------------------------- 
  // Delays Systolic Connection Signals
  // ----------------------------------
  nBit_mLength_shiftRegister #(1, PE_LATENCY) RST_SYS         (clk, 1'b0, 1'b1, rst_in, rst_out);
  nBit_mLength_shiftRegister #(1, PE_LATENCY) ENA_SYS         (clk, rst_in, 1'b1, ena_in, ena_out);
  nBit_mLength_shiftRegister #(1, PE_LATENCY) ACC_FIN_SYS     (clk, rst_in, 1'b1, acc_fin_in, acc_fin_out);
  nBit_mLength_shiftRegister #(1, PE_LATENCY) ACC_RES_SYS     (clk, rst_in, 1'b1, acc_res_in, acc_res_out);
  nBit_mLength_shiftRegister #(1, PE_LATENCY) ACC_STOP_SYS    (clk, rst_in, 1'b1, acc_stop_in, acc_stop_out);

  nBit_mLength_shiftRegister #(DATA_WIDTH*VECTOR_LENGTH, PE_LATENCY) A_SYS (clk, rst_in, ena_in, a_in, a_out);
  nBit_mLength_shiftRegister #(DATA_WIDTH*VECTOR_LENGTH, PE_LATENCY) B_SYS (clk, rst_in, ena_in, b_in, b_out);

  nBit_mLength_shiftRegister #(1, 1)         DRAIN_VALID_SYS (clk, rst_in, 1'b1, pe_ctl_drain_valid, drain_valid);
  nBit_mLength_shiftRegister #(1, 1)         DRAIN_RDY_SYS   (clk, rst_in, 1'b1, pe_ctl_drain_rdy, drain_rdy);
  nBit_mLength_shiftRegister #(ACCU_WIDTH, 1) DRAIN_DATA_SYS  (clk, rst_in, 1'b1, pe_data_drain_out, drain_res_out);

  // --------------------------------------------------------------------------

  // -----------
  // PE Datapath
  // -----------
  pe_datapath #(  
    .DATA_WIDTH     (DATA_WIDTH), 
    .ACCU_WIDTH     (ACCU_WIDTH),
    .VECTOR_LENGTH  (VECTOR_LENGTH), 
    .MULT_LATENCY   (MULT_LATENCY),
    .INPUT_DELAY    (INPUT_DELAY),
    .TREE_DELAY     (TREE_DELAY),
    .OUT_DELAY      (OUT_DELAY),
    .RES_DELAY      (RES_DELAY),
    .ROW_NUM        (ROW_NUM)    
  ) PE_DATAPATH (
    .clk					          (clk),                      // INPUT
    .rst					          (rst_in),                   // INPUT

    // Dot Product Control
    .pe_dot_ena				      (pe_data_ctl_dot_ena),      // INPUT

    // Dot Product Data
    .pe_dot_a_in	    	    (a_in),                     // INPUT
    .pe_dot_b_in	    	    (b_in),                     // INPUT

    // Result Data
    .pe_result              (pe_data_drain_out),        // OUTPUT

    // Feedback FIFO Control    
    .pe_feed_wrreq		      (pe_data_ctl_feed_wrreq),   // INPUT
    .pe_feed_rdreq		      (pe_data_ctl_feed_rdreq),   // INPUT
    .pe_feed_full		        (pe_data_ctl_feed_full),    // OUTPUT
    .pe_feed_empty		      (pe_data_ctl_feed_empty),   // OUTPUT
    .pe_feed_almfull	      (pe_data_ctl_feed_almfull), // OUTPUT
    .pe_feed_usedw		      (pe_data_ctl_feed_usedw),   // OUTPUT

    // Drain FIFO Control
    .pe_drain_wrreq         (pe_data_ctl_drain_wrreq),  // INPUT
    .pe_drain_rdreq         (pe_data_ctl_drain_rdreq),  // INPUT
    .pe_drain_full          (pe_data_ctl_drain_full),   // OUTPUT
    .pe_drain_empty         (pe_data_ctl_drain_empty),  // OUTPUT
    .pe_drain_almfull       (pe_data_ctl_drain_almfull),// OUTPUT
    .pe_drain_usedw         (pe_data_ctl_drain_usedw),  // OUTPUT      

    // Drain Control
    .pe_acc_fin             (pe_data_ctl_acc_fin),      // INPUT
    .pe_drain_neig          (pe_data_ctl_drain_neig),   // INPUT
    .pe_drain_in            (drain_res_in)              // INPUT
  );

  // ----------
  // PE Control 
  // ----------
  pe_control #( 
    .DATA_WIDTH     (DATA_WIDTH), 
    .VECTOR_LENGTH  (VECTOR_LENGTH), 
    .MULT_LATENCY   (MULT_LATENCY),
    .INPUT_DELAY    (INPUT_DELAY),
    .TREE_DELAY     (TREE_DELAY),
    .OUT_DELAY      (OUT_DELAY),
    .RES_DELAY      (RES_DELAY)
  ) PE_CONTROL (
    .clk					          (clk),                      // INPUT
    .rst					          (rst_in),                   // INPUT

    // PE Central Control
    .ena					          (ena_in),                   // INPUT
    .acc_fin                (acc_fin_in),               // INPUT
    .acc_res                (acc_res_in),               // INPUT 
    .acc_stop               (acc_stop_in),              // INPUT 

    // Dot Product Control
    .pe_dot_ena			        (pe_data_ctl_dot_ena),      // OUTPUT

    // Feedback FIFO Control 
    .pe_feed_wrreq		      (pe_data_ctl_feed_wrreq),   // OUTPUT
    .pe_feed_rdreq		      (pe_data_ctl_feed_rdreq),   // OUTPUT
    .pe_feed_full		        (pe_data_ctl_feed_full),    // INPUT
    .pe_feed_empty		      (pe_data_ctl_feed_empty),   // INPUT
    .pe_feed_almfull	      (pe_data_ctl_feed_almfull), // INPUT
    .pe_feed_usedw		      (pe_data_ctl_feed_usedw),   // INPUT

    // Drain FIFO Control
    .pe_drain_wrreq         (pe_data_ctl_drain_wrreq),  // OUTPUT
    .pe_drain_rdreq         (pe_data_ctl_drain_rdreq),  // OUTPUT
    .pe_drain_full          (pe_data_ctl_drain_full),   // INPUT
    .pe_drain_empty         (pe_data_ctl_drain_empty),  // INPUT
    .pe_drain_almfull       (pe_data_ctl_drain_almfull),// INPUT
    .pe_drain_usedw         (pe_data_ctl_drain_usedw),  // INPUT 

    // Drain Control
    .pe_acc_fin             (pe_data_ctl_acc_fin),      // OUTPUT
    .pe_drain_neig          (pe_data_ctl_drain_neig),   // OUTPUT

    // Systolic Drain Signals
    .drain_neig_valid       (drain_neig_valid),         // INPUT
    .drain_neig_rdy         (drain_neig_rdy),           // INPUT
    .drain_valid            (pe_ctl_drain_valid),       // OUTPUT
    .drain_rdy              (pe_ctl_drain_rdy)          // OUTPUT 
  );

endmodule

