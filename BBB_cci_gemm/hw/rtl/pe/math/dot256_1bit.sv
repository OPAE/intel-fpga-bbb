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

// This module does dot(bin256, bin256)
// Output is from +256 to -256
//
// It is 7-stage pipeline, like so
// S1: bdot16
// S2: bdot16
// S3: bdot16
// S4: Reduce 16 to 8
// S5: Reduce 8  to 4
// S6: Reduce 4  to 2
// S7: Reduce 2  to 1
// S8: result = bdot + acc 
module bdot256 # ( 
		   DATA_WIDTH = 16,
		   ACCU_WIDTH = 16,
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

   localparam TOTAL_DELAY = (MULT_LATENCY + 1) + TREE_DELAY*2 + INPUT_DELAY;

   // --------------------------------------------------------------------------------------------------------

   input wire clk;
   input wire rst;
   input wire ena;

   input wire [31:0] acc_reg;
   input wire [DATA_WIDTH*VECTOR_LENGTH-1:0] a_in;
   input wire [DATA_WIDTH*VECTOR_LENGTH-1:0] b_in;

   output wire [31:0] 			     result;

   // -------------------------------------------------------------------------

   // -----------------------------------------
   // Unpack Vector a and b
   // Here we are unpacking 16 16bit values for both a and b and delaying by the appropriate amount.
   // -----------------------------------------

   wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	     a_w;
   wire [DATA_WIDTH*VECTOR_LENGTH-1:0] 	     b_w;

   nBit_mLength_shiftRegister # (DATA_WIDTH*VECTOR_LENGTH, INPUT_DELAY) A_W_Q (clk, rst, ena, a_in, a_w);
   nBit_mLength_shiftRegister # (DATA_WIDTH*VECTOR_LENGTH, INPUT_DELAY) B_W_Q (clk, rst, ena, b_in, b_w);

   // --------------------------------------------------------------------------------------------------------

   wire [31:0] 				     dot_res;

   wire [31:0] 				     acc_reg_q;
   wire [31:0] 				     res_q;

   // --------------------------------------------------------------------------------------------------------


   nBit_mLength_shiftRegister #(32, TOTAL_DELAY + OUT_DELAY) acc_reg1 (clk, rst, ena, acc_reg, acc_reg_q);

   // --------------------------------------------------------------------------------------------------------

   // 16 elements * 6bit/element
   wire [(16*6)-1:0] 			     bdot16_dout; 

   // --- S1-S3: 16 x bdot16 modules
   genvar 				     i;
   generate 
      for(i=0; i<16; i=i+1) begin : bdot16_cluster
	 bdot16 bdot16_inst (
			     .clk  (clk),
			     .rst  (rst),
			     .ena  (ena),
			     .din0 (a_w[(i*16)+15 : (i*16)]),
			     .din1 (b_w[(i*16)+15 : (i*16)]),
			     .dout (bdot16_dout[(i*6)+5 : (i*6)])
			     );
      end
   endgenerate

   // --- S4: reduce16to8
   wire [(8*7)-1:0] res8; // 7b x 8 sums, each from +32 to -32
   wire [(8*7)-1:0] res8_q; 
   genvar 	    j;
   generate
      for(j=0; j<8; j=j+1) begin : reduce16to8
	 assign res8[(j*7)+6 : (j*7)] = 
					{ bdot16_dout [(j*6)+5], // sign
					  bdot16_dout [(j*6)+5: (j*6)] } + 
					{ bdot16_dout [(j*6)+(8*6)+5], // sign
					  bdot16_dout [(j*6)+(8*6)+5: (j*6)+(8*6)] }; 
      end
   endgenerate
   nBit_mLength_shiftRegister #(8*7, 1) (clk, rst, ena, res8, res8_q);

   // --- S5: reduce8to4
   wire [(4*8)-1:0] res4; // 8b x 4 sums, each from +64 to -64
   wire [(4*8)-1:0] res4_q; 
   genvar 	    k;
   generate
      for(k=0; k<4; k=k+1) begin : reduce8to4
	 assign res4[(k*8)+7 : (k*8)] = 
					{ res8_q [(k*7)+6], // sign
					  res8_q [(k*7)+6: (k*7)] } + 
					{ res8_q [(k*7)+(4*7)+6], // sign
					  res8_q [(k*7)+(4*7)+6: (k*7)+(4*7)] };  
      end
   endgenerate

   nBit_mLength_shiftRegister # (4*8, 1)    (clk, rst, ena, res4, res4_q);

   // --- S6: reduce4to2
   wire [(2*9)-1:0] res2; // 9b x 2 sums, each from +128 to -128
   wire [(2*9)-1:0] res2_q; 

   assign res2[8:0]  = { res4_q[7] ,res4_q[7:0]   } +
                       { res4_q[15],res4_q[15:8]  } ;
   assign res2[17:9] = { res4_q[23],res4_q[23:16] } +
                       { res4_q[31],res4_q[31:24] } ;

   nBit_mLength_shiftRegister # (2*9, 1)   (clk, rst, ena, res2, res2_q);

   // --- S7: reduce2to1
   wire [9:0] 	    dot256_res;

   assign dot256_res =  { res2_q[8] , res2_q[8:0]  } +
			{ res2_q[17], res2_q[17:9] } ;

   nBit_mLength_shiftRegister # (32, 3 - INPUT_DELAY)   (clk, rst, ena, {{22{dot256_res[9]}}, dot256_res}, dot_res);



   // --------------------------------------------------------------------------------------------------------

   nBit_mLength_shiftRegister # ( 32, OUT_DELAY ) RES_Q (clk, rst, ena, dot_res, res_q);

   // --------------------------------------------------------------------------------------------------------

   assign result = res_q + acc_reg_q;

endmodule


// This module does dot(bin16,bin16)
// Output is from +16 to -16
//
// It is a 3-stage pipeline, like so:
// S1: xnor_res = ~(din0 ^ din1)
// S2: lt_out = lt(xnor_res) 
// S3: dout = reduce(lt_out)
module bdot16 (
	       clk,
	       rst,
	       ena,
	       din0,
	       din1,
	       dout
	       );

   input wire          clk;
   input wire          rst;
   input wire          ena;
   input wire [15:0]   din0;
   input wire [15:0]   din1;
   output wire [5:0]   dout; // +16 to -16

   wire [15:0] 	       xnor_res;
   wire [3:0] 	       lt0_out, lt1_out, lt2_out, lt3_out;
   wire [3:0] 	       lt0_out_q, lt1_out_q, lt2_out_q, lt3_out_q;

   // S1: xnor(din0, din1)
   nBit_mLength_shiftRegister #(16, 1) XNOR_RES_Q  (clk, rst, ena, din0 ~^ din1, xnor_res);

   // S2: LTs 
   bcnt4 bcnt4_0 (xnor_res[3:0],   lt0_out);
   bcnt4 bcnt4_1 (xnor_res[7:4],   lt1_out);
   bcnt4 bcnt4_2 (xnor_res[11:8],  lt2_out);
   bcnt4 bcnt4_3 (xnor_res[15:12], lt3_out);

   nBit_mLength_shiftRegister #(4, 1) BCNT4_0 (clk, rst, ena, lt0_out, lt0_out_q);
   nBit_mLength_shiftRegister #(4, 1) BCNT4_1 (clk, rst, ena, lt1_out, lt1_out_q);
   nBit_mLength_shiftRegister #(4, 1) BCNT4_2 (clk, rst, ena, lt2_out, lt2_out_q);
   nBit_mLength_shiftRegister #(4, 1) BCNT4_3 (clk, rst, ena, lt3_out, lt3_out_q);

   // S3: reduce4to1 
   assign dout =   { {2{lt0_out_q[3]}}, lt0_out_q } + 
                   { {2{lt1_out_q[3]}}, lt1_out_q } + 
                   { {2{lt2_out_q[3]}}, lt2_out_q } + 
                   { {2{lt3_out_q[3]}}, lt3_out_q } ; 

endmodule

// This module does
//   bcnt4 = one_cnt(bin4) - zero_cnt(bin4)
// 
// E.g., if input is 0001, there's 1 one, and 3 zeros
// So, bcnt4 = 1-3 = -2
module bcnt4 (
	      input [3:0]  din,
	      output [3:0] dout // -4 to 4
	      );
   // 0 is -1, 1 is 1
   // dout = one_count - zero_count
   assign dout = 
		 (din[3:0]==4'b0000) ? 4'b1100 : // 0000 = -4
		 (din[3:0]==4'b0001) ? 4'b1110 : // 0001 = -2
		 (din[3:0]==4'b0010) ? 4'b1110 : // 0010 = -2
		 (din[3:0]==4'b0011) ? 4'b0000 : // 0011 = 0

		 (din[3:0]==4'b0100) ? 4'b1110 : // 0100 = -2
		 (din[3:0]==4'b0101) ? 4'b0000 : // 0101 = 0
		 (din[3:0]==4'b0110) ? 4'b0000 : // 0110 = 0 
		 (din[3:0]==4'b0111) ? 4'b0010 : // 0111 = 2

		 (din[3:0]==4'b1000) ? 4'b1110 : // 1000 = -2
		 (din[3:0]==4'b1001) ? 4'b0000 : // 1001 = 0
		 (din[3:0]==4'b1010) ? 4'b0000 : // 1010 = 0
		 (din[3:0]==4'b1011) ? 4'b0010 : // 1011 = 2

		 (din[3:0]==4'b1100) ? 4'b0000 : // 1100 = 0
		 (din[3:0]==4'b1101) ? 4'b0010 : // 1101 = 2
		 (din[3:0]==4'b1110) ? 4'b0010 : // 1110 = 2
                 4'b0100 ; // 1111 = 4
endmodule


