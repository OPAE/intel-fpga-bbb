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

module dot4_alm # (
		   DATA_WIDTH = 8,
		   MULT_LATENCY = 4,
		   TREE_DELAY = 1
		   ) (
		      clk,
		      rst,
		      ena,

		      a1_in,
		      a2_in,
		      a3_in,
		      a4_in,

		      b1_in,
		      b2_in,
		      b3_in,
		      b4_in,

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

   input   wire [DATA_WIDTH-1:0]       b1_in;
   input   wire [DATA_WIDTH-1:0]       b2_in;
   input   wire [DATA_WIDTH-1:0]       b3_in;
   input   wire [DATA_WIDTH-1:0]       b4_in;

   output  wire [DATA_WIDTH*2-1+2:0]   res_out;

   // -----------------------------------------------------

   wire [DATA_WIDTH*2-1+1:0] 	       dot2_res [1:0];

   // -----------------------------------------------------

   // Perform 2 Dot2's 
   dot2_alm # ( DATA_WIDTH, MULT_LATENCY, TREE_DELAY) dot2_1 (clk, rst, ena, a1_in, a2_in, b1_in, b2_in, dot2_res[0]);

   dot2_alm # ( DATA_WIDTH, MULT_LATENCY, TREE_DELAY) dot2_2 (clk, rst, ena, a3_in, a4_in, b3_in, b4_in, dot2_res[1]);

   // -----------------------------------------------------

   wire [DATA_WIDTH*2-1+2:0] 	       dot2_res_e [1:0];
   assign dot2_res_e[0] = $signed(dot2_res[0]);
   assign dot2_res_e[1] = $signed(dot2_res[1]);

   // Accmulation Piplining
   nBit_mLength_shiftRegister # ( DATA_WIDTH*2+2, TREE_DELAY ) dot4_q (clk, rst, ena, dot2_res_e[0] + dot2_res_e[1], res_out);

endmodule
