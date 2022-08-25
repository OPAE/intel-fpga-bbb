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
// This is the main write engine, which consumes write commands and generates
// write requests to host memory using the incoming data stream as the payload.
//
// The write engine core is wrapped by a parent module named copy_write_engine(),
// which injects interrupts into the write stream as needed to inform the host
// that an operation is complete. Separating the two makes the logic easier
// to understand.
//

module copy_write_engine_core
  #(
    parameter MAX_REQS_IN_FLIGHT = 32
    )
   (
    // Host memory interface. Only write buses are connected.
    ofs_plat_axi_mem_if.to_sink host_mem,

    // Data stream to write engine
    ofs_plat_axi_stream_if.to_source data_stream,

    // Write engine control - initiate a write of num_lines from addr when enable is set.
    input  copy_engine_pkg::t_wr_cmd wr_cmd,
    output copy_engine_pkg::t_wr_state wr_state
    );

    wire clk = host_mem.clk;
    wire reset_n = host_mem.reset_n;


    // Store incoming write commands in a FIFO that is large enough to hold
    // the maximum number of requests in flight. It is the responsibility of the
    // host not to overflow this FIFO.
    //
    // Read payload sizes must match write payload sizes!
    copy_engine_pkg::t_cmd_num_lines wr_cmd_num_lines_out;
    copy_engine_pkg::t_cmd_addr wr_cmd_addr_out;

    // Use the PIM's FIFO implementation. Any FIFO could be used here. The PIM's
    // FIFO provides data the same cycle notEmpty is valid.
    ofs_plat_prim_fifo_bram
      #(
        .N_DATA_BITS($bits(copy_engine_pkg::t_cmd_num_lines) + $bits(copy_engine_pkg::t_cmd_addr)),
        .N_ENTRIES(MAX_REQS_IN_FLIGHT)
        )
      fifo_in
       (
        .clk,
        .reset_n,

        .enq_data({ wr_cmd.num_lines, wr_cmd.addr }),
        .enq_en(wr_cmd.enable),
        .notFull(),
        .almostFull(),

        // Pop the next command if the write request was sent to the host
        .deq_en(host_mem.awvalid && host_mem.awready),
        .notEmpty(host_mem.awvalid),
        .first({ wr_cmd_num_lines_out, wr_cmd_addr_out })
        );

    // Write IDs are supposed to be unique. Use a simple counter that is
    // large enough to know that earlier writes with the same ID are complete.
    logic [$clog2(MAX_REQS_IN_FLIGHT):0] wr_id;
    always_ff @(posedge clk)
    begin
        if (host_mem.awvalid && host_mem.awready)
        begin
            wr_id <= wr_id + 1;
        end

        if (!reset_n)
        begin
            wr_id <= 0;
        end
    end


    //
    // Generate write requests. The host_mem interface from the PIM was configured
    // to accept write bursts up to the largest the host program will request.
    // This was done in ofs_plat_afu.sv at the declaration of host_mem.
    // There is thus a 1:1 mapping from incoming commands to AXI-MM write requests.
    //
    always_comb
    begin
        host_mem.aw = '0;
        host_mem.aw.addr = wr_cmd_addr_out;
        host_mem.aw.len = wr_cmd_num_lines_out;

        // The low bit of the address indicates whether to generate an interrupt
        // on completion. This will come back in the b channel.
        // Bit 1 must be 0. The interrupt injector uses bit 1.
        host_mem.aw.id = { wr_id, 1'b0, wr_cmd_addr_out[0] };
        // Force the actual low address bit to 0
        host_mem.aw.addr[0] = 1'b0;

        // Full width of the data bus
        host_mem.aw.size = host_mem.ADDR_BYTE_IDX_WIDTH;
    end


    //
    // Forward write data. A full implementation might do more control logic checking,
    // such as checking that the "last" flag is set on the incoming data stream at the
    // point that it is expected in the write stream. For this example, we assume
    // that the software has generated legal requests.
    //

    assign data_stream.tready = host_mem.wready || !host_mem.wvalid;

    always_ff @(posedge clk)
    begin
        if (data_stream.tready)
        begin
            host_mem.wvalid <= data_stream.tvalid;
            host_mem.w <= '0;
            host_mem.w.data <= data_stream.t.data;
            // Always full data bus
            host_mem.w.strb <= ~(ofs_plat_host_chan_pkg::DATA_WIDTH_BYTES'(0));
            // Payload sizes of the incoming stream and the outgoing write are
            // supposed to be the same. More robust code would check this.
            host_mem.w.last <= data_stream.t.last;
        end
        else if (host_mem.wready)
        begin
            // If there was a previous payload it has been sent
            host_mem.wvalid <= 1'b0;
        end

        if (!reset_n)
        begin
            host_mem.wvalid <= 1'b0;
        end
    end

    // The write response channel isn't used in this module
    assign host_mem.bready = 1'b1;


    //
    // Read request channel not used in read engine
    //
    assign host_mem.arvalid = 1'b0;
    assign host_mem.rready = 1'b1;


    //
    // Count writes
    //

    logic [63:0] num_write_lines;

    counter_multicycle wr_counter
       (
        .clk,
        .reset_n,
        .incr_by((host_mem.wvalid && host_mem.wready) ? 64'h1 : 64'h0),
        .value(num_write_lines)
        );

    always_ff @(posedge clk)
    begin
        wr_state.num_lines_write <= num_write_lines;
    end

endmodule // copy_write_engine_core
