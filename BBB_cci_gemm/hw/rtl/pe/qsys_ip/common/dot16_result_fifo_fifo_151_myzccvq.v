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
module  dot16_result_fifo_fifo_151_myzccvq  # (
  DATA_WIDTH = 32
) (
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
    input  sclr;
    input  [DATA_WIDTH-1:0]  data;
    input    rdreq;
    input    wrreq;
    output   almost_full;
    output   empty;
    output   full;
    output [DATA_WIDTH-1:0]  q;
    output [9:0]  usedw;

    wire  sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [DATA_WIDTH-1:0] sub_wire3;
    wire [9:0] sub_wire4;
    wire  almost_full = sub_wire0;
    wire  empty = sub_wire1;
    wire  full = sub_wire2;
    wire [DATA_WIDTH-1:0] q = sub_wire3[DATA_WIDTH-1:0];
    wire [9:0] usedw = sub_wire4[9:0];

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
                //.eccstatus (),
                .sclr ());
    defparam
        scfifo_component.add_ram_output_register  = "ON",
        scfifo_component.almost_full_value  = 1010,
        scfifo_component.intended_device_family  = "Arria 10",
        scfifo_component.lpm_hint  = "RAM_BLOCK_TYPE=M20K",
        scfifo_component.lpm_numwords  = 1024,
        scfifo_component.lpm_showahead  = "ON",
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_width  = DATA_WIDTH,
        scfifo_component.lpm_widthu  = 10,
        scfifo_component.overflow_checking  = "ON",
        scfifo_component.underflow_checking  = "ON",
        scfifo_component.use_eab  = "ON";


endmodule


