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

// TODO: NEED MAJOR REFACTOR - NOT CURRENTLY USED

module dot16_2_8bit # ( 
			DATA_WIDTH = 8,
			VECTOR_LENGTH = 32
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

   localparam INPUT_PIPELINE = 1;
   localparam MULT_PIPELINE = 1;
   localparam ACC_PIPELINE = 1;

   localparam DSP_TOTAL_DELAY = 3 + ACC_PIPELINE*3;
   localparam ALM_TOTAL_DELAY = INPUT_PIPELINE + MULT_PIPELINE + ACC_PIPELINE*4;

   localparam ALM_RES_DELAY = 0;// DSP_TOTAL_DELAY - ALM_TOTAL_DELAY;
   localparam DSP_RES_DELAY = 0; // ALM_TOTAL_DELAY - DSP_TOTAL_DELAY;  
   
   localparam ACC_DELAY = 0;// ((DSP_TOTAL_DELAY > ALM_TOTAL_DELAY) ? DSP_TOTAL_DELAY : ALM_TOTAL_DELAY);

   // --------------------------------------------------------------------------------------------------------

   input   wire                                    clk;
   input   wire                                    rst;
   input   wire                                    ena;
   
   input   wire [31:0] 				   acc_reg;
   
   // Vector a Input
   input   wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	   a_in;

   // Vector b Input
   input   wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	   b_in;
   
   // Result Output
   output  wire [31:0] 				   result;
   
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
         assign a_w[i] = a_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i];
         assign b_w[i] = b_in[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i];
      end
   endgenerate

   // --------------------------------------------------------------------------------------------------------

   wire    [DATA_WIDTH*2-1:0]  alm_res;
   wire [DATA_WIDTH*2-1:0]     dsp_res;
   
   wire [DATA_WIDTH*2-1:0]     alm_res_q;
   wire [DATA_WIDTH*2-1:0]     dsp_res_q;
   
   wire [31:0] 		       acc_reg_q;
   wire [DATA_WIDTH*2-1:0]     res_q;

   // --------------------------------------------------------------------------------------------------------


   nBit_mLength_shiftRegister #(32, ACC_DELAY) acc_reg1 (clk, rst, ena, acc_reg, acc_reg_q);

   // --------------------------------------------------------------------------------------------------------

   dot16_alm # ( DATA_WIDTH, INPUT_PIPELINE, MULT_PIPELINE, ACC_PIPELINE) ALM_DOT16 (
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

										     .res_out    (alm_res)
										     );
   
   dot16_dsp # ( DATA_WIDTH, ACC_PIPELINE) DSP_DOT16 (
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

						      .res_out    (dsp_res)
						      );
   
   // --------------------------------------------------------------------------------------------------------
   
   // This is to ensure that the dsp and alm results are aligned, and also to add some extra pipeline stage
   // if needed. 
   nBit_mLength_shiftRegister # ( DATA_WIDTH*2, ALM_RES_DELAY ) ALM_RES_Q (clk, rst, ena, alm_res, alm_res_q);
   nBit_mLength_shiftRegister # ( DATA_WIDTH*2, DSP_RES_DELAY ) DSP_RES_Q (clk, rst, ena, dsp_res, dsp_res_q);
   
   // --------------------------------------------------------------------------------------------------------
   
   assign result[15:0]     = alm_res_q + acc_reg_q[15:0];
   assign result[31:16]    = dsp_res_q + acc_reg_q[31:16];

endmodule
