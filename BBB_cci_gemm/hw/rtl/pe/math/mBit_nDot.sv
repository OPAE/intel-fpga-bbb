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

module mBit_nDot # (
		    A_DATA_WIDTH = 16,
		    B_DATA_WIDTH = 16,
		    VECTOR_LENGTH = 16,
		    MULT_LATENCY = 3,
		    INPUT_DELAY = 1,
		    TREE_DELAY = 1,
		    OUT_DELAY = 1,
		    ROW_NUM = 1
		    ) (
		       clk,
		       rst,
		       ena,
		       acc_reg,
		       a_in,
		       b_in,
		       result
		       );

   // -----------------------------------------------------------------------------------
   
   // Depth of the Adder Tree 
   localparam TREE_DEPTH = $log2(VECTOR_LENGTH) + 1;

   // Number of Adds
   localparam NUM_ADDS = VECTOR_LENGTH*2 - 1;

   // Total Delay of the entire dot product datapath
   localparam TOTAL_DELAY = (MULT_LATENCY + 1) + TREE_DELAY*TREE_DEPTH + INPUT_DELAY;

   // For this architecture the widths of the inputs are going to be fix to the
   // largest out of A and B.
   localparam DATA_WIDTH = A_DATA_WIDTH > B_DATA_WIDTH ? A_DATA_WIDTH : B_DATA_WIDTH;

   // This is the output width before truncation
   localparam OUT_WIDTH = DATA_WIDTH*2 + TREE_DEPTH;
   
   // This is the output width after trunction 
   localparam TRUNC_WIDTH = DATA_WIDTH*2;
   
   // -----------------------------------------------------------------------------------


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

   // -----------------------------------------------------------------------------------
   
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
   
   // -----------------------------------------------------------------------------------
   
   nBit_mLength_shiftRegister #(OUT_WIDTH, TOTAL_DELAY + OUT_DELAY) acc_reg1 (clk, rst, ena, $signed(acc_reg), acc_reg_q);

   // -----------------------------------------------------------------------------------

   // This is where we do the Dot Product
   
   wire [DATA_WIDTH*2-1:0] mul_res [0:VECTOR_LENGTH-1];
   wire [OUT_WIDTH-1:0]    mul_res_s [0:VECTOR_LENGTH-1];
   
   wire [OUT_WIDTH-1:0]    add_res_in [0:NUM_ADDS-1];
   wire [OUT_WIDTH-1:0]    add_res_out [0:NUM_ADDS-1];

   // For all the Adds we want to Pipeline them by the TREE_DELAY for the
   // TREE_DEPTH
   generate
      for (i=0; i<NUM_ADDS; i=i+1) begin
	 nBit_mLength_shiftRegister # (
				       OUT_WIDTH, 
				       TREE_DELAY
				       ) ADD_RES_Q (
						    clk,
						    rst,
						    ena,
						    add_res_in,
						    add_res_out
						    );
      end
   endgenerate

   // This is the Mults
   generate
      for (i=0; i<VECTOR_LENGTH; i=i+1) begin
	 mBit_nMult # (
		       .DATA_WIDTH   (DATA_WIDTH), 
		       .LATENCY      (MULT_LATENCY)
		       ) DOT1 (
			       .clk  (clk),
			       .rst  (rst),
			       .ena  (ena),
			       .a    (a_w[i]),
			       .b    (b_w[i]),
			       .m    (mul_res[i])
			       );

	 assign mul_res_s[i] = $signed(mul_res[i]);
      end
   endgenerate

   // First Layer of the Adder Tree
   generate
      for (i=0; i<VECTOR_LENGTH/2; i=i+1) begin
	 assign add_res_in[i] = mul_res_s[i*2] + mul_res_s[i*2 + 1];
      end
   endgenerate

   // Connect up the other Adders in the Tree
   // We are going to iterate through each layer of the tree and connect up the
   // add_res_outs to the add_res_ins
   // Eg VECTOR_LENGTH = 8                              DEPTH
   // 0     1     2     3     4     5     6     7       
   // +     +     +     +     +     +     +     +       3
   //    8           9           10          11
   //    +           +           +           +          2
   //          12                      13
   //          +                       +                1
   //                       14
   //                       +                           0
   genvar j;
   generate
      for (j=1; j<TREE_DEPTH; j=j+1) begin
	 for (i=0; i< 1 << (TREE_DEPTH-j); i=i+1) begin
            assign add_res_in[j*(1 << (TREE_DEPTH -j) + i] = add_res_out[(j-1)*(1 << (TREE_DEPTH -j-1)) + (i*2)] + add_res_out[(j-1)*(1 << (TREE_DEPTH - j - 1)) + (i*2 + 1)];
			      end
			      end
			      endgenerate

			      // -----------------------------------------------------------------------------------
			      
			      // This is where we need to handle the overflow and underflow
			      wire [OUT_WIDTH-1:0] acc_result = add_res_out[NUM_ADDS-1] + acc_reg_q;

			      trunc # (OUT_WIDTH, 32) RES_TRUNC (acc_result, result);
			      
			      // -----------------------------------------------------------------------------------

			      endmodule
