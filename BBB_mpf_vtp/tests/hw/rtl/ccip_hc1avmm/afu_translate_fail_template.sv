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

//
// These modules are rudimentary VTP address translation failure handlers.
// They split off requests with failures to a separate interface. In the
// example, failures are printed (in simulation), noted in CSRs and then
// dropped on the floor. A real implementation would either expect there
// to be no failures, in which which case this code is unnecessary, or
// implement proper recovery mechanisms.
//

`include "ofs_plat_if.vh"
`include "cci_mpf_if.vh"


//
// Dummy Avalon sink implementation to handle failed translations.
// Information about failures is noted but requests are dropped.
// There are no responses generated.
//
module dummy_failed_g1_sinks
  #(
    parameter NUM_PORTS_G1 = 0
    )
   (
    ofs_plat_avalon_mem_if.to_source host_mem_g1_failed_if[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1],

    // Record recent failures that will be exported as CSRs
    output logic [63:0] csr_g1_rd_vtp_fail_va,
    output logic [15:0] csr_g1_rd_vtp_fail_cnt,
    output logic [63:0] csr_g1_wr_vtp_fail_va,
    output logic [15:0] csr_g1_wr_vtp_fail_cnt
    );

    logic clk;
    assign clk = host_mem_g1_failed_if[0].clk;
    logic reset_n;
    assign reset_n = host_mem_g1_failed_if[0].reset_n;

    localparam BURST_CNT_WIDTH = host_mem_g1_failed_if[0].BURST_CNT_WIDTH_;

    // Collect failures
    logic [63:0] g1_rd_vtp_failed_addr[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1];
    logic [NUM_PORTS_G1-1 : 0] g1_rd_vtp_failed;
    logic [63:0] g1_wr_vtp_failed_addr[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1];
    logic [NUM_PORTS_G1-1 : 0] g1_wr_vtp_failed;

    genvar p;
    generate
        for (p = 0; p < NUM_PORTS_G1; p = p + 1)
        begin : g1
            // Since the example just drops failed requests on host_mem_g1_failed,
            // tie off the response wires.
            always_comb
            begin
                `OFS_PLAT_AVALON_MEM_IF_INIT_SINK_COMB(host_mem_g1_failed_if[p]);
            end

            // Track SOP
            logic wr_sop;
            ofs_plat_prim_burstcount1_sop_tracker
              #(
                .BURST_CNT_WIDTH(BURST_CNT_WIDTH)
                )
              sop
               (
                .clk,
                .reset_n,
                .flit_valid(host_mem_g1_failed_if[p].write && ! host_mem_g1_failed_if[p].waitrequest),
                .burstcount(host_mem_g1_failed_if[p].burstcount),
                .sop(wr_sop),
                .eop()
                );

            // Track translation failures for the port
            always_ff @(posedge clk)
            begin
                g1_rd_vtp_failed[p] <= host_mem_g1_failed_if[p].read;
                g1_wr_vtp_failed[p] <= host_mem_g1_failed_if[p].write;

                if (host_mem_g1_failed_if[p].read)
                begin
                    g1_rd_vtp_failed_addr[p] <= 64'({ host_mem_g1_failed_if[p].address,
                                                      6'(p) });

                    // synthesis translate_off
                    $display("%m: VTP translation error AVMM port %0d RD, VA 0x%x", p,
                             { host_mem_g1_failed_if[p].address, 6'b0 });
                    // synthesis translate_on
                end

                if (host_mem_g1_failed_if[p].write)
                begin
                    if (wr_sop)
                    begin
                        g1_wr_vtp_failed_addr[p] <= 64'({ host_mem_g1_failed_if[p].address,
                                                          6'(p) });

                        // synthesis translate_off
                        $display("%m: VTP translation error AVMM port %0d WR, VA 0x%x", p,
                                 { host_mem_g1_failed_if[p].address, 6'b0 });
                        // synthesis translate_on
                    end
                    else
                    begin
                        // synthesis translate_off
                        $display("%m: VTP translation error AVMM port %0d WR, non-sop", p);
                        // synthesis translate_on
                    end
                end
            end
        end
    endgenerate

    // Merge individual G1 port failures into a single CSR. This loses information --
    // it's just a demonstration.
    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            csr_g1_rd_vtp_fail_va <= '0;
            csr_g1_rd_vtp_fail_cnt <= '0;
            csr_g1_wr_vtp_fail_va <= '0;
            csr_g1_wr_vtp_fail_cnt <= '0;
        end
        else
        begin
            csr_g1_rd_vtp_fail_cnt <= csr_g1_rd_vtp_fail_cnt + (|(g1_rd_vtp_failed));
            csr_g1_wr_vtp_fail_cnt <= csr_g1_wr_vtp_fail_cnt + (|(g1_wr_vtp_failed));

            for (int i = 0; i < NUM_PORTS_G1; i = i + 1)
            begin
                if (g1_rd_vtp_failed[i])
                begin
                    csr_g1_rd_vtp_fail_va <= g1_rd_vtp_failed_addr[i];
                end

                if (g1_wr_vtp_failed[i])
                begin
                    csr_g1_wr_vtp_fail_va <= g1_wr_vtp_failed_addr[i];
                end
            end
        end
    end

endmodule // dummy_failed_g1_sinks


//
// Simple AVMM request routing fork, useful only for this example since
// to_sink1 responses are ignored. Requests from source are routed either
// to sink0 or sink1 depending on the picker inputs.
//
module fork_avalon_mem
   (
    ofs_plat_avalon_mem_if.to_sink sink0,
    ofs_plat_avalon_mem_if.to_sink sink1,
    ofs_plat_avalon_mem_if.to_source source,

    // Picker directs requests
    input  logic pick_path
    );

    // Internal picker interfaces
    ofs_plat_avalon_mem_if
      #(
        `OFS_PLAT_AVALON_MEM_IF_REPLICATE_PARAMS(sink0)
        )
      picker_mem_if[2]();

    // Connect internal interfaces to the sink ports
    ofs_plat_avalon_mem_if_reg_sink_clk reg0
       (
        .mem_sink(sink0),
        .mem_source(picker_mem_if[0])
        );

    ofs_plat_avalon_mem_if_reg_sink_clk reg1
       (
        .mem_sink(sink1),
        .mem_source(picker_mem_if[1])
        );

    always_comb
    begin
        // Only sink0 (picker_mem_if[0]) responses reach source
        `OFS_PLAT_AVALON_MEM_IF_FROM_SINK_TO_SOURCE_COMB(source, picker_mem_if[0]);

        // Send requests from source to both sinks (control signals will be
        // cleaned up below so only one sink fires).
        `OFS_PLAT_AVALON_MEM_IF_FROM_SOURCE_TO_SINK_COMB(picker_mem_if[0], source);
        `OFS_PLAT_AVALON_MEM_IF_FROM_SOURCE_TO_SINK_COMB(picker_mem_if[1], source);

        // Choose which sink gets the request
        picker_mem_if[0].read = source.read && ~pick_path;
        picker_mem_if[1].read = source.read && pick_path;
        picker_mem_if[0].write = source.write && ~pick_path;
        picker_mem_if[1].write = source.write && pick_path;

        // Use only waitrequest from the chosen sink
        source.waitrequest = (pick_path ? picker_mem_if[1].waitrequest :
                                          picker_mem_if[0].waitrequest);
    end

endmodule // fork_avalon_mem


//
// Dummy MPF CCI-P shim implementation that detects failed translations on
// an MPF/CCI-P port. In this example, failed translations are simply
// dropped. A real handler would have to route failed requests to a
// proper handler.
//
module dummy_failed_mpf_ccip_shim
   (
    input  logic clk,

    cci_mpf_if.to_fiu to_fiu,
    cci_mpf_if.to_afu to_afu,

    // Record recent failures that will be exported as CSRs
    output logic [63:0] csr_mpf_c0_vtp_fail_va,
    output logic [15:0] csr_mpf_c0_vtp_fail_cnt,
    output logic [63:0] csr_mpf_c1_vtp_fail_va,
    output logic [15:0] csr_mpf_c1_vtp_fail_cnt
    );

    logic reset;
    assign reset = to_fiu.reset;

    assign to_afu.reset = to_fiu.reset;

    assign to_afu.c0TxAlmFull = to_fiu.c0TxAlmFull;
    assign to_afu.c1TxAlmFull = to_fiu.c1TxAlmFull;
    assign to_fiu.c2Tx = to_afu.c2Tx;

    assign to_afu.c0Rx = to_fiu.c0Rx;
    assign to_afu.c1Rx = to_fiu.c1Rx;

    always_ff @(posedge clk)
    begin
        to_fiu.c0Tx <= to_afu.c0Tx;
        if (cci_mpf_c0_getReqAddrIsVirtual(to_afu.c0Tx.hdr))
        begin
            to_fiu.c0Tx.valid <= 1'b0;

            csr_mpf_c0_vtp_fail_cnt <= csr_mpf_c0_vtp_fail_cnt + 1;
            csr_mpf_c0_vtp_fail_va <= { cci_mpf_c0_getReqAddr(to_afu.c0Tx.hdr), 6'b0 };

            if (!reset)
            begin
                // synthesis translate_off
                $display("%m: VTP translation error CCI-P port RD, VA 0x%x",
                         { cci_mpf_c0_getReqAddr(to_afu.c0Tx.hdr), 6'b0 });
                // synthesis translate_on
            end
        end

        to_fiu.c1Tx <= to_afu.c1Tx;
        if (cci_mpf_c1_getReqAddrIsVirtual(to_afu.c1Tx.hdr))
        begin
            to_fiu.c1Tx.valid <= 1'b0;

            csr_mpf_c1_vtp_fail_cnt <= csr_mpf_c1_vtp_fail_cnt + 1;
            csr_mpf_c1_vtp_fail_va <= { cci_mpf_c1_getReqAddr(to_afu.c1Tx.hdr), 6'b0 };

            if (!reset)
            begin
                // synthesis translate_off
                $display("%m: VTP translation error CCI-P port WR, VA 0x%x",
                         { cci_mpf_c1_getReqAddr(to_afu.c1Tx.hdr), 6'b0 });
                // synthesis translate_on
            end
        end

        if (reset)
        begin
            csr_mpf_c0_vtp_fail_va <= '0;
            csr_mpf_c0_vtp_fail_cnt <= '0;
            csr_mpf_c1_vtp_fail_va <= '0;
            csr_mpf_c1_vtp_fail_cnt <= '0;
        end
    end

endmodule // dummy_failed_mpf_ccip_sink
