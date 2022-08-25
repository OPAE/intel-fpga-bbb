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
    //  Get an AXI-MM host channel connection from the platform.
    //
    // ====================================================================

    // Instance of the PIM's standard AXI memory interface.
    ofs_plat_axi_mem_if
      #(
        // The PIM provides parameters for configuring a standard host
        // memory DMA AXI memory interface.
        `HOST_CHAN_AXI_MEM_PARAMS,
        // PIM interfaces can be configured to log traffic during
        // simulation. In ASE, see work/log_ofs_plat_host_chan.tsv.
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
      host_mem();

    // Instance of the PIM's AXI memory lite interface, which will be
    // used to implement the AFU's CSR space.
    ofs_plat_axi_mem_lite_if
      #(
        // The AFU choses the data bus width of the interface and the
        // PIM adjusts the address space to match.
        `HOST_CHAN_AXI_MMIO_PARAMS(64),
        // Log MMIO traffic. (See the same parameter above on host_mem.)
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
        mmio64_to_afu();

    // Use the platform-provided module to map the primary host interface
    // to AXI-MM. The "primary" interface is the port that includes the
    // main OPAE-managed MMIO connection. This primary port is always
    // index 0 of plat_ifc.host_chan.ports, indepedent of the platform
    // and the native protocol of the host channel. This same module
    // name is available both on platforms that expose AXI-S PCIe TLP
    // streams to the AFU and on platforms that expose CCI-P.
    ofs_plat_host_chan_as_axi_mem_with_mmio primary_axi
       (
        .to_fiu(plat_ifc.host_chan.ports[0]),
        .host_mem_to_afu(host_mem),
        .mmio_to_afu(mmio64_to_afu),

        // These ports would be used if the PIM is told to cross to
        // a different clock. In this example, native pClk is used.
        .afu_clk(),
        .afu_reset_n()
        );

    // This example does not use DMA. Tie off the host_mem interface.
    assign host_mem.arvalid = 1'b0;
    assign host_mem.awvalid = 1'b0;
    assign host_mem.wvalid = 1'b0;
    assign host_mem.rready = 1'b1;
    assign host_mem.bready = 1'b1;


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

    ofs_plat_axi_mem_if
      #(
        `LOCAL_MEM_AXI_MEM_PARAMS_DEFAULT,
        // Log AXI transactions in simulation
        .LOG_CLASS(ofs_plat_log_pkg::LOCAL_MEM)
        )
      local_mem_to_afu[local_mem_cfg_pkg::LOCAL_MEM_NUM_BANKS]();

    // Map each bank individually
    genvar b;
    generate
        for (b = 0; b < local_mem_cfg_pkg::LOCAL_MEM_NUM_BANKS; b = b + 1)
        begin : mb
            ofs_plat_local_mem_as_axi_mem
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
                .afu_clk(mmio64_to_afu.clk),
                .afu_reset_n(mmio64_to_afu.reset_n)
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
        .clk_dst(mmio64_to_afu.clk),
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
       .mmio64_to_afu,
       .local_mem(local_mem_to_afu)
       );

endmodule // ofs_plat_afu
