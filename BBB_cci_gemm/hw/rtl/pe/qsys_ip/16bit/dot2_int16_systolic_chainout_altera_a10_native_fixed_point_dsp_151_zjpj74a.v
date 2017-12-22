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
module  dot2_int16_systolic_chainout_altera_a10_native_fixed_point_dsp_151_zjpj74a  (
            accumulate,
            aclr,
            ax,
            ay,
            bx,
            by,
            clk,
            ena,
            loadconst,
            negate,
            sub,
            chainout,
            resulta);

            input  accumulate;
            input [1:0] aclr;
            input [15:0] ax;
            input [15:0] ay;
            input [15:0] bx;
            input [15:0] by;
            input [2:0] clk;
            input [2:0] ena;
            input  loadconst;
            input  negate;
            input  sub;
            output [63:0] chainout;
            output [31:0] resulta;

            wire [63:0] sub_wire0;
            wire [31:0] sub_wire1;
            wire [63:0] chainout = sub_wire0[63:0];    
            wire [31:0] resulta = sub_wire1[31:0];    

            twentynm_mac        twentynm_mac_component (
                                        .accumulate (accumulate),
                                        .aclr (aclr),
                                        .ax (ax),
                                        .ay (ay),
                                        .bx (bx),
                                        .by (by),
                                        .clk (clk),
                                        .ena (ena),
                                        .loadconst (loadconst),
                                        .negate (negate),
                                        .sub (sub),
                                        .chainout (sub_wire0),
                                        .resulta (sub_wire1));
            defparam
                    twentynm_mac_component.ax_width = 16,
                    twentynm_mac_component.ay_scan_in_width = 16,
                    twentynm_mac_component.bx_width = 16,
                    twentynm_mac_component.by_width = 16,
                    twentynm_mac_component.operation_mode = "m18x18_systolic",
                    twentynm_mac_component.mode_sub_location = 0,
                    twentynm_mac_component.operand_source_max = "input",
                    twentynm_mac_component.operand_source_may = "input",
                    twentynm_mac_component.operand_source_mbx = "input",
                    twentynm_mac_component.operand_source_mby = "input",
                    twentynm_mac_component.signed_max = "true",
                    twentynm_mac_component.signed_may = "true",
                    twentynm_mac_component.signed_mbx = "true",
                    twentynm_mac_component.signed_mby = "true",
                    twentynm_mac_component.preadder_subtract_a = "false",
                    twentynm_mac_component.preadder_subtract_b = "false",
                    twentynm_mac_component.ay_use_scan_in = "false",
                    twentynm_mac_component.by_use_scan_in = "false",
                    twentynm_mac_component.delay_scan_out_ay = "false",
                    twentynm_mac_component.delay_scan_out_by = "false",
                    twentynm_mac_component.use_chainadder = "false",
                    twentynm_mac_component.enable_double_accum = "false",
                    twentynm_mac_component.load_const_value = 0,
                    twentynm_mac_component.coef_a_0 = 0,
                    twentynm_mac_component.coef_a_1 = 0,
                    twentynm_mac_component.coef_a_2 = 0,
                    twentynm_mac_component.coef_a_3 = 0,
                    twentynm_mac_component.coef_a_4 = 0,
                    twentynm_mac_component.coef_a_5 = 0,
                    twentynm_mac_component.coef_a_6 = 0,
                    twentynm_mac_component.coef_a_7 = 0,
                    twentynm_mac_component.coef_b_0 = 0,
                    twentynm_mac_component.coef_b_1 = 0,
                    twentynm_mac_component.coef_b_2 = 0,
                    twentynm_mac_component.coef_b_3 = 0,
                    twentynm_mac_component.coef_b_4 = 0,
                    twentynm_mac_component.coef_b_5 = 0,
                    twentynm_mac_component.coef_b_6 = 0,
                    twentynm_mac_component.coef_b_7 = 0,
                    twentynm_mac_component.ax_clock = "none",
                    twentynm_mac_component.ay_scan_in_clock = "none",
                    twentynm_mac_component.az_clock = "none",
                    twentynm_mac_component.bx_clock = "none",
                    twentynm_mac_component.by_clock = "none",
                    twentynm_mac_component.bz_clock = "none",
                    twentynm_mac_component.coef_sel_a_clock = "none",
                    twentynm_mac_component.coef_sel_b_clock = "none",
                    twentynm_mac_component.sub_clock = "none",
                    twentynm_mac_component.sub_pipeline_clock = "none",
                    twentynm_mac_component.negate_clock = "none",
                    twentynm_mac_component.negate_pipeline_clock = "none",
                    twentynm_mac_component.accumulate_clock = "none",
                    twentynm_mac_component.accum_pipeline_clock = "none",
                    twentynm_mac_component.load_const_clock = "none",
                    twentynm_mac_component.load_const_pipeline_clock = "none",
                    twentynm_mac_component.input_pipeline_clock = "0",
                    twentynm_mac_component.output_clock = "0",
                    twentynm_mac_component.scan_out_width = 18,
                    twentynm_mac_component.result_a_width = 33,
                    twentynm_mac_component.result_b_width = 32;


endmodule


