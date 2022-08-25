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
// Read engine. Consume read commands, generate read requests from host memory
// and stream read response data out.
//

module copy_read_engine
  #(
    parameter MAX_REQS_IN_FLIGHT = 32
    )
   (
    // Host memory interface. Only read buses are connected.
    ofs_plat_axi_mem_if.to_sink host_mem,

    // Data stream to write engine
    ofs_plat_axi_stream_if.to_sink data_stream,

    // Read engine control - initiate a read of num_lines from addr when enable is set.
    input  copy_engine_pkg::t_rd_cmd rd_cmd,
    output copy_engine_pkg::t_rd_state rd_state
    );

    wire clk = host_mem.clk;
    wire reset_n = host_mem.reset_n;

    // Store incoming read commands in a FIFO that is large enough to hold
    // the maximum number of requests in flight. It is the responsibility of the
    // host not to overflow this FIFO.
    copy_engine_pkg::t_cmd_num_lines rd_cmd_num_lines_out;
    copy_engine_pkg::t_cmd_addr rd_cmd_addr_out;

    // Use the PIM's FIFO implementation. Any FIFO could be used here. The PIM's
    // FIFO provides data the same cycle that notEmpty is valid.
    ofs_plat_prim_fifo_bram
      #(
        .N_DATA_BITS($bits(copy_engine_pkg::t_cmd_num_lines) + $bits(copy_engine_pkg::t_cmd_addr)),
        .N_ENTRIES(MAX_REQS_IN_FLIGHT)
        )
      fifo_in
       (
        .clk,
        .reset_n,

        .enq_data({ rd_cmd.num_lines, rd_cmd.addr }),
        .enq_en(rd_cmd.enable),
        .notFull(),
        .almostFull(),

        // Pop the next command if the read request was sent to the host
        .deq_en(host_mem.arvalid && host_mem.arready),
        .notEmpty(host_mem.arvalid),
        .first({ rd_cmd_num_lines_out, rd_cmd_addr_out })
        );

    // Read IDs are supposed to be unique. Use a simple counter that is
    // large enough to know that earlier reads with the same ID are complete.
    // The PIM doesn't actually care whether IDs are unique.
    logic [$clog2(MAX_REQS_IN_FLIGHT):0] rd_id;
    always_ff @(posedge clk)
    begin
        if (host_mem.arvalid && host_mem.arready)
        begin
            rd_id <= rd_id + 1;
        end

        if (!reset_n)
        begin
            rd_id <= 0;
        end
    end


    //
    // Generate read requests. The host_mem interface from the PIM was configured
    // to accept read bursts up to the largest the host program will request.
    // This was done in ofs_plat_afu.sv at the declaration of host_mem.
    // There is thus a 1:1 mapping from incoming commands to AXI-MM read requests.
    //
    always_comb
    begin
        host_mem.ar = '0;
        host_mem.ar.id = rd_id;
        host_mem.ar.addr = rd_cmd_addr_out;
        host_mem.ar.len = rd_cmd_num_lines_out;
        // Full width of the data bus
        host_mem.ar.size = host_mem.ADDR_BYTE_IDX_WIDTH;
    end


    //
    // Forward read responses out the AXI stream. The PIM has sorted responses
    // so they are in request order.
    //
    assign data_stream.tvalid = host_mem.rvalid;
    assign host_mem.rready = data_stream.tready;

    always_comb
    begin
        data_stream.t = '0;
        data_stream.t.data = host_mem.r.data;
        data_stream.t.last = host_mem.r.last;
    end


    //
    // Write request channel not used in read engine
    //
    assign host_mem.awvalid = 1'b0;
    assign host_mem.wvalid = 1'b0;
    assign host_mem.bready = 1'b1;


    //
    // Count read responses
    //

    logic [63:0] num_read_rsp_lines;

    counter_multicycle rd_counter
       (
        .clk,
        .reset_n,
        .incr_by((host_mem.rvalid && host_mem.rready) ? 64'h1 : 64'h0),
        .value(num_read_rsp_lines)
        );

    always_ff @(posedge clk)
    begin
        rd_state.num_lines_read <= num_read_rsp_lines;
    end

endmodule // copy_read_engine
