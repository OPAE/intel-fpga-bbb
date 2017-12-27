//
// Copyright (c) 2017, Intel Corporation
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

module dot8_fp_top # ( 
		       DATA_WIDTH = 32,
		       ACCU_WIDTH = 32,
		       VECTOR_LENGTH = 8,
		       MULT_LATENCY = 3,
		       INPUT_DELAY = 1,
		       TREE_DELAY= 1,
		       OUT_DELAY = 1,
		       ROW_NUM = 1
		       )
   (
    clk,
    rst,
    ena,
    acc_reg,
    a_in,
    b_in,
    result
    );
   // --------------------------------------------------------------------------------------------------------
	
   
   
   input   wire                                    clk;
   input   wire                                    rst;
   input   wire                                    ena;

   input   wire [ACCU_WIDTH-1:0] 		   acc_reg;

   // Vector a Input
   input   wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	   a_in;

   // Vector b Input
   input   wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	   b_in;

   // Result Output
   output  wire [ACCU_WIDTH-1:0] 		   result;

   // --------------------------------------------------------------------------------------------------------

   // -----------------------------------------
   // Unpack Vector a and b
   // Here we are unpacking 16 16bit values for both a and b and delaying by the appropriate amount.
   // -----------------------------------------

   wire [DATA_WIDTH-1:0] 			   a_w [0:VECTOR_LENGTH-1];
   wire [DATA_WIDTH-1:0] 			   b_w [0:VECTOR_LENGTH-1];

   genvar 					   i;
   generate
      for (i=0; i<VECTOR_LENGTH; i=i+1) begin
	 if (i > 3) begin
		`ifdef CHAIN_8_DSP
			nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY ) A_W_Q (clk, rst, ena, a_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], a_w[i]);
			nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY ) B_W_Q (clk, rst, ena, b_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], b_w[i]);
		`else
			nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY + 8 ) A_W_Q (clk, rst, ena, a_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], a_w[i]);
			nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY + 8 ) B_W_Q (clk, rst, ena, b_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], b_w[i]);
		`endif
	 end
	 else begin
	    nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY) A_W_Q (clk, rst, ena, a_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], a_w[i]);
	    nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY) B_W_Q (clk, rst, ena, b_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], b_w[i]);
	 end
      end
   endgenerate

   // --------------------------------------------------------------------------------------------------------

   // The increase in bitwidth is to handle the overflow and underflow detection.
   `ifndef	CHAIN_8_DSP
		logic [31:0]			dot_4_first_result;
	`endif
   logic [31:0]			acc_reg_q;

   // --------------------------------------------------------------------------------------------------------


   nBit_mLength_shiftRegister #(ACCU_WIDTH, 0) acc_reg1 (clk, rst, ena, acc_reg, acc_reg_q);

   // --------------------------------------------------------------------------------------------------------
  
   // Do the DOT8
   // To DO:
   // Add dot_8 module with 8 DSP chained
   //Instantiate 2 Dot-4. Only the 1st dot-4 chain will get the running sum
 `ifdef CHAIN_8_DSP
	acl_fp_dot8_a10			DOT_8
	(
		.running_sum	(acc_reg_q),
	    .a1				(a_w[0]),
	    .b1				(b_w[0]),
	    .a2				(a_w[1]),
	    .b2				(b_w[1]),
	    .a3				(a_w[2]),
	    .b3				(b_w[2]),
	    .a4				(a_w[3]),
	    .b4				(b_w[3]),
	    .a5				(a_w[4]),
	    .b5				(b_w[4]),
	    .a6				(a_w[5]),
	    .b6				(b_w[5]),
	    .a7				(a_w[6]),
	    .b7				(b_w[6]),
	    .a8				(a_w[7]),
	    .b8				(b_w[7]),
		.clock			(clk),
		.enable			(ena),
		.result			(result)
	);
 
`else  
	acl_fp_dot4_a10			DOT_4_FIRST
     (
      .running_sum (acc_reg_q),
      .a1	   (a_w[0]),
      .b1	   (b_w[0]), 
      .a2	   (a_w[1]), 
      .b2	   (b_w[1]), 
      .a3	   (a_w[2]), 
      .b3	   (b_w[2]), 
      .a4	   (a_w[3]), 
      .b4	   (b_w[3]), 
      .clock	   (clk), 
      .enable	   (ena), 
      .result      (dot_4_first_result)
      );
   
   //Instantiate 2 Dot-4. Only the 1st dot-4 chain will get the running sum
   acl_fp_dot4_a10			DOT_4_SECOND
     (
      .running_sum (dot_4_first_result),
      .a1	   (a_w[4]),
      .b1	   (b_w[4]), 
      .a2	   (a_w[5]), 
      .b2	   (b_w[5]), 
      .a3	   (a_w[6]), 
      .b3	   (b_w[6]), 
      .a4	   (a_w[7]), 
      .b4	   (b_w[7]), 
      .clock	   (clk), 
      .enable	   (ena),
      .result      (result)
      );
`endif

endmodule
