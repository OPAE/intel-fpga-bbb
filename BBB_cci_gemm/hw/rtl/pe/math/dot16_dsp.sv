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

module dot16_dsp # (
		    DATA_WIDTH = 8,
		    ACC_PIPELINE = 1
		    ) (
		       clk,
		       rst,
		       ena,

		       a1_in,
		       a2_in,
		       a3_in,
		       a4_in,
		       a5_in,
		       a6_in,
		       a7_in,
		       a8_in,
		       a9_in,
		       a10_in,
		       a11_in,
		       a12_in,
		       a13_in,
		       a14_in,
		       a15_in,
		       a16_in,

		       b1_in,
		       b2_in,
		       b3_in,
		       b4_in,
		       b5_in,
		       b6_in,
		       b7_in,
		       b8_in,
		       b9_in,
		       b10_in,
		       b11_in,
		       b12_in,
		       b13_in,
		       b14_in,
		       b15_in,
		       b16_in,

		       res_out
		       );

   // -----------------------------------------------------

   input   wire                        clk;
   input   wire                        rst;
   input   wire                        ena;

   input   wire [DATA_WIDTH-1:0]       a1_in;
   input   wire [DATA_WIDTH-1:0]       a2_in;
   input   wire [DATA_WIDTH-1:0]       a3_in;
   input   wire [DATA_WIDTH-1:0]       a4_in;
   input   wire [DATA_WIDTH-1:0]       a5_in;
   input   wire [DATA_WIDTH-1:0]       a6_in;
   input   wire [DATA_WIDTH-1:0]       a7_in;
   input   wire [DATA_WIDTH-1:0]       a8_in;
   input   wire [DATA_WIDTH-1:0]       a9_in;
   input   wire [DATA_WIDTH-1:0]       a10_in;
   input   wire [DATA_WIDTH-1:0]       a11_in;
   input   wire [DATA_WIDTH-1:0]       a12_in;
   input   wire [DATA_WIDTH-1:0]       a13_in;
   input   wire [DATA_WIDTH-1:0]       a14_in;
   input   wire [DATA_WIDTH-1:0]       a15_in;
   input   wire [DATA_WIDTH-1:0]       a16_in;

   input   wire [DATA_WIDTH-1:0]       b1_in;
   input   wire [DATA_WIDTH-1:0]       b2_in;
   input   wire [DATA_WIDTH-1:0]       b3_in;
   input   wire [DATA_WIDTH-1:0]       b4_in;
   input   wire [DATA_WIDTH-1:0]       b5_in;
   input   wire [DATA_WIDTH-1:0]       b6_in;
   input   wire [DATA_WIDTH-1:0]       b7_in;
   input   wire [DATA_WIDTH-1:0]       b8_in;
   input   wire [DATA_WIDTH-1:0]       b9_in;
   input   wire [DATA_WIDTH-1:0]       b10_in;
   input   wire [DATA_WIDTH-1:0]       b11_in;
   input   wire [DATA_WIDTH-1:0]       b12_in;
   input   wire [DATA_WIDTH-1:0]       b13_in;
   input   wire [DATA_WIDTH-1:0]       b14_in;
   input   wire [DATA_WIDTH-1:0]       b15_in;
   input   wire [DATA_WIDTH-1:0]       b16_in;

   output  wire [DATA_WIDTH*2-1+4:0]   res_out;

   // -----------------------------------------------------

   wire [DATA_WIDTH*2-1+3:0] 	       dot8_res [1:0];

   // -----------------------------------------------------

   // Perform 2 Dot8's 
   dot8_dsp # ( DATA_WIDTH, ACC_PIPELINE) dot8_1 (clk, rst, ena, a1_in, a2_in, a3_in, a4_in, a5_in, a6_in, a7_in, a8_in, b1_in, b2_in, b3_in, b4_in, b5_in, b6_in, b7_in, b8_in, dot8_res[0]);

   dot8_dsp # ( DATA_WIDTH, ACC_PIPELINE) dot8_2 (clk, rst, ena, a9_in, a10_in, a11_in, a12_in, a13_in, a14_in, a15_in, a16_in, b9_in, b10_in, b11_in, b12_in, b13_in, b14_in, b15_in, b16_in, dot8_res[1]);

   // -----------------------------------------------------

   wire [DATA_WIDTH*2-1+4:0] 	       dot8_res_e [1:0];
   assign dot8_res_e[0] = $signed(dot8_res[0]);
   assign dot8_res_e[1] = $signed(dot8_res[1]);

   // Accmulation Piplining
   nBit_mLength_shiftRegister # ( DATA_WIDTH*2+4, ACC_PIPELINE ) dot16_q (clk, rst, ena, dot8_res_e[0] + dot8_res_e[1], res_out);

endmodule
