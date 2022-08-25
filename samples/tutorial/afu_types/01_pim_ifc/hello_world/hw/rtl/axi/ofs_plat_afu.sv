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

//
// Top level PIM-based module.
//

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


    // Each interface names its associated clock and reset.
    logic clk;
    assign clk = host_mem.clk;
    logic reset_n;
    assign reset_n = host_mem.reset_n;


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


    // =========================================================================
    //
    //   Instantiate the hello world implementation
    //
    // =========================================================================

    hello_world_axi hello_afu
       (
        .mmio64_to_afu,
        .host_mem
        );

endmodule
