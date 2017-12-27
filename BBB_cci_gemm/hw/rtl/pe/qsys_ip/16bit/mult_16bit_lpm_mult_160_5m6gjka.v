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
module  mult_16bit_lpm_mult_160_5m6gjka  (
            aclr,
            clken,
            clock,
            dataa,
            datab,
            result);

            input  aclr;
            input  clock;
            input  clken;
            input [15:0] dataa;
            input [15:0] datab;
            output [31:0] result;

            wire [31:0] sub_wire0;
            wire [31:0] result = sub_wire0[31:0];    

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
                    lpm_mult_component.lpm_pipeline = 4,
                    lpm_mult_component.lpm_representation = "SIGNED",
                    lpm_mult_component.lpm_type = "LPM_MULT",
                    lpm_mult_component.lpm_widtha = 16,
                    lpm_mult_component.lpm_widthb = 16,
                    lpm_mult_component.lpm_widthp = 32;


endmodule


