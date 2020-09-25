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

module ofs_plat_afu
   (
    // All platform wires, wrapped in one interface.
    ofs_plat_if plat_ifc
    );

    // ====================================================================
    //
    //  Get a CCI-P port from the platform.
    //
    // ====================================================================

    // Instance of a CCI-P interface. The interface wraps usual CCI-P
    // sRx and sTx structs as well as the associated clock and reset.
    ofs_plat_host_ccip_if ccip_to_afu();

    // Use the platform-provided module to map the primary host interface
    // to CCI-P. The "primary" interface is the port that includes the
    // main OPAE-managed MMIO connection.
    ofs_plat_host_chan_as_ccip
      #(
        // When non-zero, add a clock crossing to move the AFU CCI-P
        // interface to the clock/reset pair passed in afu_clk/afu_reset.
        .ADD_CLOCK_CROSSING(1),

        // Request registered AFU-side signals so that we don't have to
        // register the CCI-P signals in the AFU.
        .ADD_TIMING_REG_STAGES(1)
        )
      primary_hc
       (
        .to_fiu(plat_ifc.host_chan.ports[0]),
        .to_afu(ccip_to_afu),

        // Pick the AFU's CCI-P clock. This is used only when the
        // ADD_CLOCK_CROSSING parameter is non-zero.
        .afu_clk(plat_ifc.clocks.uClk_usr.clk),
        .afu_reset_n(plat_ifc.clocks.uClk_usr.reset_n)
        );


    // ====================================================================
    //
    //  Get local memory from the platform.
    //
    // ====================================================================

    // The choice of interface type for local memory is independent of the
    // choice for the host channel. The host channel could be AXI-MM and
    // local memory Avalon. In fact, there is no requirement that all banks
    // of local memory be mapped to the same interface type. An AFU designer
    // who doesn't value his job could choose to map half the banks to
    // Avalon and half to AXI within a single AFU.

    ofs_plat_avalon_mem_if
      #(
        `LOCAL_MEM_AVALON_MEM_PARAMS_DEFAULT
        )
      local_mem_to_afu[local_mem_cfg_pkg::LOCAL_MEM_NUM_BANKS]();

    // Map each bank individually
    genvar b;
    generate
        for (b = 0; b < local_mem_cfg_pkg::LOCAL_MEM_NUM_BANKS; b = b + 1)
        begin : mb
            ofs_plat_local_mem_as_avalon_mem
              #(
                // Add a clock crossing from bank-specific clock.
                .ADD_CLOCK_CROSSING(1)
                )
              shim
               (
                .to_fiu(plat_ifc.local_mem.banks[b]),
                .to_afu(local_mem_to_afu[b]),

                // Map to the same clock as the AFU's host channel
                // interface. Whatever clock is chosen above in primary_hc
                // will be used here.
                .afu_clk(ccip_to_afu.clk),
                .afu_reset_n(ccip_to_afu.reset_n)
                );
        end
    endgenerate


    // ====================================================================
    //
    //  Map pwrState to the AFU clock domain
    //
    // ====================================================================

    t_ofs_plat_power_state afu_pwrState;

    ofs_plat_prim_clock_crossing_reg
      #(
        .WIDTH($bits(t_ofs_plat_power_state))
        )
      map_pwrState
       (
        .clk_src(plat_ifc.clocks.pClk.clk),
        .clk_dst(ccip_to_afu.clk),
        .r_in(plat_ifc.pwrState),
        .r_out(afu_pwrState)
        );


    // ====================================================================
    //
    //  Tie off unused ports.
    //
    // ====================================================================

    ofs_plat_if_tie_off_unused
      #(
        // Masks are bit masks, with bit 0 corresponding to port/bank zero.
        // Set a bit in the mask when a port is IN USE by the design.
        // This way, the AFU does not need to know about every available
        // device. By default, devices are tied off.
        .HOST_CHAN_IN_USE_MASK(1),
        // All banks are used
        .LOCAL_MEM_IN_USE_MASK(-1)
        )
        tie_off(plat_ifc);


    // ====================================================================
    //
    //  Pass the constructed interfaces to the AFU.
    //
    // ====================================================================

    afu_top
     #(
       .NUM_LOCAL_MEM_BANKS(local_mem_cfg_pkg::LOCAL_MEM_NUM_BANKS)
       )
     afu_top
      (
       .ccip_if(ccip_to_afu),
       .local_mem(local_mem_to_afu),
       .pwrState(afu_pwrState)
       );

endmodule // ofs_plat_afu
