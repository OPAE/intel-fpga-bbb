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

module dot16_16bit # ( 
		       DATA_WIDTH = 16,
		       ACCU_WIDTH = 32,
		       VECTOR_LENGTH = 16,
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

   localparam TOTAL_DELAY = (MULT_LATENCY + 1) + TREE_DELAY*2 + INPUT_DELAY;

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
	 nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY) A_W_Q (clk, rst, ena, a_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], a_w[i]);
	 nBit_mLength_shiftRegister # (DATA_WIDTH, INPUT_DELAY) B_W_Q (clk, rst, ena, b_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i], b_w[i]);
      end
   endgenerate

   // --------------------------------------------------------------------------------------------------------

   // The increase in bitwidth is to handle the overflow and underflow detection.
   wire    [DATA_WIDTH*2-1+4:0]  dot_res;

   wire [ACCU_WIDTH-1:0] 	 acc_reg_q;
   wire [DATA_WIDTH*2-1+4:0] 	 res_q;

   // --------------------------------------------------------------------------------------------------------


   nBit_mLength_shiftRegister #(ACCU_WIDTH, TOTAL_DELAY + OUT_DELAY) acc_reg1 (clk, rst, ena, acc_reg, acc_reg_q);

   // --------------------------------------------------------------------------------------------------------

   // This is where we are doing the dot32, there are two cases:
   //  *  ROW_NUM < 10  : In this case we want to do a dot16 in dsps and dot16 in alms
   //  *  ROW_NUM >= 10 : In this case we want to do the dot32 in alms

   generate
      if (ROW_NUM > 9) begin
	 // ----------
	 // ALM DOT16 
	 // ----------
	 dot16_alm # ( DATA_WIDTH, MULT_LATENCY, TREE_DELAY) ALM_DOT16 (
									.clk        (clk),
									.rst        (rst),
									.ena        (ena),

									.a1_in      (a_w[0]),
									.a2_in      (a_w[1]),
									.a3_in      (a_w[2]),
									.a4_in      (a_w[3]),
									.a5_in      (a_w[4]),
									.a6_in      (a_w[5]),
									.a7_in      (a_w[6]),
									.a8_in      (a_w[7]),
									.a9_in      (a_w[8]),
									.a10_in     (a_w[9]),
									.a11_in     (a_w[10]),
									.a12_in     (a_w[11]),
									.a13_in     (a_w[12]),
									.a14_in     (a_w[13]),
									.a15_in     (a_w[14]),
									.a16_in     (a_w[15]),

									.b1_in      (b_w[0]),
									.b2_in      (b_w[1]),
									.b3_in      (b_w[2]),
									.b4_in      (b_w[3]),
									.b5_in      (b_w[4]),
									.b6_in      (b_w[5]),
									.b7_in      (b_w[6]),
									.b8_in      (b_w[7]),
									.b9_in      (b_w[8]),
									.b10_in     (b_w[9]),
									.b11_in     (b_w[10]),
									.b12_in     (b_w[11]),
									.b13_in     (b_w[12]),
									.b14_in     (b_w[13]),
									.b15_in     (b_w[14]),
									.b16_in     (b_w[15]),

									.res_out    (dot_res)
									);
      end else begin
	 dot16_dsp # ( DATA_WIDTH, TREE_DELAY) DSP_DOT16 (
							  .clk        (clk),
							  .rst        (rst),
							  .ena        (ena),

							  .a1_in      (a_w[0]),
							  .a2_in      (a_w[1]),
							  .a3_in      (a_w[2]),
							  .a4_in      (a_w[3]),
							  .a5_in      (a_w[4]),
							  .a6_in      (a_w[5]),
							  .a7_in      (a_w[6]),
							  .a8_in      (a_w[7]),
							  .a9_in      (a_w[8]),
							  .a10_in     (a_w[9]),
							  .a11_in     (a_w[10]),
							  .a12_in     (a_w[11]),
							  .a13_in     (a_w[12]),
							  .a14_in     (a_w[13]),
							  .a15_in     (a_w[14]),
							  .a16_in     (a_w[15]),

							  .b1_in      (b_w[0]),
							  .b2_in      (b_w[1]),
							  .b3_in      (b_w[2]),
							  .b4_in      (b_w[3]),
							  .b5_in      (b_w[4]),
							  .b6_in      (b_w[5]),
							  .b7_in      (b_w[6]),
							  .b8_in      (b_w[7]),
							  .b9_in      (b_w[8]),
							  .b10_in     (b_w[9]),
							  .b11_in     (b_w[10]),
							  .b12_in     (b_w[11]),
							  .b13_in     (b_w[12]),
							  .b14_in     (b_w[13]),
							  .b15_in     (b_w[14]),
							  .b16_in     (b_w[15]),

							  .res_out    (dot_res)
							  );
      end
   endgenerate

   // --------------------------------------------------------------------------------------------------------

   nBit_mLength_shiftRegister # ( DATA_WIDTH*2+4, OUT_DELAY ) RES_Q (clk, rst, ena, dot_res, res_q);

   // --------------------------------------------------------------------------------------------------------

   // This is where we need to handle the overflow and underflow
   wire [DATA_WIDTH*2-1+5:0] acc_result;
   wire [DATA_WIDTH*2-1+5:0] res_q_e;
   wire [DATA_WIDTH*2-1+5:0] acc_reg_q_e;
   assign res_q_e = $signed(res_q);
   assign acc_reg_q_e = $signed(acc_reg_q);

   assign acc_result = res_q_e + acc_reg_q_e;

   trunc # (DATA_WIDTH*2+5, ACCU_WIDTH) RES_TRUNC (acc_result, result);

   // --------------------------------------------------------------------------------------------------------

endmodule
