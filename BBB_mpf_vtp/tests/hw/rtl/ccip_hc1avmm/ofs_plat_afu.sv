//
// Copyright (c) 2019, Intel Corporation
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
// Export the primary host interface as CCI-P. If present, export a secondary
// group of host interfaces as Avalon ports.
//

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
    ofs_plat_host_ccip_if host_ccip_if();

    localparam NUM_CCIP_REG_STAGES =
        (ccip_cfg_pkg::SUGGESTED_TIMING_REG_STAGES != 0) ?
            ccip_cfg_pkg::SUGGESTED_TIMING_REG_STAGES : 1;

    // Use the platform-provided module to map the primary host interface
    // to CCI-P. The "primary" interface is the port that includes the
    // main OPAE-managed MMIO connection.
    ofs_plat_host_chan_as_ccip
      #(
        .ADD_TIMING_REG_STAGES(NUM_CCIP_REG_STAGES)
        )
      primary_ccip
       (
        .to_fiu(plat_ifc.host_chan.ports[0]),
        .to_afu(host_ccip_if),

        .afu_clk(),
        .afu_reset_n()
        );


    // ====================================================================
    //
    // If there is a second group of host channel ports map them too.
    //
    // ====================================================================

`ifndef OFS_PLAT_PARAM_HOST_CHAN_G1_NUM_PORTS

    // Dummy entry -- no group 1 ports on this platform
    localparam NUM_PORTS_G1 = 0;
    ofs_plat_avalon_mem_if
      #(
        `HOST_CHAN_AVALON_MEM_RDWR_PARAMS,
        .BURST_CNT_WIDTH(3)
        )
        host_mem_g1_to_afu[1]();

`else

    localparam NUM_PORTS_G1 = `OFS_PLAT_PARAM_HOST_CHAN_G1_NUM_PORTS;
    ofs_plat_avalon_mem_if
      #(
        `HOST_CHAN_G1_AVALON_MEM_PARAMS,
        .BURST_CNT_WIDTH(7),
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
        host_mem_g1_to_afu[NUM_PORTS_G1]();

    genvar p;
    generate
        for (p = 0; p < NUM_PORTS_G1; p = p + 1)
        begin : hc_g1
            ofs_plat_host_chan_g1_as_avalon_mem
              #(
                // Cross to the same clock domain as the CCI-P port
                .ADD_CLOCK_CROSSING(1)
                )
              avalon
               (
                .to_fiu(plat_ifc.host_chan_g1.ports[p]),
                .host_mem_to_afu(host_mem_g1_to_afu[p]),

                .afu_clk(host_ccip_if.clk),
                .afu_reset_n(host_ccip_if.reset_n)
                );
        end
    endgenerate

`endif // OFS_PLAT_PARAM_HOST_CHAN_G1_NUM_PORTS


    // ====================================================================
    //
    //  Tie off unused ports.
    //
    // ====================================================================

    ofs_plat_if_tie_off_unused
      #(
`ifdef OFS_PLAT_PARAM_HOST_CHAN_G1_NUM_PORTS
        // If host channel group 1 ports exist, they are all connected
        .HOST_CHAN_G1_IN_USE_MASK(-1),
`endif
        // Host channel group 0 port 0 is connected
        .HOST_CHAN_IN_USE_MASK(1)
        )
        tie_off(plat_ifc);


    // ====================================================================
    //
    //  Pass the constructed interfaces to the AFU.
    //
    // ====================================================================

    afu
     #(
`ifdef OFS_PLAT_PARAM_HOST_CHAN_G1_ADDRESS_SPACE
       .HOST_MEM_G1_ADDRESS_SPACE(`OFS_PLAT_PARAM_HOST_CHAN_G1_ADDRESS_SPACE),
`endif
       .NUM_PORTS_G1(NUM_PORTS_G1)
       )
     afu_impl
      (
       .host_ccip_if(host_ccip_if),
       .host_mem_g1_if(host_mem_g1_to_afu),
       .pClk(plat_ifc.clocks.pClk.clk),
       .pwrState(plat_ifc.pwrState)
       );

endmodule // ofs_plat_afu
