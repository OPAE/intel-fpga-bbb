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

module pe_datapath #(
  DATA_WIDTH = 8,
  ACCU_WIDTH = 10,
  VECTOR_LENGTH = 32,
  MULT_LATENCY = 3,
  INPUT_DELAY = 1,
  TREE_DELAY = 1,
  OUT_DELAY = 1,
  RES_DELAY = 1,
  ROW_NUM = 1
) (
  clk,
  rst,

  // Dot Product Control
  pe_dot_ena,

  // Dot Product Data
  pe_dot_a_in,
  pe_dot_b_in,

  // Result Data
  pe_result,

  // Feeback FIFO Control
  pe_feed_wrreq,
  pe_feed_rdreq,
  pe_feed_full,
  pe_feed_empty,
  pe_feed_almfull,
  pe_feed_usedw,

  // Drain FIFO Control
  pe_drain_wrreq,
  pe_drain_rdreq,
  pe_drain_full,
  pe_drain_empty,
  pe_drain_almfull,
  pe_drain_usedw,

  // Drain Control
  pe_acc_fin,
  pe_drain_neig,
  pe_drain_in
);

  // --------------------------------------------------------------------------

  //localparam OUT_WIDTH = (DATA_WIDTH == 1) ? 32 : DATA_WIDTH*2;
  localparam OUT_WIDTH = 32;

  // --------------------------------------------------------------------------

  input wire clk;
  input wire rst;

  // -------------------    
  // Dot Product Control
  // ------------------- 
  input   wire pe_dot_ena;

  // ----------------
  // Dot Product Data
  // ----------------
  input wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	pe_dot_a_in;
  input wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	pe_dot_b_in;

  // -----------
  // Result Data
  // -----------
  output wire [ACCU_WIDTH-1:0] pe_result;

  // ---------------------    
  // Feedback FIFO Control
  // ---------------------
  input 	wire pe_feed_wrreq;
  input 	wire pe_feed_rdreq;
  output 	wire pe_feed_full;
  output	wire pe_feed_empty;
  output	wire pe_feed_almfull;
  output	wire [9:0] pe_feed_usedw;

  // ---------------------    
  // Drain FIFO Control
  // ---------------------
  input 	wire pe_drain_wrreq;
  input 	wire pe_drain_rdreq;
  output 	wire pe_drain_full;
  output	wire pe_drain_empty;
  output	wire pe_drain_almfull;
  output	wire [9:0] pe_drain_usedw;

  // -------------
  // Drain Control
  // -------------
  input   wire pe_acc_fin;
  input   wire pe_drain_neig;
  input   wire [ACCU_WIDTH-1:0] pe_drain_in;

  // --------------------------------------------------------------------------

  // ------------------
  // Feedback FIFO Data
  // ------------------
  wire [ACCU_WIDTH-1:0]	pe_feed_wrdata;
  wire [ACCU_WIDTH-1:0]	pe_feed_rddata;
  wire [ACCU_WIDTH-1:0]	pe_acc_in;
  reg  [ACCU_WIDTH-1:0]	pe_acc_reg;

  // ------------------
  // Dot Product Result
  // ------------------
  wire [ACCU_WIDTH-1:0] pe_dot_result;
  wire [ACCU_WIDTH-1:0] pe_dot_result_delay;
  wire [ACCU_WIDTH-1:0] pe_comb_result;

  // ---------------
  // Drain FIFO Data 
  // ---------------
  wire [ACCU_WIDTH-1:0]	pe_drain_wrdata;
  wire [ACCU_WIDTH-1:0]	pe_drain_rddata;

  wire pe_drain_wrreq_comb;
  wire pe_comb_wrreq;

  // -----------
  // Drain Input
  // -----------
  wire [ACCU_WIDTH-1:0] pe_drain_in_data;

  // --------------------------------------------------------------------------

  always @(posedge clk) begin
    if (rst) begin
      pe_acc_reg <= 0;
    end else if(pe_dot_ena) begin
      pe_acc_reg <= pe_feed_rdreq ? pe_feed_rddata : 0;
    end
  end

  // Systolic Drain in Connection
  // So when pe_drain_valid is assered we want to take the result from the systolic above.
  assign pe_drain_in_data = pe_drain_neig ? pe_drain_in : 0;

  // Mux Connection between Dot Product, Feedback and Drain FIFOs.
  // If we have finished accumlateing the result take the input form the dsp dot chain
  // other taked it potentially for the systolic pe above
 
`ifdef PACK // Enable the Packer
  pe_packer # (32, 8) PE_PACK (
                                  .clk (clk),
                                  .rst (rst),
                                  .ena (pe_dot_ena),
                                  .i_drain_wrreq(pe_drain_wrreq),
                                  .pe_drain_in  (pe_dot_result_delay),
                                  .o_drain_wrreq(pe_comb_wrreq),
                                  .pe_drain_out (pe_comb_result)
                                  ); 

`else // By default do the non Tenary Computation
  assign pe_comb_wrreq = pe_drain_wrreq;
  assign pe_comb_result = pe_dot_result_delay;
`endif

  assign pe_drain_wrdata  = pe_acc_fin ? pe_comb_result : pe_drain_in_data;
  assign pe_drain_wrreq_comb = pe_acc_fin ? pe_comb_wrreq : pe_drain_wrreq;


  // If we have finished accumlating the result then fill the feed fifo with 0's
  assign pe_feed_wrdata   = pe_dot_result_delay; 

  assign pe_acc_in = pe_acc_reg;

  // Master Output 
  assign pe_result      = pe_drain_rddata;

  // --------------------------------------------------------------------------

  // --------------------
  // Dot Product Pipeline
  // --------------------
  // Add extra pipeline registers here to help with timing.
  nBit_mLength_shiftRegister #(ACCU_WIDTH, RES_DELAY) r0 (clk, rst, pe_dot_ena, pe_dot_result, pe_dot_result_delay);

  // -----------
  // Dot Product
  // -----------
  generate
    if ( DATA_WIDTH == 16) begin
`ifdef TERNARY // Perform the Ternary Computation
      dot16_16bit_ternary #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCU_WIDTH     (ACCU_WIDTH),
        .VECTOR_LENGTH  (VECTOR_LENGTH),
        .MULT_LATENCY   (MULT_LATENCY),
        .INPUT_DELAY    (INPUT_DELAY),
        .TREE_DELAY     (TREE_DELAY),
        .OUT_DELAY      (OUT_DELAY),
        .ROW_NUM        (ROW_NUM)
      ) DOT16_16BIT (
        .clk	  (clk),
        .rst	 (rst),
        .ena	 (pe_dot_ena),
        .acc_reg (pe_acc_in),
        .a_in  	 (pe_dot_a_in),
        .b_in  	 (pe_dot_b_in),
        .result  (pe_dot_result)
      );
`else // By default do the non Tenary Computation
      dot16_16bit #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCU_WIDTH     (ACCU_WIDTH),
        .VECTOR_LENGTH  (VECTOR_LENGTH),
        .MULT_LATENCY   (MULT_LATENCY),
        .INPUT_DELAY    (INPUT_DELAY),
        .TREE_DELAY     (TREE_DELAY),
        .OUT_DELAY      (OUT_DELAY),
        .ROW_NUM        (ROW_NUM)
      ) DOT16_16BIT (
        .clk	  (clk),
        .rst	 (rst),
        .ena	 (pe_dot_ena),
        .acc_reg (pe_acc_in),
        .a_in  	 (pe_dot_a_in),
        .b_in  	 (pe_dot_b_in),
        .result  (pe_dot_result)
      );

`endif
    end else if ( DATA_WIDTH == 32) begin
`ifdef TERNARY // Perform the Ternary Computation
      dot8_32bit_ternary #(
			   .DATA_WIDTH     (DATA_WIDTH),
			   .ACCU_WIDTH     (ACCU_WIDTH),
			   .VECTOR_LENGTH  (VECTOR_LENGTH),
			   .MULT_LATENCY   (MULT_LATENCY),
			   .INPUT_DELAY    (INPUT_DELAY),
			   .TREE_DELAY     (TREE_DELAY),
			   .OUT_DELAY      (OUT_DELAY),
			   .ROW_NUM        (ROW_NUM)
			   ) DOT8_32BIT (
					 .clk        (clk),
					 .rst        (rst),
					 .ena        (pe_dot_ena),
					 .acc_reg    (pe_acc_in),
					 .a_in       (pe_dot_a_in),
					 .b_in       (pe_dot_b_in),
					 .result     (pe_dot_result)
					 );
`else // By default do the non Tenary Computation
       dot8_fp_top #(
		    .DATA_WIDTH     (DATA_WIDTH),
        .ACCU_WIDTH     (ACCU_WIDTH),
        .VECTOR_LENGTH  (VECTOR_LENGTH),
        .MULT_LATENCY   (MULT_LATENCY),
        .INPUT_DELAY    (INPUT_DELAY),
        .TREE_DELAY     (TREE_DELAY),
        .OUT_DELAY      (OUT_DELAY),
        .ROW_NUM        (ROW_NUM)
      ) DOT8_32BIT (
        .clk        (clk),
        .rst        (rst),
        .ena        (pe_dot_ena),
        .acc_reg    (pe_acc_in),
        .a_in       (pe_dot_a_in),
        .b_in       (pe_dot_b_in),
        .result     (pe_dot_result)
      );
`endif
    end else if ( DATA_WIDTH == 1) begin
      bdot256 #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCU_WIDTH     (ACCU_WIDTH),
        .VECTOR_LENGTH  (VECTOR_LENGTH),
        .MULT_LATENCY   (MULT_LATENCY),
        .INPUT_DELAY    (INPUT_DELAY),
        .TREE_DELAY     (TREE_DELAY),
        .OUT_DELAY      (OUT_DELAY),
        .ROW_NUM        (ROW_NUM)
      ) DOT256_1BIT (
        .clk        (clk),
        .rst        (rst),
        .ena        (pe_dot_ena),
        .acc_reg    (pe_acc_in),
        .a_in       (pe_dot_a_in),
        .b_in       (pe_dot_b_in),
        .result     (pe_dot_result)
      );
    end else if ( DATA_WIDTH == 4) begin
      dot64_4bit #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCU_WIDTH     (ACCU_WIDTH),
        .VECTOR_LENGTH  (VECTOR_LENGTH),
        .MULT_LATENCY   (MULT_LATENCY),
        .INPUT_DELAY    (INPUT_DELAY),
        .TREE_DELAY     (TREE_DELAY),
        .OUT_DELAY      (OUT_DELAY),
        .ROW_NUM        (ROW_NUM)
      ) DOT64_4BIT (
        .clk	  (clk),
        .rst	  (rst),
        .ena	  (pe_dot_ena),
        .acc_reg  (pe_acc_in),
        .a_in  	  (pe_dot_a_in),
        .b_in  	  (pe_dot_b_in),
        .result   (pe_dot_result)
      );
    
    end else begin
`ifdef TERNARY // Perform the Ternary Computation
      dot32_8bit_ternary #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCU_WIDTH     (ACCU_WIDTH),
        .VECTOR_LENGTH  (VECTOR_LENGTH),
        .MULT_LATENCY   (MULT_LATENCY),
        .INPUT_DELAY    (INPUT_DELAY),
        .TREE_DELAY     (TREE_DELAY),
        .OUT_DELAY      (OUT_DELAY),
        .ROW_NUM        (ROW_NUM)
      ) DOT32_8BIT (
        .clk	  (clk),
        .rst	  (rst),
        .ena	  (pe_dot_ena),
        .acc_reg  (pe_acc_in),
        .a_in  	  (pe_dot_a_in),
        .b_in  	  (pe_dot_b_in),
        .result   (pe_dot_result)
      );
`else // By default do the non Tenary Computation
      dot32_8bit #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ACCU_WIDTH     (ACCU_WIDTH),
        .VECTOR_LENGTH  (VECTOR_LENGTH),
        .MULT_LATENCY   (MULT_LATENCY),
        .INPUT_DELAY    (INPUT_DELAY),
        .TREE_DELAY     (TREE_DELAY),
        .OUT_DELAY      (OUT_DELAY),
        .ROW_NUM        (ROW_NUM)
      ) DOT32_8BIT (
        .clk	  (clk),
        .rst	  (rst),
        .ena	  (pe_dot_ena),
        .acc_reg  (pe_acc_in),
        .a_in  	  (pe_dot_a_in),
        .b_in  	  (pe_dot_b_in),
        .result   (pe_dot_result)
      );
`endif
    end
  endgenerate

  // -------------------------
  // Feedback FIFO - DIM: 1024
  // -------------------------    
  dot16_result_fifo # (
    .DATA_WIDTH (ACCU_WIDTH)
  ) CACHE_FIFO (
    .data			    (pe_feed_wrdata),
    .wrreq			  (pe_feed_wrreq),
    .rdreq			  (pe_feed_rdreq),
    .clock			  (clk),
    .sclr         (rst),
    .q				    (pe_feed_rddata),
    .usedw			  (pe_feed_usedw),
    .full			    (pe_feed_full),
    .empty			  (pe_feed_empty),
    .almost_full	(pe_feed_almfull)
  );

  // ----------------------
  // Drain FIFO - DIM: 1024
  // ----------------------
  dot16_result_fifo # (
    .DATA_WIDTH (ACCU_WIDTH)
  ) DRAIN_FIFO (
    .data           (pe_drain_wrdata),
    .wrreq          (pe_drain_wrreq_comb),
    .rdreq          (pe_drain_rdreq),
    .clock          (clk),
    .sclr           (rst),
    .q              (pe_drain_rddata),
    .usedw          (pe_drain_usedw),
    .full           (pe_drain_full),
    .empty          (pe_drain_empty),
    .almost_full    (pe_drain_almfull)
  );

endmodule
