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
module  mult_8bit_lpm_mult_160_lkaps7i  (
            aclr,
            clock,
            clken,
            dataa,
            datab,
            result);

            input  aclr;
            input  clock;
            input  clken;
            input [7:0] dataa;
            input [7:0] datab;
            output [15:0] result;

            wire [15:0] sub_wire0;
            wire [15:0] result = sub_wire0[15:0];    

            lpm_mult        lpm_mult_component (
                                        .aclr (aclr),
                                        .clock (clock),
                                        .dataa (dataa),
                                        .datab (datab),
                                        .result (sub_wire0),
                                        .clken (clken),
                                        .sum (1'b0));
            defparam
                    lpm_mult_component.lpm_hint = "DEDICATED_MULTIPLIER_CIRCUITRY=NO,MAXIMIZE_SPEED=9",
                    lpm_mult_component.lpm_pipeline = 3,
                    lpm_mult_component.lpm_representation = "SIGNED",
                    lpm_mult_component.lpm_type = "LPM_MULT",
                    lpm_mult_component.lpm_widtha = 8,
                    lpm_mult_component.lpm_widthb = 8,
                    lpm_mult_component.lpm_widthp = 16;


endmodule


