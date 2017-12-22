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

module dot2_alm # (
		   DATA_WIDTH = 8,
		   MULT_LATENCY= 4,
		   TREE_DELAY = 1
		   ) (
		      clk,
		      rst,
		      ena,

		      a1_in,
		      a2_in,

		      b1_in,
		      b2_in,

		      res_out
		      );

   // -----------------------------------------------------

   input   wire                        clk;
   input   wire                        rst;
   input   wire                        ena;

   input   wire [DATA_WIDTH-1:0]       a1_in;
   input   wire [DATA_WIDTH-1:0]       a2_in;

   input   wire [DATA_WIDTH-1:0]       b1_in;
   input   wire [DATA_WIDTH-1:0]       b2_in;

   output  wire [DATA_WIDTH*2-1+1:0]   res_out;

   // -----------------------------------------------------

   // Input Pipeline
   wire [DATA_WIDTH-1:0] 	       a1_in_q;
   wire [DATA_WIDTH-1:0] 	       a2_in_q;
   wire [DATA_WIDTH-1:0] 	       b1_in_q;
   wire [DATA_WIDTH-1:0] 	       b2_in_q;


   // -----------------------------------------------------

`ifdef TERNARY // Perform the Ternary Computation
   // a1_in * a2_in
   wire [DATA_WIDTH-1:0] 	       a_res;

   // b1_in * b2_in
   wire [DATA_WIDTH-1:0] 	       b_res;
   
   nBit_mLength_shiftRegister # (DATA_WIDTH, MULT_LATENCY) (clk, rst, ena, $signed(b1_in), a_res); 
   nBit_mLength_shiftRegister # (DATA_WIDTH, MULT_LATENCY) (clk, rst, ena, $signed(b2_in), b_res); 
`else // By default do the non Tenary Computation
   
   // a1_in * a2_in
   wire [DATA_WIDTH*2-1:0] 	       a_res;

   // b1_in * b2_in
   wire [DATA_WIDTH*2-1:0] 	       b_res;
   
   // Use the 8Bit Vedic Multiplier
   mBit_nMult # (
		 .DATA_WIDTH  (DATA_WIDTH),
		 .LATENCY     (MULT_LATENCY)
		 ) DOT1_0 (
			   .clk    (clk),
			   .rst    (rst), 
			   .ena    (ena), 
			   .a      (a1_in), 
			   .b      (b1_in), 
			   .m      (a_res)
			   );

   mBit_nMult # (
		 .DATA_WIDTH      (DATA_WIDTH),
		 .LATENCY         (MULT_LATENCY)
		 ) DOT1_1 (
			   .clk    (clk),
			   .rst    (rst), 
			   .ena    (ena), 
			   .a      (a2_in), 
			   .b      (b2_in), 
			   .m      (b_res)
			   );
`endif

   // -----------------------------------------------------

   // Accumulate Pipeling -- Accumulate into 1 bit wider to account for overflow/underflow
   wire [DATA_WIDTH*2-1+1:0] 	       a_res_e;
   wire [DATA_WIDTH*2-1+1:0] 	       b_res_e;

   assign a_res_e = $signed(a_res);
   assign b_res_e = $signed(b_res);

   nBit_mLength_shiftRegister # (DATA_WIDTH*2 + 1, TREE_DELAY) dotRes (clk, rst, ena, a_res_e + b_res_e, res_out);

endmodule
