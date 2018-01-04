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

module dot64_4bit 
  # ( 
      DATA_WIDTH = 4,
      ACCU_WIDTH = 8,
      VECTOR_LENGTH = 64,
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

   wire    [DATA_WIDTH*2-1+4:0]  alm_res [0:3];

   wire [ACCU_WIDTH-1:0] 	 acc_reg_q;

   // --------------------------------------------------------------------------------------------------------


   nBit_mLength_shiftRegister #(ACCU_WIDTH, TOTAL_DELAY + OUT_DELAY) acc_reg1 (clk, rst, ena, acc_reg, acc_reg_q);

   // --------------------------------------------------------------------------------------------------------

   wire [DATA_WIDTH*2-1+5:0] 	 alm_res_e [0:3];
   wire [DATA_WIDTH*2-1+5:0] 	 res_q [0:1];

   // For the initial implementation we want to do everything in alms
   
   generate
      if (ROW_NUM > 9) begin
	 // ----------
	 // ALM DOT16 
	 // ----------
	 for (i = 0; i < 4; i = i + 1) begin
	    dot16_alm # ( DATA_WIDTH, MULT_LATENCY-1, TREE_DELAY) ALM0_DOT16 (
									      .clk        (clk),
									      .rst        (rst),
									      .ena        (ena),

									      .a1_in      (a_w[i*16 + 0]),
									      .a2_in      (a_w[i*16 + 1]),
									      .a3_in      (a_w[i*16 + 2]),
									      .a4_in      (a_w[i*16 + 3]),
									      .a5_in      (a_w[i*16 + 4]),
									      .a6_in      (a_w[i*16 + 5]),
									      .a7_in      (a_w[i*16 + 6]),
									      .a8_in      (a_w[i*16 + 7]),
									      .a9_in      (a_w[i*16 + 8]),
									      .a10_in     (a_w[i*16 + 9]),
									      .a11_in     (a_w[i*16 + 10]),
									      .a12_in     (a_w[i*16 + 11]),
									      .a13_in     (a_w[i*16 + 12]),
									      .a14_in     (a_w[i*16 + 13]),
									      .a15_in     (a_w[i*16 + 14]),
									      .a16_in     (a_w[i*16 + 15]),

									      .b1_in      (b_w[i*16 + 0]),
									      .b2_in      (b_w[i*16 + 1]),
									      .b3_in      (b_w[i*16 + 2]),
									      .b4_in      (b_w[i*16 + 3]),
									      .b5_in      (b_w[i*16 + 4]),
									      .b6_in      (b_w[i*16 + 5]),
									      .b7_in      (b_w[i*16 + 6]),
									      .b8_in      (b_w[i*16 + 7]),
									      .b9_in      (b_w[i*16 + 8]),
									      .b10_in     (b_w[i*16 + 9]),
									      .b11_in     (b_w[i*16 + 10]),
									      .b12_in     (b_w[i*16 + 11]),
									      .b13_in     (b_w[i*16 + 12]),
									      .b14_in     (b_w[i*16 + 13]),
									      .b15_in     (b_w[i*16 + 14]),
									      .b16_in     (b_w[i*16 + 15]),

									      .res_out    (alm_res[i])
									      );
	    
            assign alm_res_e[i] = $signed(alm_res[i]);
	 end // for (i = 0; i < 4; i = i + 1)
	 nBit_mLength_shiftRegister # ( DATA_WIDTH*2+5, OUT_DELAY ) DOT32_0Q (clk, rst, ena, alm_res_e[0] + alm_res_e[1], res_q[0]);
	 nBit_mLength_shiftRegister # ( DATA_WIDTH*2+5, OUT_DELAY ) DOT32_1Q (clk, rst, ena, alm_res_e[2] + alm_res_e[3], res_q[1]);
      end else begin // if (ROW_NUM > 9)
	 // ---------
	 // DPS DOT16 
	 // ---------
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

							  .res_out    (alm_res[0])
							  );
	 // ---------
	 // ALM DOT16 
	 // ---------
	 dot16_alm # ( DATA_WIDTH, MULT_LATENCY, TREE_DELAY) ALM_DOT16 (
									.clk        (clk),
									.rst        (rst),
									.ena        (ena),

									.a1_in      (a_w[16]),
									.a2_in      (a_w[17]),
									.a3_in      (a_w[18]),
									.a4_in      (a_w[19]),
									.a5_in      (a_w[20]),
									.a6_in      (a_w[21]),
									.a7_in      (a_w[22]),
									.a8_in      (a_w[23]),
									.a9_in      (a_w[24]),
									.a10_in     (a_w[25]),
									.a11_in     (a_w[26]),
									.a12_in     (a_w[27]),
									.a13_in     (a_w[28]),
									.a14_in     (a_w[29]),
									.a15_in     (a_w[30]),
									.a16_in     (a_w[31]),

									.b1_in      (b_w[16]),
									.b2_in      (b_w[17]),
									.b3_in      (b_w[18]),
									.b4_in      (b_w[19]),
									.b5_in      (b_w[20]),
									.b6_in      (b_w[21]),
									.b7_in      (b_w[22]),
									.b8_in      (b_w[23]),
									.b9_in      (b_w[24]),
									.b10_in     (b_w[25]),
									.b11_in     (b_w[26]),
									.b12_in     (b_w[27]),
									.b13_in     (b_w[28]),
									.b14_in     (b_w[29]),
									.b15_in     (b_w[30]),
									.b16_in     (b_w[31]),

									.res_out    (alm_res[1])
									);
	 
	 assign alm_res_e[0] = $signed(alm_res[0]);
	 assign alm_res_e[1] = $signed(alm_res[1]);
	 // ---------------
	 // ALM DOT16 3 - 4 
	 // ---------------
	 for (i = 2; i < 4; i = i + 1) begin
	    dot16_alm # ( DATA_WIDTH, MULT_LATENCY-1, TREE_DELAY) ALM0_DOT16 (
									      .clk        (clk),
									      .rst        (rst),
									      .ena        (ena),

									      .a1_in      (a_w[i*16 + 0]),
									      .a2_in      (a_w[i*16 + 1]),
									      .a3_in      (a_w[i*16 + 2]),
									      .a4_in      (a_w[i*16 + 3]),
									      .a5_in      (a_w[i*16 + 4]),
									      .a6_in      (a_w[i*16 + 5]),
									      .a7_in      (a_w[i*16 + 6]),
									      .a8_in      (a_w[i*16 + 7]),
									      .a9_in      (a_w[i*16 + 8]),
									      .a10_in     (a_w[i*16 + 9]),
									      .a11_in     (a_w[i*16 + 10]),
									      .a12_in     (a_w[i*16 + 11]),
									      .a13_in     (a_w[i*16 + 12]),
									      .a14_in     (a_w[i*16 + 13]),
									      .a15_in     (a_w[i*16 + 14]),
									      .a16_in     (a_w[i*16 + 15]),

									      .b1_in      (b_w[i*16 + 0]),
									      .b2_in      (b_w[i*16 + 1]),
									      .b3_in      (b_w[i*16 + 2]),
									      .b4_in      (b_w[i*16 + 3]),
									      .b5_in      (b_w[i*16 + 4]),
									      .b6_in      (b_w[i*16 + 5]),
									      .b7_in      (b_w[i*16 + 6]),
									      .b8_in      (b_w[i*16 + 7]),
									      .b9_in      (b_w[i*16 + 8]),
									      .b10_in     (b_w[i*16 + 9]),
									      .b11_in     (b_w[i*16 + 10]),
									      .b12_in     (b_w[i*16 + 11]),
									      .b13_in     (b_w[i*16 + 12]),
									      .b14_in     (b_w[i*16 + 13]),
									      .b15_in     (b_w[i*16 + 14]),
									      .b16_in     (b_w[i*16 + 15]),

									      .res_out    (alm_res[i])
									      );
            assign alm_res_e[i] = $signed(alm_res[i]);
	 end // for (i = 2; i < 4; i = i + 1)
	 
	 //nBit_mLength_shiftRegister # ( DATA_WIDTH*2+5, 0 ) DOT32_0Q (clk, rst, ena, alm_res_e[0] + alm_res_e[1], res_q[0]);
	assign res_q[0] = alm_res_e[0] + alm_res_e[1];
	nBit_mLength_shiftRegister # ( DATA_WIDTH*2+5, OUT_DELAY ) DOT32_1Q (clk, rst, ena, alm_res_e[2] + alm_res_e[3], res_q[1]);
      end // else: !if(ROW_NUM > 9)
   endgenerate


   // --------------------------------------------------------------------------------------------------------
   

   // --------------------------------------------------------------------------------------------------------
   
   wire    [DATA_WIDTH*2-1+6:0]  res_q_e [0:1];
   wire [DATA_WIDTH*2-1+6:0] 	 t_res_q;

   generate
      for (i = 0; i < 2; i = i + 1) begin    
	 assign res_q_e[i] = $signed(res_q[i]);
      end
   endgenerate
   
   nBit_mLength_shiftRegister # ( DATA_WIDTH*2+6, OUT_DELAY ) DOT64_Q (clk, rst, ena, res_q_e[0] + res_q_e[1], t_res_q);

   // --------------------------------------------------------------------------------------------------------

   // This is where we need to handle the overflow and underflow
   wire [ACCU_WIDTH-1+7:0] acc_result;
   wire [ACCU_WIDTH-1+7:0] t_res_q_e;
   wire [ACCU_WIDTH-1+7:0] acc_reg_q_e;
   assign t_res_q_e = $signed(t_res_q);
   assign acc_reg_q_e = $signed(acc_reg_q);

   assign acc_result = t_res_q_e + acc_reg_q_e;

   trunc # (ACCU_WIDTH+7, ACCU_WIDTH) RES_TRUNC (acc_result, result);

   // --------------------------------------------------------------------------------------------------------

endmodule
