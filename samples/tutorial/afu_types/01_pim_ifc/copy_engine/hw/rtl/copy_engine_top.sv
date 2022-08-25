//
// Copyright (c) 2022, Intel Corporation
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
// Copy engine top-level. Take in a pair of AXI-MM interfaces, one for CSRs and
// one for reading and writing host memory.
//
// This engine can be instantiated either from a full-PIM system using
// ofs_plat_afu() or from a hybrid design in which the PIM host channel
// mapping is created by the AFU.
//

module copy_engine_top
   (
    // CSR interface (MMIO on the host)
    ofs_plat_axi_mem_lite_if.to_source mmio64_to_afu,

    // Host memory (DMA)
    ofs_plat_axi_mem_if.to_sink host_mem
    );

    // Each interface names its associated clock and reset.
    logic clk;
    assign clk = host_mem.clk;
    logic reset_n;
    assign reset_n = host_mem.reset_n;

    // Maximum number of copy commands in flight. This is exposed in a CSR. It
    // is the host's responsibility not to exceed. The host can track completions
    // by requesting interrupts.
    localparam MAX_REQS_IN_FLIGHT = 1024;


    // ====================================================================
    //
    // CSR (MMIO) manager. Handle all MMIO reads and writes from the host
    // and output copy commands.
    //
    // ====================================================================

    copy_engine_pkg::t_rd_cmd rd_cmd;
    copy_engine_pkg::t_rd_state rd_state;
    copy_engine_pkg::t_wr_cmd wr_cmd;
    copy_engine_pkg::t_wr_state wr_state;

    csr_mgr
      #(
        .MAX_REQS_IN_FLIGHT(MAX_REQS_IN_FLIGHT),
        // Maximum burst length is dictated by the size of the field in
        // the AXI-MM host_mem. The PIM will map AXI-MM bursts to legal
        // host channel bursts, including guaranteeing to satisfy any
        // necessary address alignment.
        .MAX_BURST_CNT(1 << host_mem.BURST_CNT_WIDTH_)
        )
      csr_mgr_inst
       (
        .mmio64_to_afu,

        .rd_cmd,
        .rd_state,

        .wr_cmd,
        .wr_state
        );


    // ====================================================================
    //
    // Read engine
    //
    // ====================================================================

    // Declare a copy of the host memory read interface. The read ports
    // will be connected to the read engine and the write ports unused.
    // This will split the read channels from the write channels but keep
    // a single interface type.
    ofs_plat_axi_mem_if
      #(
        // Copy the configuration from host_mem
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(host_mem)
        )
      host_mem_rd();

    // Connect read ports to host_mem
    assign host_mem_rd.clk = clk;
    assign host_mem_rd.reset_n = reset_n;
    assign host_mem_rd.instance_number = host_mem.instance_number;

    assign host_mem.arvalid = host_mem_rd.arvalid;
    assign host_mem_rd.arready = host_mem.arready;
    assign host_mem.ar = host_mem_rd.ar;

    assign host_mem_rd.rvalid = host_mem.rvalid;
    assign host_mem.rready = host_mem_rd.rready;
    assign host_mem_rd.r = host_mem.r;

    // Write unused
    assign host_mem_rd.bvalid = 1'b0;
    assign host_mem_rd.awready = 1'b0;
    assign host_mem_rd.wready = 1'b0;

    //
    // Declare an AXI stream that will pass data from the read engine to the
    // data stream engine.
    //
    ofs_plat_axi_stream_if
      #(
        .TDATA_TYPE(logic [ofs_plat_host_chan_pkg::DATA_WIDTH-1 : 0]),
        .TUSER_TYPE(logic)
        )
      data_stream_from_rd();

    assign data_stream_from_rd.clk = clk;
    assign data_stream_from_rd.reset_n = reset_n;
    assign data_stream_from_rd.instance_number = 0;

    //
    // Read engine
    //
    copy_read_engine
      #(
        .MAX_REQS_IN_FLIGHT(MAX_REQS_IN_FLIGHT)
        )
      read_engine
       (
        // Host memory read interface
        .host_mem(host_mem_rd),

        // Stream data from reader to writer
        .data_stream(data_stream_from_rd),

        // Commands
        .rd_cmd,
        .rd_state
        );
    

    // ====================================================================
    //
    // Data stream engine
    //
    // ====================================================================

    // Forward the data stream through a sample data stream engine.
    // The assumption is that a real algorithm would be doing some
    // manipulation of the data stream and this demonstrates that
    // data path.
    //

    // ***
    // The PIM guarantees that the data stream arrives in request order.
    // ***

    // Another AXI stream, from the engine to the writer
    ofs_plat_axi_stream_if
      #(
        .TDATA_TYPE(logic [ofs_plat_host_chan_pkg::DATA_WIDTH-1 : 0]),
        .TUSER_TYPE(logic)
        )
      data_stream_to_wr();

    assign data_stream_to_wr.clk = clk;
    assign data_stream_to_wr.reset_n = reset_n;
    assign data_stream_to_wr.instance_number = 0;

    data_stream_engine data_engine
       (
        .data_stream_in(data_stream_from_rd),
        .data_stream_out(data_stream_to_wr)
        );


    // ====================================================================
    //
    // Write engine
    //
    // ====================================================================

    // Declare a copy of the host memory write interface. The write ports
    // will be connected to the write engine and the read ports unused.
    // This will split the read channels from the write channels but keep
    // a single interface type.
    ofs_plat_axi_mem_if
      #(
        // Copy the configuration from host_mem
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(host_mem)
        )
      host_mem_wr();

    // Connect read ports to host_mem
    assign host_mem_wr.clk = clk;
    assign host_mem_wr.reset_n = reset_n;
    assign host_mem_wr.instance_number = host_mem.instance_number;

    assign host_mem.awvalid = host_mem_wr.awvalid;
    assign host_mem_wr.awready = host_mem.awready;
    assign host_mem.aw = host_mem_wr.aw;

    assign host_mem.wvalid = host_mem_wr.wvalid;
    assign host_mem_wr.wready = host_mem.wready;
    assign host_mem.w = host_mem_wr.w;

    assign host_mem_wr.bvalid = host_mem.bvalid;
    assign host_mem.bready = host_mem_wr.bready;
    assign host_mem_wr.b = host_mem.b;

    // Read unused
    assign host_mem_wr.rvalid = 1'b0;
    assign host_mem_wr.arready = 1'b0;

    //
    // Write engine
    //
    copy_write_engine
      #(
        .MAX_REQS_IN_FLIGHT(MAX_REQS_IN_FLIGHT)
        )
      write_engine
       (
        // Host memory write interface
        .host_mem(host_mem_wr),

        // Stream data from reader to writer
        .data_stream(data_stream_to_wr),

        // Commands
        .wr_cmd,
        .wr_state
        );

endmodule
