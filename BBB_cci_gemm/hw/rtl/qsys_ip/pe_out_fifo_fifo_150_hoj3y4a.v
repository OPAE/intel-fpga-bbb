// (C) 2001-2015 Altera Corporation. All rights reserved.
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
module  pe_out_fifo_fifo_150_hoj3y4a  (
    clock,
    sclr,
    data,
    rdreq,
    wrreq,
    almost_full,
    empty,
    full,
    q,
    usedw);

    input    clock;
    input    sclr;
    input  [511:0]  data;
    input    rdreq;
    input    wrreq;
    output   almost_full;
    output   empty;
    output   full;
    output [511:0]  q;
    //output [3:0]  usedw;
    //output [4:0]  usedw;
    output [10:0]  usedw;
        
    wire  sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [511:0] sub_wire3;
    //wire [3:0] sub_wire4;
    //wire [4:0] sub_wire4;
    wire [5:0] sub_wire4;

    wire  almost_full = sub_wire0;
    wire  empty = sub_wire1;
    wire  full = sub_wire2;
    wire [511:0] q = sub_wire3[511:0];
    //wire [3:0] usedw = sub_wire4[3:0];
    //wire [4:0] usedw = sub_wire4[4:0];
    wire [5:0] usedw = sub_wire4[5:0];
    
    scfifo  scfifo_component (
                .clock (clock),
                .data (data),
                .rdreq (rdreq),
                .wrreq (wrreq),
                .almost_full (sub_wire0),
                .empty (sub_wire1),
                .full (sub_wire2),
                .q (sub_wire3),
                .usedw (sub_wire4),
                .aclr (sclr),
                .almost_empty (),
                .sclr ());

                /* Possible Fifo Settings
                 * AMF: 1000, 500, 250, 120, 60, 26, 10
                 * NWD: 1024, 512, 256, 128, 64, 32, 16
                 * WTH:   10,   9,   8,   7,  6,  5,  4
                 */
    defparam
        scfifo_component.add_ram_output_register  = "ON",
        scfifo_component.almost_full_value  = 40,
        scfifo_component.intended_device_family  = "Arria 10",
        scfifo_component.lpm_numwords  = 128,
        scfifo_component.lpm_showahead  = "OFF",
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_width  = 512,
        scfifo_component.lpm_widthu  = 7,
        scfifo_component.overflow_checking  = "ON",
        scfifo_component.underflow_checking  = "ON",
        scfifo_component.use_eab  = "ON";


endmodule


