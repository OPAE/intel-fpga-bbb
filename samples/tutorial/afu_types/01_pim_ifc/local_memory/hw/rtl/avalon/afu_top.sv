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
    ofs_plat_avalon_mem_if.to_sink local_mem[NUM_LOCAL_MEM_BANKS]
    );

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
    // This single instance of an Avalon memory interface is managed by
    // hello_mem_afu and drives each of the memory banks.
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
    // Forward commands to local memory banks.
    //

    //
    // Export the local memory interface signals as vectors so that bank
    // selection can use array syntax.
    //
    logic avs_waitrequest_v[NUM_LOCAL_MEM_BANKS];
    logic avs_readdatavalid_v[NUM_LOCAL_MEM_BANKS];
    logic [DATA_WIDTH-1 : 0] avs_readdata_v[NUM_LOCAL_MEM_BANKS];

    genvar b;
    generate
        for (b = 0; b < NUM_LOCAL_MEM_BANKS; b = b + 1)
        begin : lmb
            always_comb
            begin
                // Local memory to AFU signals
                avs_waitrequest_v[b] = local_mem[b].waitrequest;
                avs_readdata_v[b] = local_mem[b].readdata;
                avs_readdatavalid_v[b] = local_mem[b].readdatavalid;

                // Replicate address and write data to all banks.  Only
                // the request signals have to be bank-specific.
                local_mem[b].burstcount = local_mem_cmd.burstcount;
                local_mem[b].writedata = local_mem_cmd.writedata;
                local_mem[b].address = local_mem_cmd.address;
                local_mem[b].byteenable = local_mem_cmd.byteenable;

                // Request a write to this bank?
                local_mem[b].write = local_mem_cmd.write &&
                                     ($bits(mem_bank_select)'(b) == mem_bank_select);

                // Request a read from this bank?
                local_mem[b].read =  local_mem_cmd.read &&
                                     ($bits(mem_bank_select)'(b) == mem_bank_select);

                local_mem[b].user = '0;
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
