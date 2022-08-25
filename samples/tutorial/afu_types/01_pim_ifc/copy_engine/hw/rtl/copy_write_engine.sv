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
// This is not the main write engine. It is a wrapper around the main engine,
// which is named copy_write_engine_core().
//
// The module here is responsible for injecting completions (interrupts or
// status line writes) into the write stream as copy operations complete in
// order to signal the host. Putting just the completion logic here makes
// the code easier to read.
//

module copy_write_engine
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

    //
    // ***
    //   To make comments and variable names simpler, we will call both
    //   completion methods "interrupts" instead of naming both interrupts
    //   and writes to the mem_status_addr. The logic for generating either
    //   interrupts or writes to the status line is mostly shared, with
    //   the exception of the command sent to host_mem.aw.
    // ***
    //

    // An interrupt will be generated at the completion of a packet when the low
    // bit of wr_cmd.addr is set. Since we only deal with bus-aligned addresses,
    // the bit would otherwise have to be zero. It is a convenient place to
    // request an interrupt without needing extra MMIO traffic. The tracking
    // state is declared here since it is needed to gate write requests.
    logic interrupt_pending;
    logic [$clog2(MAX_REQS_IN_FLIGHT):0] interrupt_pending_cnt;
    logic emit_interrupt;
    // Only one interrupt request can be outstanding for the vector ID
    logic interrupt_not_busy;
    
    // This container will be used to generate interrupts. Instantiating it
    // with the same parameters as all other instances makes the width the same.
    ofs_plat_axi_mem_if
      #(
        // Copy the configuration from host_mem
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(host_mem)
        )
      interrupt();

    // Various control signals used for synchronizing AW/W channels and
    // injecting interrupts.
    logic w_sop;
    logic aw_ready;
    logic w_ready;


    // ====================================================================
    //
    // Add skid buffers to outbound AW and W both for timing and so that
    // the two channels can be synchronized on SOP. The ready_to_src is
    // guaranteed not to depend on enable_from_src in this implementation,
    // allowing us to build a ready signal from both channels together.
    //
    // ====================================================================

    // Instantiate a host channel AXI-MM interface that will be passed to the
    // core write engine.
    ofs_plat_axi_mem_if
      #(
        // Copy the configuration from host_mem
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(host_mem)
        )
      host_mem_wr();

    assign host_mem_wr.clk = clk;
    assign host_mem_wr.reset_n = reset_n;
    assign host_mem_wr.instance_number = host_mem.instance_number;

    ofs_plat_prim_ready_enable_skid
      #(
        .N_DATA_BITS(host_mem.T_AW_WIDTH)
        )
      mem_aw_skid
       (
        .clk,
        .reset_n,

        .enable_to_dst(host_mem.awvalid),
        .data_to_dst(host_mem.aw),
        .ready_from_dst(host_mem.awready),

        // Either a new address or an interrupt
        .enable_from_src((host_mem_wr.awvalid && host_mem_wr.awready) || emit_interrupt),
        .data_from_src(!emit_interrupt ? host_mem_wr.aw : interrupt.aw),
        .ready_to_src(aw_ready)
        );

    ofs_plat_prim_ready_enable_skid
      #(
        .N_DATA_BITS(host_mem.T_W_WIDTH)
        )
      mem_w_skid
       (
        .clk,
        .reset_n,

        .enable_to_dst(host_mem.wvalid),
        .data_to_dst(host_mem.w),
        .ready_from_dst(host_mem.wready),

        // Either new data or an interrupt
        .enable_from_src((host_mem_wr.wvalid && host_mem_wr.wready) || emit_interrupt),
        .data_from_src(!emit_interrupt ? host_mem_wr.w : interrupt.w),
        .ready_to_src(w_ready)
        );


    assign host_mem_wr.bvalid = host_mem.bvalid;
    // This module also processes write responses, but it is always ready
    // for the write completion. The interrupt_pending_cnt tracker below
    // is large enough to track all outstanding requests.
    assign host_mem.bready = host_mem_wr.bready;
    assign host_mem_wr.b = host_mem.b;

    // Read unused
    assign host_mem_wr.rvalid = 1'b0;
    assign host_mem_wr.arready = 1'b0;
    assign host_mem.arvalid = 1'b0;
    assign host_mem.rready = 1'b1;


    wire all_w_ready = aw_ready && w_ready;
    // Are both AW and W valid? This is used at SOP. Interrupts have priority
    // at SOP.
    wire all_w_valid = host_mem_wr.awvalid && host_mem_wr.wvalid &&
                       !(interrupt_pending && interrupt_not_busy);

    assign host_mem_wr.awready = all_w_ready && w_sop && all_w_valid;
    assign host_mem_wr.wready = all_w_ready && (!w_sop || all_w_valid);


    //
    // Track interrupt requests. An interrupt is generated at the completion of
    // every write command that has its low address bit set to 1. See the declaration
    // of "interrupt_pending" above for details.
    //
    // Completion is when the response is received on b -- the point at which the
    // write data is committed to memory.
    //

    // Emit an interrupt when both AW and W are ready and it is SOP. Interrupt
    // sends a message on both and we have to keep W packets together.
    assign emit_interrupt = all_w_ready && w_sop && interrupt_pending && interrupt_not_busy;
    // New interrupt needed due to write completion. Increment the pending
    // interrupts counter. If the interrupt user flag is set, this is an
    // interrupt response and not a write completion.
    wire incr_interrupt = host_mem.bvalid && host_mem.b.id[0] &&
                          !host_mem.b.user[ofs_plat_host_chan_axi_mem_pkg::HC_AXI_UFLAG_INTERRUPT];

    always_ff @(posedge clk)
    begin
        if (emit_interrupt == incr_interrupt)
        begin
            // No change. Either increment and decrement together or neither.
            interrupt_pending <= interrupt_pending;
            interrupt_pending_cnt <= interrupt_pending_cnt;
        end
        else if (incr_interrupt)
        begin
            // New interrupt needed
            interrupt_pending <= 1'b1;
            interrupt_pending_cnt <= interrupt_pending_cnt + 1;
        end
        else
        begin
            // Emitted interrupt
            interrupt_pending <= (interrupt_pending_cnt > 1);
            interrupt_pending_cnt <= interrupt_pending_cnt - 1;
        end

        if (!reset_n)
        begin
            interrupt_pending <= 1'b0;
            interrupt_pending_cnt <= '0;
        end
    end

    // Command and payload passed to host_mem when emit_interrupt is true.
    logic [63:0] num_completed_cmds;

    always_comb
    begin
        interrupt.aw = '0;

        // Id bit 1 set to indicate this message. The real write engine
        // guarantees never to set bit 1.
        interrupt.aw.id[1] = 1'b1;

        if (!wr_cmd.use_mem_status)
        begin
            // Interrupt vector index is passed in the low bits of addr.
            interrupt.aw.addr = { '0, wr_cmd.intr_id };
            // Signal an interrupt. The PIM encodes this with user flags.
            interrupt.aw.user[ofs_plat_host_chan_axi_mem_pkg::HC_AXI_UFLAG_INTERRUPT] = 1'b1;
        end
        else
        begin
            // Status line write instead of interrupt
            interrupt.aw.addr = wr_cmd.mem_status_addr;
        end

        // Generate a corresponding write data packet. Interrupts don't have a
        // real payload, so just generate the payload appropriate for status
        // line writes.
        interrupt.w = '0;
        interrupt.w.last = 1'b1;
        interrupt.w.data = { '0, num_completed_cmds };
        // Only write 64 bits
        interrupt.w.strb = { '0, 8'hff };
    end

    always_ff @(posedge clk)
    begin
        // ID[1] is clear for command traffic
        if (host_mem.bvalid && host_mem.bready && !host_mem.b.id[1])
        begin
            num_completed_cmds <= num_completed_cmds + 1;
        end

        if (!reset_n)
        begin
            num_completed_cmds <= 0;
        end
    end


    // Track whether the interrupt ID is busy by detecting requests and
    // waiting for an ACK from the host.
    always_ff @(posedge clk)
    begin
        if (emit_interrupt && !wr_cmd.use_mem_status)
        begin
            // Lock out other interrupts when generating one
            interrupt_not_busy <= 1'b0;
        end

        if (wr_cmd.intr_ack)
        begin
            // Previous interrupt is complete
            interrupt_not_busy <= 1'b1;
        end

        if (!reset_n)
        begin
            interrupt_not_busy <= 1'b1;
        end
    end


    // Track SOP of the W stream. It's simply the next flit following EOP.
    always_ff @(posedge clk)
    begin
        if (host_mem_wr.wvalid && host_mem_wr.wready)
        begin
            w_sop <= host_mem_wr.w.last;
        end

        if (!reset_n)
        begin
            w_sop <= 1'b1;
        end
    end


    //
    // Instantiate the actual write engine.
    //
    copy_write_engine_core
      #(
        .MAX_REQS_IN_FLIGHT(MAX_REQS_IN_FLIGHT)
        )
      write_engine_core
       (
        // Host memory write interface
        .host_mem(host_mem_wr),

        // Stream data from reader to writer
        .data_stream,

        // Commands
        .wr_cmd,
        .wr_state
        );

endmodule // copy_write_engine
