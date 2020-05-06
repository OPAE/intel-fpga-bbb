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
// Instantiate the VTP service and page translation engine.
//

`include "mpf_vtp.vh"


module mpf_svc_vtp
  #(
    // When ENABLE_VTP is set to 0 no VTP service is instantiated and the
    // pt_fim and gen_csr_if ports are tied off.
    parameter ENABLE_VTP = 1,

    // Number of translation ports (vtp_ports below). Each port is a
    // pipeline with a private translation cache. Misses are serviced
    // by a shared TLB.
    parameter N_VTP_PORTS = 0,

    // Two implementations of physical to virtual page translation are
    // available in VTP. Pick mode "HARDWARE_WALKER" to walk the VTP
    // page table using AFU-generated memory reads. Pick mode
    // "SOFTWARE_SERVICE" to send translation requests to software.
    // In HARDWARE_WALKER mode it is the user code's responsibility to
    // pin all pages that may be touched by the FPGA. The SOFTWARE_SERVICE
    // mode may pin pages automatically on demand.
    parameter VTP_PT_MODE = 0,

    // Address mode. Normally, this is "IOADDR", indicating that the FPGA
    // DMA uses IO addresses from fpgaGetIOAddress(). When set to "HPA",
    // the FPGA uses host physical addresses.
    parameter string VTP_ADDR_MODE = "IOADDR",

    // NUMA domain restrictions. Normally this is 0, indicating no
    // restrictions. When non-zero it is a mask of NUMA domains the FPGA
    // can reach.
    parameter mpf_vtp_pkg::t_mpf_vtp_csr_numa_mask VTP_NUMA_MASK = 0,

    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Translations ports. Each port has a private L1 cache. Misses
    // are routed internally to a shared L2 TLB and, if necessary,
    // to a miss handler that queries the page table.
    mpf_vtp_port_if.to_master vtp_ports[N_VTP_PORTS],

    // FIM interface for host I/O
    mpf_vtp_pt_host_if.pt_walk pt_fim,

    // CSRs
    mpf_services_gen_csr_if.to_master gen_csr_if
    );

    genvar p;
    generate
        if (ENABLE_VTP)
        begin : v_to_p
            mpf_vtp_csrs_if vtp_csrs();
            always_comb
            begin
                vtp_csrs.vtp_out_mode = '0;
                vtp_csrs.vtp_out_mode.no_hw_page_walker = (VTP_PT_MODE != "HARDWARE_WALKER");
                vtp_csrs.vtp_out_mode.sw_translation_service = (VTP_PT_MODE == "SOFTWARE_SERVICE");
                vtp_csrs.vtp_out_mode.numa_mask_enabled = (VTP_NUMA_MASK != 0);

                vtp_csrs.vtp_out_mode.addr_mode = MPF_VTP_ADDR_MODE_IOADDR;
                if (VTP_ADDR_MODE == "HPA")
                    vtp_csrs.vtp_out_mode.addr_mode = MPF_VTP_ADDR_MODE_HPA;
                vtp_csrs.vtp_numa_mask = VTP_NUMA_MASK;
            end

            //
            // Translate generic CSR read/write requests coming in on gen_csr_if
            // into VTP-specific data structures.
            //
            mpf_vtp_csr
              #(
                .ENABLE_VTP(ENABLE_VTP)
                )
              csr_mgr
               (
                .clk,
                .reset,
                .gen_csr_if,
                .csrs(vtp_csrs),
                .events(vtp_csrs)
                );

            mpf_vtp_l2_if vtp_l2_ports[N_VTP_PORTS] ();
            mpf_vtp_l2_if vtp_svc_dedup[N_VTP_PORTS]();

            for (p = 0; p < N_VTP_PORTS; p = p + 1)
            begin : d
                //
                // Per-port private level 1 translation. This is the entry point
                // for new translation requests.
                //
                mpf_svc_vtp_l1
                  l1
                   (
                    .clk,
                    .reset,
                    .vtp_port(vtp_ports[p]),
                    .vtp_svc(vtp_l2_ports[p]),
                    .csrs(vtp_csrs)
                    );

                //
                // Deduplicate back-to-back L1 misses for the same page coming
                // from a single client. This is a filter between L1 and L2,
                // reducing the L2 traffic.
                //
                mpf_svc_vtp_l2_dedup
                  #(
                    .DEBUG_MESSAGES(DEBUG_MESSAGES)
                    )
                  dedup
                   (
                    .clk,
                    .reset,
                    .to_client(vtp_l2_ports[p]),
                    .to_server(vtp_svc_dedup[p])
                    );
            end

            //
            // Instantiate the shared VTP service (L2 and page table walker).
            //
            mpf_vtp_pt_walk_if pt_walk();

            mpf_svc_vtp_l2
              #(
                .N_VTP_PORTS(N_VTP_PORTS),
                .DEBUG_MESSAGES(DEBUG_MESSAGES)
                )
              vtp_l2
               (
                .clk,
                .reset,
                .vtp_svc(vtp_svc_dedup),
                .pt_walk,
                .csrs(vtp_csrs),
                .events(vtp_csrs)
                );

            if (VTP_PT_MODE == "HARDWARE_WALKER")
            begin
                mpf_svc_vtp_pt_walk
                  #(
                    .DEBUG_MESSAGES(DEBUG_MESSAGES)
                    )
                  walker
                   (
                    .clk,
                    .reset,
                    .pt_walk,
                    .pt_fim,
                    .csrs(vtp_csrs),
                    .events(vtp_csrs)
                );
            end
            else if (VTP_PT_MODE == "SOFTWARE_SERVICE")
            begin
                mpf_svc_vtp_pt_sw
                  #(
                    .DEBUG_MESSAGES(DEBUG_MESSAGES)
                    )
                  walker
                   (
                    .clk,
                    .reset,
                    .pt_walk,
                    .pt_fim,
                    .csrs(vtp_csrs),
                    .events(vtp_csrs)
                );
            end
            else
            begin
                initial
                begin
                    $fatal(2, "*** Illegal VTP_PT_MODE ***");
                end
            end
        end
        else
        begin : no_vtp
            // Tie off page table walker
            assign pt_fim.readEn = 1'b0;
            assign pt_fim.writeEn = 1'b0;

            // Tie off the external CSR interface. Index 0 is the DFH
            // and must be present in case it is still used in a CSR chain.
            // All other registers (especially the BBB UUID) are driven
            // to zero.
            always_ff @(posedge clk)
            begin
                gen_csr_if.rd_rsp_valid <= gen_csr_if.rd_req_en;

                if ((|(gen_csr_if.csr_req_idx)))
                    gen_csr_if.rd_data <= '0;
                else
                    gen_csr_if.rd_data <= gen_csr_if.dfh_value;
            end
        end
    endgenerate

endmodule // mpf_svc_vtp
