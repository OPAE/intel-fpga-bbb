// Copyright 2022 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

//
// Instantiate the hello world AFU from an afu_main() wrapper. This demonstrates
// the use of PIM transformations mixed with non-PIM AFUs.
//

`include "ofs_plat_if.vh"

// Merge HSSI macros from various platforms into a single AFU_MAIN_HAS_HSSI
`ifdef INCLUDE_HSSI_AND_NOT_CVL
  `define AFU_MAIN_HAS_HSSI 1
`endif
`ifdef PLATFORM_FPGA_FAMILY_S10
  `ifdef INCLUDE_HSSI
    `define AFU_MAIN_HAS_HSSI 1
  `endif
`endif
`define AFU_MAIN_HAS_HSSI 1

// ========================================================================
//
//  The ports in this implementation of afu_main() are complicated because
//  the code is expected to compile on multiple platforms, each with
//  subtle variations.
//
//  An implementation for a single platform should be simplified by
//  reducing the ports to only those of the target.
//
//  This example currently compiles on OFS for d5005 and n6000.
//
// ========================================================================

module afu_main 
#(
   parameter PG_NUM_PORTS    = 1,
   // PF/VF to which each port is mapped
   parameter pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t[PG_NUM_PORTS-1:0] PORT_PF_VF_INFO =
                {PG_NUM_PORTS{pcie_ss_hdr_pkg::ReqHdr_pf_vf_info_t'(0)}},

   parameter NUM_MEM_CH      = 0,
   parameter MAX_ETH_CH      = ofs_fim_eth_plat_if_pkg::MAX_NUM_ETH_CHANNELS
)(
   input  logic clk,
   input  logic clk_div2,
   input  logic clk_div4,
   input  logic uclk_usr,
   input  logic uclk_usr_div2,

   input  logic rst_n,
`ifdef PLATFORM_FPGA_FAMILY_S10
   input  logic port_rst_n [PG_NUM_PORTS-1:0],
   input  logic rst_n_100M,
`else
   input  logic [PG_NUM_PORTS-1:0] port_rst_n,
`endif

   // PCIe A ports are the standard TLP channels. All host responses
   // arrive on the RX A port.
   pcie_ss_axis_if.source        afu_axi_tx_a_if [PG_NUM_PORTS-1:0],
   pcie_ss_axis_if.sink          afu_axi_rx_a_if [PG_NUM_PORTS-1:0],
   // PCIe B ports are a second channel on which reads and interrupts
   // may be sent from the AFU. To improve throughput, reads on B may flow
   // around writes on A through PF/VF MUX trees until writes are committed
   // to the PCIe subsystem. AFUs may tie off the B port and send all
   // messages to A.
   pcie_ss_axis_if.source        afu_axi_tx_b_if [PG_NUM_PORTS-1:0],
   // Write commits are signaled here on the RX B port, indicating the
   // point at which the A and B channels become ordered within the FIM.
   // Commits are signaled after tlast of a write on TX A, after arbitration
   // with TX B within the FIM. The commit is a Cpl (without data),
   // returning the tag value from the write request. AFUs that do not
   // need local write commits may ignore this port, but must set
   // tready to 1.
   pcie_ss_axis_if.sink          afu_axi_rx_b_if [PG_NUM_PORTS-1:0],

   `ifdef INCLUDE_DDR4
      // Local memory
      ofs_fim_emif_axi_mm_if.user ext_mem_if [NUM_MEM_CH-1:0],
   `endif
   `ifdef PLATFORM_FPGA_FAMILY_S10
      // S10 uses AVMM for DDR
      ofs_fim_emif_avmm_if.user   ext_mem_if [NUM_MEM_CH-1:0],
   `endif

   `ifdef AFU_MAIN_HAS_HSSI
      ofs_fim_hssi_ss_tx_axis_if.client hssi_ss_st_tx [MAX_ETH_CH-1:0],
      ofs_fim_hssi_ss_rx_axis_if.client hssi_ss_st_rx [MAX_ETH_CH-1:0],
      ofs_fim_hssi_fc_if.client         hssi_fc [MAX_ETH_CH-1:0],
      input logic [MAX_ETH_CH-1:0]      i_hssi_clk_pll,
   `endif

    // S10 HSSI PTP interface
   `ifdef INCLUDE_PTP
      ofs_fim_hssi_ptp_tx_tod_if.client       hssi_ptp_tx_tod [MAX_ETH_CH-1:0],
      ofs_fim_hssi_ptp_rx_tod_if.client       hssi_ptp_rx_tod [MAX_ETH_CH-1:0],
      ofs_fim_hssi_ptp_tx_egrts_if.client     hssi_ptp_tx_egrts [MAX_ETH_CH-1:0],
      ofs_fim_hssi_ptp_rx_ingrts_if.client    hssi_ptp_rx_ingrts [MAX_ETH_CH-1:0],
   `endif

   // JTAG interface for PR region debug
   `ifdef PLATFORM_FPGA_FAMILY_S10
      // Old JTAG interface: just wires
      input  logic               sr2pr_tms,
      input  logic               sr2pr_tdi,
      output logic               pr2sr_tdo,
      input  logic               sr2pr_tck,
      input  logic               sr2pr_tckena
   `else
      ofs_jtag_if.sink           remote_stp_jtag_if
   `endif
);


    // ======================================================
    //
    // Merge soft reset and power on reset
    //
    // ======================================================

    logic rst_n_q1 = 1'b0;
    logic [PG_NUM_PORTS-1:0] port_rst_n_q1 = {PG_NUM_PORTS{1'b0}};
    logic [PG_NUM_PORTS-1:0] port_rst_n_q2 = {PG_NUM_PORTS{1'b0}};

    always @(posedge clk) begin
        rst_n_q1 <= rst_n;
    end

    for (genvar p = 0; p < PG_NUM_PORTS; p = p + 1) begin : reg_rst
        always @(posedge clk) begin
            port_rst_n_q1[p] <= port_rst_n[p];
            port_rst_n_q2[p] <= port_rst_n_q1[p] && rst_n_q1;
        end
    end


    // ======================================================
    //
    // Put a TLP-based hello world on port 0
    //
    // ======================================================

    //
    // This AFU does not use the PIM at all. It consumes and produces
    // PCIe SS encoded TLP streams.
    //

    hello_world_tlp
      #(
        .PF_ID(PORT_PF_VF_INFO[0].pf_num),
        .VF_ID(PORT_PF_VF_INFO[0].vf_num),
        .VF_ACTIVE(PORT_PF_VF_INFO[0].vf_active)
        )
      hello_world_tlp
       (
        .clk,
        .rst_n(port_rst_n_q2[0]),
        .o_tx_if(afu_axi_tx_a_if[0]),
        .o_tx_b_if(afu_axi_tx_b_if[0]),
        .i_rx_if(afu_axi_rx_a_if[0]),
        .i_rx_b_if(afu_axi_rx_b_if[0])
        );


    // ======================================================
    //
    // Put the PIM-based hello world on all other ports
    //
    // ======================================================

    //
    // Map the PIM-based hello world to all other available host channel
    // ports. PIM and non-PIM AFU instances can coexist independently within
    // the same compilation.
    //

    generate
        for (genvar p = 1; p < PG_NUM_PORTS; p = p + 1)
        begin : pim_afus
            ofs_plat_host_chan_axis_pcie_tlp_if
              #(
                .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
                )
              host_chan();

            // Map the PIM's host_chan interface to the FIM's PCIe SS interface.
            // This transforms the individual PCIe port's FIM interfaces to the
            // PIM's standard wrapper around the port's RX/TX interfaces.
            //
            // This is the same module that the PIM's default afu_main() would
            // use to set up a full PIM ofs_plat_afu() environment.
            map_fim_pcie_ss_to_pim_host_chan
              #(
                .INSTANCE_NUMBER(p),

                .PF_NUM(PORT_PF_VF_INFO[p].pf_num),
                .VF_NUM(PORT_PF_VF_INFO[p].vf_num),
                .VF_ACTIVE(PORT_PF_VF_INFO[p].vf_active)
                )
            map_host_chan
              (
               .clk(clk),
               .reset_n(port_rst_n_q2[p]),

               .pcie_ss_tx_a_st(afu_axi_tx_a_if[p]),
               .pcie_ss_tx_b_st(afu_axi_tx_b_if[p]),
               .pcie_ss_rx_a_st(afu_axi_rx_a_if[p]),
               .pcie_ss_rx_b_st(afu_axi_rx_b_if[p]),

               .port(host_chan)
               );


            // ****
            // Now that we have a standard PIM host_chan, the remainder of the code
            // is the same as the full ofs_plat_afu() version.
            // ****

            // Instance of the PIM's standard AXI memory interface. Now that we have
            // a standard PIM host_chan, the remainder of the code is the same as
            // the full ofs_plat_afu() version.
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

            // Map from TLP to a pair of AXI-MM interfaces
            ofs_plat_host_chan_as_axi_mem_with_mmio pim_map
               (
                .to_fiu(host_chan),
                .host_mem_to_afu(host_mem),
                .mmio_to_afu(mmio64_to_afu),

                // These ports would be used if the PIM is told to cross to
                // a different clock. In this example, native pClk is used.
                .afu_clk(),
                .afu_reset_n()
                );

            // AXI-MM based hello world
            hello_world_axi hello_afu
               (
                .mmio64_to_afu,
                .host_mem
                );
        end // block: pim_afus
    endgenerate


    // ======================================================
    //
    // Tie off unused local memory
    //
    // ======================================================

    for (genvar c=0; c<NUM_MEM_CH; c++) begin : mb
     `ifdef INCLUDE_DDR4
        assign ext_mem_if[c].awvalid = 1'b0;
        assign ext_mem_if[c].wvalid = 1'b0;
        assign ext_mem_if[c].arvalid = 1'b0;
        assign ext_mem_if[c].bready = 1'b1;
        assign ext_mem_if[c].rready = 1'b1;
     `endif

     `ifdef PLATFORM_FPGA_FAMILY_S10
        assign ext_mem_if[c].write = 1'b0;
        assign ext_mem_if[c].read = 1'b0;
     `endif
    end


    // ======================================================
    //
    // Tie off unused HSSI
    //
    // ======================================================

`ifdef AFU_MAIN_HAS_HSSI
    for (genvar c=0; c<MAX_ETH_CH; c++) begin : hssi
        assign hssi_ss_st_tx[c].tx = '0;
        assign hssi_fc[c].tx_pause = 0;
        assign hssi_fc[c].tx_pfc = 0;
    end
`endif


    // ======================================================
    //
    // Remote Debug JTAG IP instantiation
    //
    // ======================================================

    wire remote_stp_conf_reset = ~rst_n_q1;
    `include "ofs_fim_remote_stp_node.vh"

endmodule : afu_main
