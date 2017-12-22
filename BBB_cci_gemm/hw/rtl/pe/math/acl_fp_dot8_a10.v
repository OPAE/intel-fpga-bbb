// (C) 1992-2014 Altera Corporation. All rights reserved.                         
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
    


module acl_fp_dot8_a10(running_sum, a1, a2, a3, a4, a5, a6, a7, a8,
                       b1,b2,b3,b4,b5,b6,b7,b8, clock, enable, result);
// Latency 11, 8-element vector dot product.
input [31:0]   running_sum;
input   [31:0] a1;
input   [31:0] b1;
input   [31:0] a2;
input   [31:0] b2;
input   [31:0] a3;
input   [31:0] b3;
input   [31:0] a4;
input   [31:0] b4;
input   [31:0] a5;
input   [31:0] b5;
input   [31:0] a6;
input   [31:0] b6;
input   [31:0] a7;
input   [31:0] b7;
input   [31:0] a8;
input   [31:0] b8;
input clock;
input enable;
output [31:0] result;

wire [31:0] ab11;
wire [3:0] ab11_flags;

// FP MAC wysiwyg
twentynm_fp_mac mac_fp_wys_01 ( //dsp1
    // inputs
    .accumulate(),
    .chainin_overflow(),
    .chainin_invalid(),
    .chainin_underflow(),
    .chainin_inexact(),
    .ax(running_sum),
    .ay(a1),
    .az(b1),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),//ab11_flags[3]),
    .chainout_invalid(),//ab11_flags[2]),
    .chainout_underflow(),//ab11_flags[1]),
    .chainout_inexact(),//ab11_flags[0]),
    .resulta(),
    .chainout(ab11)
);
defparam mac_fp_wys_01.operation_mode = "sp_mult_add"; 
defparam mac_fp_wys_01.use_chainin = "false"; 
defparam mac_fp_wys_01.adder_subtract = "false"; 
defparam mac_fp_wys_01.ax_clock = "0"; 
defparam mac_fp_wys_01.ay_clock = "0"; 
defparam mac_fp_wys_01.az_clock = "0"; 
defparam mac_fp_wys_01.output_clock = "0"; 
defparam mac_fp_wys_01.accumulate_clock = "none"; 
defparam mac_fp_wys_01.ax_chainin_pl_clock = "0"; 
defparam mac_fp_wys_01.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_01.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_01.adder_input_clock = "0"; 
defparam mac_fp_wys_01.accum_adder_clock = "none"; 

// FP MAC wysiwyg
// Pipeline datac and datad by 2 cycles.

reg [31:0] a21;
reg [31:0] a22;
reg [31:0] b21;
reg [31:0] b22;

always@(posedge clock)
begin
  if (enable)
  begin
    a21 <= a2;
    a22 <= a21;
    b21 <= b2;
    b22 <= b21;
  end
end

wire [31:0] ab22;
wire [3:0] ab22_flags;

twentynm_fp_mac mac_fp_wys_02 (
    // inputs
    .accumulate(),
    .chainin_overflow(),//ab11_flags[3]),
    .chainin_invalid(),//ab11_flags[2]),
    .chainin_underflow(),//ab11_flags[1]),
    .chainin_inexact(),//ab11_flags[0]),
    .ax(),
    .ay(a22),
    .az(b22),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ab11),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),//ab22_flags[3]),
    .chainout_invalid(),//ab22_flags[2]),
    .chainout_underflow(),//ab22_flags[1]),
    .chainout_inexact(),//ab22_flags[0]),
    .resulta(),
    .chainout(ab22)
);
defparam mac_fp_wys_02.operation_mode = "sp_mult_add"; 
defparam mac_fp_wys_02.use_chainin = "true"; 
defparam mac_fp_wys_02.adder_subtract = "false"; 
defparam mac_fp_wys_02.ax_clock = "none"; 
defparam mac_fp_wys_02.ay_clock = "0"; 
defparam mac_fp_wys_02.az_clock = "0"; 
defparam mac_fp_wys_02.output_clock = "0"; 
defparam mac_fp_wys_02.accumulate_clock = "none"; 
defparam mac_fp_wys_02.ax_chainin_pl_clock = "none"; 
defparam mac_fp_wys_02.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_02.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_02.adder_input_clock = "0"; 
defparam mac_fp_wys_02.accum_adder_clock = "none"; 

wire [31:0] ab33;
wire [3:0] ab33_flags;
wire [31:0] ab44;
wire [31:0] sum_of_four;

twentynm_fp_mac mac_fp_wys_03 (
    // inputs
    .accumulate(),
    .chainin_overflow(),//ab22_flags[3]),
    .chainin_invalid(),//ab22_flags[2]),
    .chainin_underflow(),//ab22_flags[1]),
    .chainin_inexact(),//ab22_flags[0]),
    .ax(ab44),
    .ay(a3),
    .az(b3),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ab22),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),//ab33_flags[3]),
    .chainout_invalid(),//ab33_flags[2]),
    .chainout_underflow(),//ab33_flags[1]),
    .chainout_inexact(),//ab33_flags[0]),
    .resulta(sum_of_four),
    .chainout(ab33)
);
defparam mac_fp_wys_03.operation_mode = "sp_vector2"; 
defparam mac_fp_wys_03.use_chainin = "true"; 
defparam mac_fp_wys_03.adder_subtract = "false"; 
defparam mac_fp_wys_03.ax_clock = "0"; 
defparam mac_fp_wys_03.ay_clock = "0"; 
defparam mac_fp_wys_03.az_clock = "0"; 
defparam mac_fp_wys_03.output_clock = "0"; 
defparam mac_fp_wys_03.accumulate_clock = "none"; 
defparam mac_fp_wys_03.ax_chainin_pl_clock = "none"; 
defparam mac_fp_wys_03.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_03.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_03.adder_input_clock = "0"; 
defparam mac_fp_wys_03.accum_adder_clock = "none"; 


reg [31:0] a4_r;
reg [31:0] b4_r;

always@(posedge clock)
begin
  if (enable)
  begin
    a4_r <= a4;
    b4_r <= b4;
  end
end

wire [31:0] sum_2;
wire [3:0] sum_2_flags;

twentynm_fp_mac mac_fp_wys_04 (
    // inputs
    .accumulate(),
    .chainin_overflow(),//ab33_flags[3]),
    .chainin_invalid(),//ab33_flags[2]),
    .chainin_underflow(),//ab33_flags[1]),
    .chainin_inexact(),//ab33_flags[0]),
    .ax(sum_of_four),
    .ay(a4_r),
    .az(b4_r),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ab33),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),//sum_2_flags[3]),
    .chainout_invalid(),//sum_2_flags[2]),
    .chainout_underflow(),//sum_2_flags[1]),
    .chainout_inexact(),//sum_2_flags[0]),
    .resulta(ab44),
    .chainout(sum_2)
);
defparam mac_fp_wys_04.operation_mode = "sp_vector1"; 
defparam mac_fp_wys_04.use_chainin = "true"; 
defparam mac_fp_wys_04.adder_subtract = "false"; 
defparam mac_fp_wys_04.ax_clock = "0"; 
defparam mac_fp_wys_04.ay_clock = "0"; 
defparam mac_fp_wys_04.az_clock = "0"; 
defparam mac_fp_wys_04.output_clock = "0"; 
defparam mac_fp_wys_04.accumulate_clock = "none"; 
defparam mac_fp_wys_04.ax_chainin_pl_clock = "0"; 
defparam mac_fp_wys_04.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_04.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_04.adder_input_clock = "0"; 
defparam mac_fp_wys_04.accum_adder_clock = "none"; 


wire [31:0] ab55;
wire [3:0] ab55_flags;

wire [31:0] sum_of_four2;

// FP MAC wysiwyg
twentynm_fp_mac mac_fp_wys_05 (
    // inputs
    .accumulate(),
    .chainin_overflow(),//sum_2_flags[3]),
    .chainin_invalid(),//sum_2_flags[2]),
    .chainin_underflow(),//sum_2_flags[1]),
    .chainin_inexact(),//sum_2_flags[0]),
    .ax(sum_of_four2),
    .ay(a5),
    .az(b5),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(sum_2),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),//ab55_flags[3]),
    .chainout_invalid(),//ab55_flags[2]),
    .chainout_underflow(),//ab55_flags[1]),
    .chainout_inexact(),//ab55_flags[0]),
    .resulta(result),
    .chainout(ab55)
);
defparam mac_fp_wys_05.operation_mode = "sp_vector2"; 
defparam mac_fp_wys_05.use_chainin = "true"; 
defparam mac_fp_wys_05.adder_subtract = "false"; 
defparam mac_fp_wys_05.ax_clock = "0"; 
defparam mac_fp_wys_05.ay_clock = "0"; 
defparam mac_fp_wys_05.az_clock = "0"; 
defparam mac_fp_wys_05.output_clock = "0"; 
defparam mac_fp_wys_05.accumulate_clock = "none"; 
defparam mac_fp_wys_05.ax_chainin_pl_clock = "none"; 
defparam mac_fp_wys_05.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_05.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_05.adder_input_clock = "0"; 
defparam mac_fp_wys_05.accum_adder_clock = "none"; 


wire [31:0] ab66;
wire [3:0] ab66_flags;
reg [31:0] a6_r;
reg [31:0] b6_r;

always@(posedge clock)
begin
   if (enable)
   begin
     a6_r <= a6;
     b6_r <= b6;
   end
end

twentynm_fp_mac mac_fp_wys_06 (
    // inputs
    .accumulate(),
    .chainin_overflow(),//ab55_flags[3]),
    .chainin_invalid(),//ab55_flags[2]),
    .chainin_underflow(),//ab55_flags[1]),
    .chainin_inexact(),//ab55_flags[0]),
    .ax(),
    .ay(a6_r),
    .az(b6_r),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ab55),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),//ab66_flags[3]),
    .chainout_invalid(),//ab66_flags[2]),
    .chainout_underflow(),//ab66_flags[1]),
    .chainout_inexact(),//ab66_flags[0]),
    .resulta(),
    .chainout(ab66)
);
defparam mac_fp_wys_06.operation_mode = "sp_mult_add"; 
defparam mac_fp_wys_06.use_chainin = "true"; 
defparam mac_fp_wys_06.adder_subtract = "false"; 
defparam mac_fp_wys_06.ax_clock = "none"; 
defparam mac_fp_wys_06.ay_clock = "0"; 
defparam mac_fp_wys_06.az_clock = "0"; 
defparam mac_fp_wys_06.output_clock = "0"; 
defparam mac_fp_wys_06.accumulate_clock = "none"; 
defparam mac_fp_wys_06.ax_chainin_pl_clock = "0"; 
defparam mac_fp_wys_06.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_06.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_06.adder_input_clock = "0"; 
defparam mac_fp_wys_06.accum_adder_clock = "none"; 

wire [31:0] ab88;
wire [31:0] ab77;
wire [31:0] ab77_flags;

twentynm_fp_mac mac_fp_wys_07 (
    // inputs
    .accumulate(),
    .chainin_overflow(),//ab66_flags[3]),
    .chainin_invalid(),//ab66_flags[2]),
    .chainin_underflow(),//ab66_flags[1]),
    .chainin_inexact(),//ab66_flags[0]),
    .ax(ab88),
    .ay(a7),
    .az(b7),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ab66),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),//ab77_flags[3]),
    .chainout_invalid(),//ab77_flags[2]),
    .chainout_underflow(),//ab77_flags[1]),
    .chainout_inexact(),//ab77_flags[0]),
    .resulta(sum_of_four2),
    .chainout(ab77)
);
defparam mac_fp_wys_07.operation_mode = "sp_vector2"; 
defparam mac_fp_wys_07.use_chainin = "true"; 
defparam mac_fp_wys_07.adder_subtract = "false"; 
defparam mac_fp_wys_07.ax_clock = "0"; 
defparam mac_fp_wys_07.ay_clock = "0"; 
defparam mac_fp_wys_07.az_clock = "0"; 
defparam mac_fp_wys_07.output_clock = "0"; 
defparam mac_fp_wys_07.accumulate_clock = "none"; 
defparam mac_fp_wys_07.ax_chainin_pl_clock = "0"; 
defparam mac_fp_wys_07.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_07.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_07.adder_input_clock = "0"; 
defparam mac_fp_wys_07.accum_adder_clock = "none"; 

reg [31:0] a8_r;
reg [31:0] b8_r;

always@(posedge clock)
begin
   if (enable)
   begin
      a8_r <= a8;
      b8_r <= b8;
   end
end

twentynm_fp_mac mac_fp_wys_08 (
    // inputs
    .accumulate(),
    .chainin_overflow(),//ab77_flags[3]),
    .chainin_invalid(),//ab77_flags[2]),
    .chainin_underflow(),//ab77_flags[1]),
    .chainin_inexact(),//ab77_flags[0]),
    .ax(),
    .ay(a8_r),
    .az(b8_r),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ab77),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),
    .chainout_invalid(),
    .chainout_underflow(),
    .chainout_inexact(),
    .resulta(ab88),
    .chainout()
);
defparam mac_fp_wys_08.operation_mode = "sp_mult_add"; 
defparam mac_fp_wys_08.use_chainin = "true"; 
defparam mac_fp_wys_08.adder_subtract = "false"; 
defparam mac_fp_wys_08.ax_clock = "none"; 
defparam mac_fp_wys_08.ay_clock = "0"; 
defparam mac_fp_wys_08.az_clock = "0"; 
defparam mac_fp_wys_08.output_clock = "0"; 
defparam mac_fp_wys_08.accumulate_clock = "none"; 
defparam mac_fp_wys_08.ax_chainin_pl_clock = "0"; 
defparam mac_fp_wys_08.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_08.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_08.adder_input_clock = "0"; 
defparam mac_fp_wys_08.accum_adder_clock = "none";
 
endmodule
