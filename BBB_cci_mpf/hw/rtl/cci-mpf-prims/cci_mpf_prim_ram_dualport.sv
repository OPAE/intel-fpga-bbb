//
// Copyright (c) 2015, Intel Corporation
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
//

//
// Dual port Block RAM.
//
// ***
// *** Separate clocks may be specified for the two ports only when the
// *** read during write mode is DONT_CARE.  Otherwise, clk0 is used and
// *** clk1 is ignored.
// ***
//

`include "cci_mpf_platform.vh"

module cci_mpf_prim_ram_dualport
  #(
    parameter N_ENTRIES = 32,
    parameter N_DATA_BITS = 64,
    // Number of extra stages of output register buffering to add
    parameter N_OUTPUT_REG_STAGES = 0,

    // Operation mode, either "BIDIR_DUAL_PORT" or "DUAL_PORT".
    // For DUAL_PORT configure only writes on port a and reads
    // on port b.  This mode can be useful since M20K RAM does
    // not allow 512 x 32 or 512 x 40 modes in bidirectional mode.
    parameter OPERATION_MODE = "BIDIR_DUAL_PORT",

    // Other options are "OLD_DATA" and "NEW_DATA".
    parameter READ_DURING_WRITE_MODE_MIXED_PORTS = "DONT_CARE",

    // Default clock for port 1. This value must be CLOCK0 when
    // READ_DURING_WRITE_MODE_MIXED_PORTS is something other than DONT_CARE.
    parameter PORT1_CLOCK = "CLOCK1",

    // Default returns new data for reads on same port as a write.
    // (No NBE read means return X in masked bytes, which we don't support
    // in this interface.)  Set to OLD_DATA to return the current value.
    parameter READ_DURING_WRITE_MODE_PORT_A = "NEW_DATA_NO_NBE_READ",
    parameter READ_DURING_WRITE_MODE_PORT_B = "NEW_DATA_NO_NBE_READ"
    )
   (
    input  logic clk0,
    input  logic [$clog2(N_ENTRIES)-1 : 0] addr0,
    input  logic wen0,
    input  logic [N_DATA_BITS-1 : 0] wdata0,
    output logic [N_DATA_BITS-1 : 0] rdata0,

    input  logic clk1,
    input  logic [$clog2(N_ENTRIES)-1 : 0] addr1,
    input  logic wen1,
    input  logic [N_DATA_BITS-1 : 0] wdata1,
    output logic [N_DATA_BITS-1 : 0] rdata1
    );


    logic [N_DATA_BITS-1 : 0] mem_rd0[0 : N_OUTPUT_REG_STAGES];
    assign rdata0 = mem_rd0[N_OUTPUT_REG_STAGES];

    logic [N_DATA_BITS-1 : 0] mem_rd1[0 : N_OUTPUT_REG_STAGES];
    assign rdata1 = mem_rd1[N_OUTPUT_REG_STAGES];

    // If the output data is registered then request a register stage in
    // the megafunction, giving it an opportunity to optimize the location.
    //
    localparam OUTDATA_REGISTERED0 = (N_OUTPUT_REG_STAGES == 0) ? "UNREGISTERED" :
                                                                  "CLOCK0";
    localparam OUTDATA_REGISTERED1 = (N_OUTPUT_REG_STAGES == 0) ? "UNREGISTERED" :
                                                                  PORT1_CLOCK;
    localparam OUTDATA_IDX = (N_OUTPUT_REG_STAGES == 0) ? 0 : 1;

`ifdef PLATFORM_INTENDED_DEVICE_FAMILY
    localparam PLATFORM_INTENDED_DEVICE_FAMILY = `PLATFORM_INTENDED_DEVICE_FAMILY;
`else
    localparam PLATFORM_INTENDED_DEVICE_FAMILY = "Stratix";
`endif

    initial
    begin
        assert ((READ_DURING_WRITE_MODE_MIXED_PORTS == "DONT_CARE") ||
                (PORT1_CLOCK == "CLOCK0")) else
            $fatal(2, "PORT1_CLOCK is %s but must be CLOCK0 when READ_DURING_WRITE_MODE_MIXED_PORTS is DONT_CARE", PORT1_CLOCK);
    end

    //
    // Starting with version 18, Quartus is really picky about whether the clock1
    // port is attached. We are forced to replicate the code, changing only the
    // binding of the clock1 port. The macro avoids actual source replication.
    //

    `define ALTSYNCRAM_DEF(CLK1_DEF) \
      altsyncram \
        #( \
          .intended_device_family(PLATFORM_INTENDED_DEVICE_FAMILY), \
          .operation_mode(OPERATION_MODE), \
          .width_a(N_DATA_BITS), \
          .widthad_a($clog2(N_ENTRIES)), \
          .numwords_a(N_ENTRIES), \
          .width_b(N_DATA_BITS), \
          .widthad_b($clog2(N_ENTRIES)), \
          .numwords_b(N_ENTRIES), \
          .outdata_reg_a(OUTDATA_REGISTERED0), \
          .rdcontrol_reg_b(PORT1_CLOCK), \
          .address_reg_b(PORT1_CLOCK), \
          .outdata_reg_b(OUTDATA_REGISTERED1), \
          .indata_reg_b(PORT1_CLOCK), \
          .wrcontrol_wraddress_reg_b(PORT1_CLOCK), \
          .byteena_reg_b(PORT1_CLOCK), \
          .read_during_write_mode_mixed_ports(READ_DURING_WRITE_MODE_MIXED_PORTS), \
          .read_during_write_mode_port_a(READ_DURING_WRITE_MODE_PORT_A), \
          .read_during_write_mode_port_b(READ_DURING_WRITE_MODE_PORT_B) \
          ) \
        data \
         ( \
          .clock0(clk0), \
          ``CLK1_DEF, \
          \
          .wren_a(wen0), \
          .address_a(addr0), \
          .data_a(wdata0), \
          .q_a(mem_rd0[OUTDATA_IDX]), \
           \
          .wren_b(wen1), \
          .address_b(addr1), \
          .data_b(wdata1), \
          .q_b(mem_rd1[OUTDATA_IDX]), \
           \
          // Legally unconnected ports -- get rid of lint errors \
          .rden_a(), \
          .rden_b(), \
          .clocken0(), \
          .clocken1(), \
          .clocken2(), \
          .clocken3(), \
          .aclr0(), \
          .aclr1(), \
          .byteena_a(), \
          .byteena_b(), \
          .addressstall_a(), \
          .addressstall_b(), \
          .eccstatus() \
          );

    generate
        if (PORT1_CLOCK == "CLOCK1")
        begin : c1
            `ALTSYNCRAM_DEF(.clock1(clk1))
        end
        else
        begin : c0
            `ALTSYNCRAM_DEF(.clock1())
        end
    endgenerate


    // Manage output buffering.
    genvar s;
    generate
        for (s = 1; s < N_OUTPUT_REG_STAGES; s = s + 1)
        begin: r
            always_ff @(posedge clk0)
            begin
                mem_rd0[s+1] <= mem_rd0[s];
            end

            always_ff @(posedge clk1)
            begin
                mem_rd1[s+1] <= mem_rd1[s];
            end
        end
    endgenerate

endmodule // cci_mpf_prim_ram_dualport


//
// Dual port RAM initialized with a constant on reset.
//
module cci_mpf_prim_ram_dualport_init
  #(
    parameter N_ENTRIES = 32,
    parameter N_DATA_BITS = 64,
    // Number of extra stages of output register buffering to add
    parameter N_OUTPUT_REG_STAGES = 0,

    // Operation mode, either "BIDIR_DUAL_PORT" or "DUAL_PORT".
    // For DUAL_PORT configure only writes on port a and reads
    // on port b.  This mode can be useful since M20K RAM does
    // not allow 512 x 32 or 512 x 40 modes in bidirectional mode.
    parameter OPERATION_MODE = "BIDIR_DUAL_PORT",

    // Other options are "OLD_DATA" and "NEW_DATA"
    parameter READ_DURING_WRITE_MODE_MIXED_PORTS = "DONT_CARE",

    // Default clock for port 1. This value must be CLOCK0 when
    // READ_DURING_WRITE_MODE_MIXED_PORTS is something other than DONT_CARE.
    parameter PORT1_CLOCK = "CLOCK1",

    // Default returns new data for reads on same port as a write.
    // (No NBE read means return X in masked bytes.)
    // Set to OLD_DATA to return the current value.
    parameter READ_DURING_WRITE_MODE_PORT_A = "NEW_DATA_NO_NBE_READ",
    parameter READ_DURING_WRITE_MODE_PORT_B = "NEW_DATA_NO_NBE_READ",

    parameter INIT_VALUE = N_DATA_BITS'(0)
    )
   (
    input  logic reset,
    // Goes high after initialization complete and stays high.
    output logic rdy,

    input  logic clk0,
    input  logic [$clog2(N_ENTRIES)-1 : 0] addr0,
    input  logic wen0,
    input  logic [N_DATA_BITS-1 : 0] wdata0,
    output logic [N_DATA_BITS-1 : 0] rdata0,

    input  logic clk1,
    input  logic [$clog2(N_ENTRIES)-1 : 0] addr1,
    input  logic wen1,
    input  logic [N_DATA_BITS-1 : 0] wdata1,
    output logic [N_DATA_BITS-1 : 0] rdata1
    );

    logic [$clog2(N_ENTRIES)-1 : 0] addr0_local;
    logic wen0_local;
    logic [N_DATA_BITS-1 : 0] wdata0_local;

    cci_mpf_prim_ram_dualport
      #(
        .N_ENTRIES(N_ENTRIES),
        .N_DATA_BITS(N_DATA_BITS),
        .N_OUTPUT_REG_STAGES(N_OUTPUT_REG_STAGES),
        .OPERATION_MODE(OPERATION_MODE),
        .READ_DURING_WRITE_MODE_MIXED_PORTS(READ_DURING_WRITE_MODE_MIXED_PORTS),
        .PORT1_CLOCK(PORT1_CLOCK),
        .READ_DURING_WRITE_MODE_PORT_A(READ_DURING_WRITE_MODE_PORT_A),
        .READ_DURING_WRITE_MODE_PORT_B(READ_DURING_WRITE_MODE_PORT_B)
        )
      ram
       (
        .clk0,
        .addr0(addr0_local),
        .wen0(wen0_local),
        .wdata0(wdata0_local),
        .rdata0,

        .clk1,
        .addr1,
        .wen1,
        .wdata1,
        .rdata1
        );


    //
    // Initialization loop
    //

    logic [$clog2(N_ENTRIES)-1 : 0] addr0_init;

    assign addr0_local = rdy ? addr0 : addr0_init;
    assign wen0_local = rdy ? wen0 : 1'b1;
    assign wdata0_local = rdy ? wdata0 : INIT_VALUE;

    always_ff @(posedge clk0)
    begin
        if (reset)
        begin
            rdy <= 1'b0;
            addr0_init <= 0;
        end
        else if (! rdy)
        begin
            addr0_init <= addr0_init + 1;
            rdy <= (addr0_init == (N_ENTRIES-1));
        end
    end

endmodule // cci_mpf_prim_ram_dualport_init
