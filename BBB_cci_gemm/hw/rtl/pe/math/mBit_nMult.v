// (C) 2001-2016 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  mBit_nMult # (
		      DATA_WIDTH = 16,
		      LATENCY = 3
		      ) (
			 clk,
			 rst,
			 ena,
			 a,
			 b,
			 m
			 );
   input wire clk;
   input wire rst;
   input wire ena;

   input wire signed [DATA_WIDTH-1:0] a;
   input wire signed [DATA_WIDTH-1:0] b;

   output wire signed [DATA_WIDTH*2-1:0] m;

   wire signed [DATA_WIDTH*2-1:0] 	 res;
   
   /*
    assign res = a * (* multstyle = "logic" *) b;

    nBit_mLength_shiftRegister # (DATA_WIDTH*2, LATENCY) MULT_RES (clk, rst, ena, res, m);
    */

   reg [DATA_WIDTH-1:0] 		 zero_sum;
   always @(posedge clk) begin
      zero_sum <= 0;
   end

   lpm_mult        lpm_mult_component (
				       .aclr (rst),
				       .sclr (1'b0),
				       .clock (clk),
				       .dataa (a),
				       .datab (b),
				       .result (m),
				       .clken (ena),
				       .sum (zero_sum));
   defparam
     lpm_mult_component.lpm_hint = "DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
     lpm_mult_component.lpm_pipeline = LATENCY,
     lpm_mult_component.lpm_representation = "SIGNED",
     lpm_mult_component.lpm_type = "LPM_MULT",
     lpm_mult_component.lpm_widtha = DATA_WIDTH,
     lpm_mult_component.lpm_widthb = DATA_WIDTH,
     lpm_mult_component.lpm_widthp = DATA_WIDTH*2,
     lpm_mult_component.lpm_widths = DATA_WIDTH;

endmodule


