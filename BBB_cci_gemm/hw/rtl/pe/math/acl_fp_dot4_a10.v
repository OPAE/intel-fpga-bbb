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
    


module acl_fp_dot4_a10(running_sum, a1, b1, a2, b2, a3, b3, a4, b4, clock, enable, result);
// Latency 8, 4-element vector dot product.
input [31:0] running_sum;
input   [31:0] a1;
input   [31:0] a2;
input   [31:0] a3;
input   [31:0] a4;
input   [31:0] b1;
input   [31:0] b2;
input   [31:0] b3;
input   [31:0] b4;
input clock;
input enable;
output [31:0] result;

wire [31:0] ab;
wire [3:0] ab_flags;

// FP MAC wysiwyg
twentynm_fp_mac mac_fp_wys_01 (
    // inputs
    .accumulate(),
    .chainin_overflow(),
    .chainin_invalid(),
    .chainin_underflow(),
    .chainin_inexact(),
    .ax(running_sum),
    .ay(b1),
    .az(a1),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(ab_flags[3]),
    .chainout_invalid(ab_flags[2]),
    .chainout_underflow(ab_flags[1]),
    .chainout_inexact(ab_flags[0]),
    .resulta(),
    .chainout(ab)
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

reg [31:0] d1;
reg [31:0] d2;
reg [31:0] c1;
reg [31:0] c2;

always@(posedge clock)
begin
  if (enable)
  begin
    d1 <= b2;
    d2 <= d1;
    c1 <= a2;
    c2 <= c1;
  end
end

wire [31:0] rs_abcd;
wire [3:0] rs_abcd_flags;
twentynm_fp_mac mac_fp_wys_02 (
    // inputs
    .accumulate(),
    .chainin_overflow(ab_flags[3]),
    .chainin_invalid(ab_flags[2]),
    .chainin_underflow(ab_flags[1]),
    .chainin_inexact(ab_flags[0]),
    .ax(),
    .ay(c2),
    .az(d2),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ab),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(rs_abcd_flags[3]),
    .chainout_invalid(rs_abcd_flags[2]),
    .chainout_underflow(rs_abcd_flags[1]),
    .chainout_inexact(rs_abcd_flags[0]),
    .resulta(),
    .chainout(rs_abcd)
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

wire [31:0] ef;
wire [3:0] ef_flags;
wire [31:0] ef_p_gh;

twentynm_fp_mac mac_fp_wys_03 (
    // inputs
    .accumulate(),
    .chainin_overflow(rs_abcd_flags[3]),
    .chainin_invalid(rs_abcd_flags[2]),
    .chainin_underflow(rs_abcd_flags[1]),
    .chainin_inexact(rs_abcd_flags[0]),
    .ax(ef_p_gh),
    .ay(a3),
    .az(b3),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(rs_abcd),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(ef_flags[3]),
    .chainout_invalid(ef_flags[2]),
    .chainout_underflow(ef_flags[1]),
    .chainout_inexact(ef_flags[0]),
    .resulta(result),
    .chainout(ef)
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

twentynm_fp_mac mac_fp_wys_04 (
    // inputs
    .accumulate(),
    .chainin_overflow(ef_flags[3]),
    .chainin_invalid(ef_flags[2]),
    .chainin_underflow(ef_flags[1]),
    .chainin_inexact(ef_flags[0]),
    .ax(),
    .ay(a4_r),
    .az(b4_r),
    .clk({2'b00,clock}),
    .ena({2'b11,enable}),
    .aclr(2'b00),
    .chainin(ef),
    // outputs
    .overflow(),
    .invalid(),
    .underflow(),
    .inexact(),
    .chainout_overflow(),
    .chainout_invalid(),
    .chainout_underflow(),
    .chainout_inexact(),
    .resulta(ef_p_gh),
    .chainout()
);
defparam mac_fp_wys_04.operation_mode = "sp_mult_add"; 
defparam mac_fp_wys_04.use_chainin = "true"; 
defparam mac_fp_wys_04.adder_subtract = "false"; 
defparam mac_fp_wys_04.ax_clock = "none"; 
defparam mac_fp_wys_04.ay_clock = "0"; 
defparam mac_fp_wys_04.az_clock = "0"; 
defparam mac_fp_wys_04.output_clock = "0"; 
defparam mac_fp_wys_04.accumulate_clock = "none"; 
defparam mac_fp_wys_04.ax_chainin_pl_clock = "0"; 
defparam mac_fp_wys_04.accum_pipeline_clock = "none"; 
defparam mac_fp_wys_04.mult_pipeline_clock = "0"; 
defparam mac_fp_wys_04.adder_input_clock = "0"; 
defparam mac_fp_wys_04.accum_adder_clock = "none"; 

endmodule
