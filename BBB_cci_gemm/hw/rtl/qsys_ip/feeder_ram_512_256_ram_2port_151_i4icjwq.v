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
module  feeder_ram_512_256_ram_2port_151_i4icjwq # (
    SIZE = 512) (
    clock,
    data,
    rdaddress,
    rden,
    wraddress,
    wren,
    q);


    localparam WR_SIZE = SIZE;
    localparam RD_SIZE = SIZE*2;

    localparam WR_WIDTH = $clog2(WR_SIZE);
    localparam RD_WIDTH = $clog2(RD_SIZE);

    input    clock;
    input  [511:0]  data;
    input  [RD_WIDTH-1:0]  rdaddress;
    input    rden;
    input  [WR_WIDTH-1:0]  wraddress;
    input    wren;
    output [255:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri1     clock;
    tri1     rden;
    tri0     wren;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [255:0] sub_wire0;
    wire [255:0] q = sub_wire0[255:0];

    altera_syncram  altera_syncram_component (
                .address_a (wraddress),
                .address_b (rdaddress),
                .address2_a (1'b0),
                .address2_b (1'b0),
                .clock0 (clock),
                .data_a (data),
                .rden_b (rden),
                .wren_a (wren),
                .q_b (sub_wire0),
                .aclr0 (1'b0),
                .aclr1 (1'b0),
                .sclr  (1'b0),
                .addressstall_a (1'b0),
                .addressstall_b (1'b0),
                .byteena_a (1'b1),
                .byteena_b (1'b1),
                .clock1 (1'b1),
                .clocken0 (1'b1),
                .clocken1 (1'b1),
                .clocken2 (1'b1),
                .clocken3 (1'b1),
                .data_b ({256{1'b1}}),
                .eccencparity(8'h0),
                .eccencbypass(1'b0),
                .eccstatus (),
                .q_a (),
                .rden_a (1'b1),
                .wren_b (1'b0));
    defparam
        altera_syncram_component.address_aclr_b  = "NONE",
        altera_syncram_component.address_reg_b  = "CLOCK0",
        altera_syncram_component.clock_enable_input_a  = "BYPASS",
        altera_syncram_component.clock_enable_input_b  = "BYPASS",
        altera_syncram_component.clock_enable_output_b  = "BYPASS",
        altera_syncram_component.intended_device_family  = "Arria 10",
        altera_syncram_component.lpm_type  = "altera_syncram",
        altera_syncram_component.numwords_a  = WR_SIZE,
        altera_syncram_component.numwords_b  = RD_SIZE,
        altera_syncram_component.operation_mode  = "DUAL_PORT",
        altera_syncram_component.outdata_aclr_b  = "NONE",
        altera_syncram_component.outdata_reg_b  = "CLOCK0",
        altera_syncram_component.power_up_uninitialized  = "FALSE",
        altera_syncram_component.rdcontrol_reg_b  = "CLOCK0",
        altera_syncram_component.read_during_write_mode_mixed_ports  = "DONT_CARE",
        altera_syncram_component.widthad_a  = WR_WIDTH,
        altera_syncram_component.widthad_b  = RD_WIDTH,
        altera_syncram_component.width_a  = 512,
        altera_syncram_component.width_b  = 256,
        altera_syncram_component.width_byteena_a  = 1;


endmodule


