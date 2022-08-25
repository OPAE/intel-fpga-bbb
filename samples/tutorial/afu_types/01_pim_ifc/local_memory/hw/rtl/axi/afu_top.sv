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

module afu_top
  #(
    parameter NUM_LOCAL_MEM_BANKS = 2
    )
   (
    // CSR interface (MMIO on the host)
    ofs_plat_axi_mem_lite_if.to_source mmio64_to_afu,

    // Local memory interface. The platform interface module (ofs_plat_afu)
    // has mapped all local memory clocks to same clock as the CSR interface.
    ofs_plat_axi_mem_if.to_sink local_mem[NUM_LOCAL_MEM_BANKS]
    );

    import ofs_plat_axi_mem_pkg::*;

    logic clk;
    logic reset_n;

    assign clk = mmio64_to_afu.clk;
    assign reset_n = mmio64_to_afu.reset_n;


    // ====================================================================
    // User AFU goes here
    // ====================================================================

    //
    // At this point, all interfaces are operating in a common clock
    // domain.
    //

    localparam DATA_WIDTH = `OFS_PLAT_PARAM_LOCAL_MEM_DATA_WIDTH;

    //
    // Memory banks are used very simply here.  Only one bank is active at
    // a time, selected by mem_bank_select.  mem_bank_select is set
    // by a CSR from the host.
    //
    // Despite the local memory banks themselves using AXI interfaces,
    // this simple example uses the same hello_mem_afu controller to
    // manage CSRs and drive the local memory. hello_mem_afu uses
    // Avalon memory interfaces. Code below will map the Avalon command
    // interface connected to hello_mem_afu to AXI memory bank commands.
    ofs_plat_avalon_mem_if
      #(
        `LOCAL_MEM_AVALON_MEM_PARAMS_DEFAULT
        )
      local_mem_cmd();

    // Choose which memory bank to test
    logic [$clog2(NUM_LOCAL_MEM_BANKS)-1:0] mem_bank_select;

    hello_mem_afu
      #(
        .NUM_LOCAL_MEM_BANKS(NUM_LOCAL_MEM_BANKS)
        )
      hello_mem_afu_inst
       (
        .clk,
        .reset_n,

        .mmio64_to_afu,
        .mem_cmd(local_mem_cmd),
        .mem_bank_select(mem_bank_select)
        );


    //
    // Forward commands to local memory banks, translating the AFU's internal
    // Avalon memory commands to AXI memory commands.
    //

    //
    // Map control and read responses back to Avalon names.
    //
    logic avs_waitrequest_v[NUM_LOCAL_MEM_BANKS];
    logic avs_readdatavalid_v[NUM_LOCAL_MEM_BANKS];
    logic [DATA_WIDTH-1 : 0] avs_readdata_v[NUM_LOCAL_MEM_BANKS];

    genvar b;
    generate
        for (b = 0; b < NUM_LOCAL_MEM_BANKS; b = b + 1)
        begin : lmb
            // Always ready to receive a local memory response
            assign local_mem[b].rready = 1'b1;
            assign local_mem[b].bready = 1'b1;

            // Generate AXI "last" for write bursts by tracking the Avalon
            // command channel.
            logic is_wsop, is_weop;
            ofs_plat_prim_burstcount1_sop_tracker
              #(
                .BURST_CNT_WIDTH(local_mem_cmd.BURST_CNT_WIDTH)
                )
              eop_tracker
               (
                .clk,
                .reset_n,
                .flit_valid(local_mem_cmd.write &&
                            !avs_waitrequest_v[b] &&
                            ($bits(mem_bank_select)'(b) == mem_bank_select)),
                .burstcount(local_mem_cmd.burstcount),
                .sop(is_wsop),
                .eop(is_weop)
                );

            //
            // Instantiate independent skid buffers for the three AXI
            // command channels: write address, write data and read address.
            // The PIM provides a module that implements skid buffers for
            // ready/enable protocols.
            //
            // By using skid buffers we avoid violating the rule that
            // asserting valid on a channel must be independent of the
            // ready signal.
            //

            // Use an instance of the AXI-MM interface for its structs.
            ofs_plat_axi_mem_if
              #(
                // Replicate interface parameters so the instance is identical
                `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(local_mem[b]),
                // No simulation-time checking. This instance is just used for
                // storage.
                .DISABLE_CHECKER(1)
                )
              local_mem_axi_reg();

            // Read requests
            ofs_plat_prim_ready_enable_skid
              #(
                .N_DATA_BITS(local_mem[b].T_AR_WIDTH)
                )
              ar_skid
               (
                .clk,
                .reset_n,
                .enable_from_src(local_mem_axi_reg.arvalid),
                .data_from_src(local_mem_axi_reg.ar),
                .ready_to_src(local_mem_axi_reg.arready),
                .enable_to_dst(local_mem[b].arvalid),
                .data_to_dst(local_mem[b].ar),
                .ready_from_dst(local_mem[b].arready)
                );

            // Write address requests
            ofs_plat_prim_ready_enable_skid
              #(
                .N_DATA_BITS(local_mem[b].T_AW_WIDTH)
                )
              aw_skid
               (
                .clk,
                .reset_n,
                .enable_from_src(local_mem_axi_reg.awvalid),
                .data_from_src(local_mem_axi_reg.aw),
                .ready_to_src(local_mem_axi_reg.awready),
                .enable_to_dst(local_mem[b].awvalid),
                .data_to_dst(local_mem[b].aw),
                .ready_from_dst(local_mem[b].awready)
                );

            // Write data requests
            ofs_plat_prim_ready_enable_skid
              #(
                .N_DATA_BITS(local_mem[b].T_W_WIDTH)
                )
              w_skid
               (
                .clk,
                .reset_n,
                .enable_from_src(local_mem_axi_reg.wvalid),
                .data_from_src(local_mem_axi_reg.w),
                .ready_to_src(local_mem_axi_reg.wready),
                .enable_to_dst(local_mem[b].wvalid),
                .data_to_dst(local_mem[b].w),
                .ready_from_dst(local_mem[b].wready)
                );

            // AXI addresses are byte level. Avalon addresses are line level. AXI
            // addresses must be passed with low 0 bits.
            logic [local_mem[b].ADDR_BYTE_IDX_WIDTH-1 : 0] axi_addr_pad = '0;

            // Generate AXI structs as inputs to the skid buffers.
            always_comb
            begin
                // Local memory to AFU signals, mapping back to Avalon.
                // Block on inability to request a read or a write. These
                // ready signals come from the input side of the skid buffers.
                avs_waitrequest_v[b] = !local_mem_axi_reg.awready ||
                                       !local_mem_axi_reg.wready ||
                                       !local_mem_axi_reg.arready;


                // Read requests
                local_mem_axi_reg.arvalid = local_mem_cmd.read && !avs_waitrequest_v[b] &&
                                            ($bits(mem_bank_select)'(b) == mem_bank_select);
                local_mem_axi_reg.ar = '0;
                // Padding maps from line addresses (Avalon) to byte addresses (AXI).
                local_mem_axi_reg.ar.addr = { local_mem_cmd.address, axi_addr_pad };
                // AXI burst counts treat 0 as a single beat. Avalon treats 1 as a single beat.
                local_mem_axi_reg.ar.len = local_mem_cmd.burstcount - 1;
                local_mem_axi_reg.ar.size = t_axi_log2_beat_size'(local_mem[b].ADDR_BYTE_IDX_WIDTH);

                // Read responses
                avs_readdata_v[b] = local_mem[b].r.data;
                avs_readdatavalid_v[b] = local_mem[b].rvalid;


                // Write requests
                local_mem_axi_reg.awvalid = local_mem_cmd.write && !avs_waitrequest_v[b] &&
                                            is_wsop &&
                                            ($bits(mem_bank_select)'(b) == mem_bank_select);
                local_mem_axi_reg.aw = '0;
                local_mem_axi_reg.aw.addr = { local_mem_cmd.address, axi_addr_pad };
                local_mem_axi_reg.aw.len = local_mem_cmd.burstcount - 1;
                local_mem_axi_reg.aw.size = t_axi_log2_beat_size'(local_mem[b].ADDR_BYTE_IDX_WIDTH);

                local_mem_axi_reg.wvalid = local_mem_cmd.write && !avs_waitrequest_v[b] &&
                                           ($bits(mem_bank_select)'(b) == mem_bank_select);
                local_mem_axi_reg.w = '0;
                local_mem_axi_reg.w.data = local_mem_cmd.writedata;
                local_mem_axi_reg.w.strb = local_mem_cmd.byteenable;
                local_mem_axi_reg.w.last = is_weop;
            end
        end
    endgenerate

    assign local_mem_cmd.waitrequest = avs_waitrequest_v[mem_bank_select];

    // Read responses from the active bank
    always_ff @(posedge clk)
    begin
        local_mem_cmd.readdata <= avs_readdata_v[mem_bank_select];
        local_mem_cmd.readdatavalid <= avs_readdatavalid_v[mem_bank_select];
    end

endmodule
