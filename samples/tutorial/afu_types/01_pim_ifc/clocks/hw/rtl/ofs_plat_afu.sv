//
// Copyright (c) 2020, Intel Corporation
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

`include "ofs_plat_if.vh"
`include "afu_json_info.vh"

//
// PIM clock crossing example.
//

module ofs_plat_afu
   (
    // All platform wires, wrapped in one interface.
    ofs_plat_if plat_ifc
    );

    // ====================================================================
    //
    //  This example uses Avalon memory host interfaces. It could just as
    //  easily have used AXI-MM or CCI-P. The parameters and clock ports
    //  passed to the PIM are identical for all variantions of the modules
    //  that map plat_ifc.host_chan.ports[0] to a memory interface.
    //
    // ====================================================================

    // Host memory. This AFU doesn't generate any host memory traffic.
    // The interface will be tied off.
    ofs_plat_avalon_mem_rdwr_if
      #(
        // The PIM provides parameters for configuring a standard host
        // memory DMA Avalon memory interface.
        `HOST_CHAN_AVALON_MEM_RDWR_PARAMS
        )
      host_mem();

    // Avalon interface for the AFU's CSR space.
    ofs_plat_avalon_mem_if
      #(
        // The AFU choses the data bus width of the interface and the
        // PIM adjusts the address space to match.
        `HOST_CHAN_AVALON_MMIO_PARAMS(64),
        // Log MMIO traffic. (See the same parameter above on host_mem.)
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
        mmio64_to_afu();

    // Instantiate the PIM module that maps a host channel to Avalon.
    ofs_plat_host_chan_as_avalon_mem_rdwr_with_mmio
      #(
        // Request a clock crossing. ADD_CLOCK_CROSSING defaults to 0.
        // When it is left at 0, host_mem_to_afu.clk and mmio_to_afu.clk
        // remain in the clock domain of to_fiu. When ADD_CLOCK_CROSSING
        // is non-zero, a clock crossing is instantiated that maps
        // host_mem_to_afu.clk and mmio_to_afu.clk to afu_clk.
        .ADD_CLOCK_CROSSING(1)
        )
      primary_avalon
       (
        .to_fiu(plat_ifc.host_chan.ports[0]),
        .host_mem_to_afu(host_mem),
        .mmio_to_afu(mmio64_to_afu),

        // Standard clocks are defined in
        // $OPAE_PLATFORM_ROOT/hw/lib/build/platform/ofs_plat_if/rtl/base_ifcs/clocks/ofs_plat_clocks.vh
        // and passed to the afu in plat_ifc.clocks. host_chan.ports[0]
        // is always bound to pClk. Aligned divide by 2 (pClkDiv2) and by
        // 4 (pClkDiv4) are provided, as is a user clock (uClk_usr) and
        // aligned divide by 2 uClk_usrDiv2. On most platforms the user
        // clock's frequency is configurable at run time from software.
        //
        // In this example, we bind mmio64_to_afu to uClk_usr. Any of the
        // above clocks could have been chosen.
        .afu_clk(plat_ifc.clocks.uClk_usr.clk),
        .afu_reset_n(plat_ifc.clocks.uClk_usr.reset_n)
        );


    // ====================================================================
    //
    //  Tie off unused ports.
    //
    // ====================================================================

    // The PIM ties off unused devices, controlled by the AFU indicating
    // which devices it is using. This way, an AFU must know only about
    // the devices it uses. Tie-offs are thus portable, with the PIM
    // managing devices unused by and unknown to the AFU.
    ofs_plat_if_tie_off_unused
      #(
        // Host channel group 0 port 0 is connected. The mask is a
        // bit vector of indices used by the AFU.
        .HOST_CHAN_IN_USE_MASK(1)
        )
        tie_off(plat_ifc);

    // No host memory DMA is required in this example.
    assign host_mem.rd_read = 1'b0;
    assign host_mem.wr_write = 1'b0;


    // ====================================================================
    //
    //  Instantiate a cycle counter for each clock. These will be
    //  mapped to CSRs.
    //
    // ====================================================================

    // uClk has been mapped to mmio64_to_afu.clk. We will use this clock
    // for MMIO transactions.
    logic clk;
    assign clk = mmio64_to_afu.clk;
    logic reset_n;
    assign reset_n = mmio64_to_afu.reset_n;

    logic reset_counter_n;
    logic enable_counter;

    localparam N_COUNTER_BITS = 40;

    logic [N_COUNTER_BITS-1:0] counter_max;
    logic [N_COUNTER_BITS-1:0] counter_pclk_value;
    logic [N_COUNTER_BITS-1:0] counter_pclk_div2_value;
    logic [N_COUNTER_BITS-1:0] counter_pclk_div4_value;
    logic [N_COUNTER_BITS-1:0] counter_clkusr_value;
    logic [N_COUNTER_BITS-1:0] counter_clkusr_div2_value;
    logic [N_COUNTER_BITS-1:0] counter_clk_value;

    logic max_value_reached;
    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_pclk_inst (
        .clk(clk),
        .count_clk(plat_ifc.clocks.pClk.clk),
        .count(counter_pclk_value),
        .max_value(counter_max),
        .max_value_reached(max_value_reached),
        .sync_reset_n(plat_ifc.clocks.pClk.reset_n & reset_counter_n),
        .enable(enable_counter)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_pclk_div2_inst (
        .clk(clk),
        .count_clk(plat_ifc.clocks.pClkDiv2.clk),
        .count(counter_pclk_div2_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset_n(plat_ifc.clocks.pClkDiv2.reset_n & reset_counter_n),
        .enable(enable_counter & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_pclk_div4_inst (
        .clk(clk),
        .count_clk(plat_ifc.clocks.pClkDiv4.clk),
        .count(counter_pclk_div4_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset_n(plat_ifc.clocks.pClkDiv4.reset_n & reset_counter_n),
        .enable(enable_counter & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_clkusr_inst (
        .clk(clk),
        .count_clk(plat_ifc.clocks.uClk_usr.clk),
        .count(counter_clkusr_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset_n(plat_ifc.clocks.uClk_usr.reset_n & reset_counter_n),
        .enable(enable_counter & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_clkusr_div2_inst (
        .clk(clk),
        .count_clk(plat_ifc.clocks.uClk_usrDiv2.clk),
        .count(counter_clkusr_div2_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset_n(plat_ifc.clocks.uClk_usrDiv2.reset_n & reset_counter_n),
        .enable(enable_counter & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_clk_inst (
        .clk(clk),
        .count_clk(clk),
        .count(counter_clk_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset_n(reset_n & reset_counter_n),
        .enable(enable_counter & ~max_value_reached)
    );


    // ====================================================================
    //
    //  AFU CSRs
    // 
    // ====================================================================

    // The AFU ID is a unique ID for a given program.  Here we generated
    // one with the "uuidgen" program and stored it in the AFU's JSON file.
    // ASE and synthesis setup scripts automatically invoke afu_json_mgr
    // to extract the UUID into afu_json_info.vh.
    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    // AFU is already ready for CSR requests
    assign mmio64_to_afu.waitrequest = 1'b0;

    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            mmio64_to_afu.readdatavalid <= 1'b0;
            mmio64_to_afu.writeresponsevalid <= 1'b0;

            mmio64_to_afu.response <= '0;
            mmio64_to_afu.writeresponse <= '0;

            reset_counter_n <= 1'b0;
            enable_counter <= 1'b0;
            counter_max <= '0;
        end
        else
        begin
            //
            // CSR writes
            //
            mmio64_to_afu.writeresponsevalid <= mmio64_to_afu.write;
            mmio64_to_afu.writeresponseuser <= mmio64_to_afu.user;

            if (mmio64_to_afu.write)
            begin
                case (mmio64_to_afu.address[4:0])
                    5'h11: reset_counter_n <= ~mmio64_to_afu.writedata[0];
                    5'h12: enable_counter <= mmio64_to_afu.writedata[0];
                    5'h13: counter_max <= mmio64_to_afu.writedata[N_COUNTER_BITS-1:0];
                endcase
            end

            //
            // CSR reads
            //
            mmio64_to_afu.readdatavalid <= mmio64_to_afu.read;
            mmio64_to_afu.readresponseuser <= mmio64_to_afu.user;

            if (mmio64_to_afu.read)
            begin
                case (mmio64_to_afu.address[4:0])
                    // AFU header
                    5'h00: mmio64_to_afu.readdata <=
                                   {
                                    4'b0001, // Feature type = AFU
                                    8'b0,    // reserved
                                    4'b0,    // afu minor revision = 0
                                    7'b0,    // reserved
                                    1'b1,    // end of DFH list = 1
                                    24'b0,   // next DFH offset = 0
                                    4'b0,    // afu major revision = 0
                                    12'b0    // feature ID = 0
                                    };
                    5'h01: mmio64_to_afu.readdata <= afu_id[63:0]; // afu id low
                    5'h02: mmio64_to_afu.readdata <= afu_id[127:64]; // afu id hi
                    5'h03: mmio64_to_afu.readdata <= 64'h0; // reserved
                    5'h04: mmio64_to_afu.readdata <= 64'h0; // reserved
                    5'h10: mmio64_to_afu.readdata <= 64'(max_value_reached); // status
                    5'h11: mmio64_to_afu.readdata <= { 63'b0, ~reset_counter_n };
                    5'h12: mmio64_to_afu.readdata <= { 63'b0, enable_counter };
                    5'h13: mmio64_to_afu.readdata <= 64'(counter_max);
                    5'h14: mmio64_to_afu.readdata <= 64'(counter_pclk_value);
                    5'h15: mmio64_to_afu.readdata <= 64'(counter_pclk_div2_value);
                    5'h16: mmio64_to_afu.readdata <= 64'(counter_pclk_div4_value);
                    5'h17: mmio64_to_afu.readdata <= 64'(counter_clkusr_value);
                    5'h18: mmio64_to_afu.readdata <= 64'(counter_clkusr_div2_value);
                    5'h19: mmio64_to_afu.readdata <= 64'(counter_clk_value);
                    // Frequency of pClk
                    5'h1a: mmio64_to_afu.readdata <= 64'(`OFS_PLAT_PARAM_CLOCKS_PCLK_FREQ);
                    default:
                           mmio64_to_afu.readdata <= 64'h0;
                endcase
            end
        end
    end

endmodule
