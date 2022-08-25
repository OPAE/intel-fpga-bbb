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
`include "afu_json_info.vh"

//
// Simple CSR manager. Export the required device feature header and some
// command registers for triggering host memory reads and writes. The
// number of registers managed here is quite small and throughput
// of reads doesn't affect performance, so the CSR interface is not
// pipelined.
//

//
// Read registers (64 bits, byte address is offset * 8):
//
//   0: Device feature header (DFH)
//   1: AFU_ID_L
//   2: AFU_ID_L
//   3: DFH_RSVD0
//   4: DFH_RSVD1
//   5: Platform information
//	  [63:48] Maximum burst length
//        [47:32] Maximum permitted number of requests in flight
//        [31:24] Number of interrupt vectors available
//        [23:16] Data bus width (bytes)
//        [15: 0] pClk frequency (MHz)
//   6: Number of lines read (each line is data bus width bytes)
//   7: Number of lines written
//
// Write command registers (64 bits, byte address is offset * 8):
//
//   8: Read engine num_lines: number of lines to read per request. Define
//      "line" as the width of the data bus. This must be set before writing
//      an address to register 9. The value is actually num_lines-1 to match
//      AXI-MM encoding.
//   9: Read start address. When this is written, the number of lines currently
//      in register 8 will be read, starting with the incoming address. The
//      host must rate limit requests so that there are fewer than the maximum
//      permitted number of requests in flight (read register 5).
//  10: Write engine num_lines. The same as register 8, but for the write stream.
//      Num_lines for a write request must match num_lines for the read that is
//      feeding it. The interrupt vector to use when completing a packet that
//      has interrupt completion enabled is stored in the high half.
//        [39:32] interrupt number
//        [31: 0] num_lines
//  11: Write start address. The same protocol as register 9, but for writes.
//      Write data comes from the read stream. The write engine will wait for
//      read data to arrive. When bit 0 of the start address is 1 a completion
//      will be generated to the host when the write commits. Completions are
//      either interrupts or writes to the line set in register 13. The interrupt
//      vector is set in register 10.
//  12: Interrupt ACK. Software must acknowledge an interrupt before the same
//      vector can be used again. The value written is ignored.
//  13: Completion status line address. When not set, interrupts are generated
//      to indicate command completion to the host. When this register is set,
//      command completion is indicated by writing the total number of write
//      commands completed to the status line address. Turn status writes ON
//      by setting bit 0 when writing register 13. Turn status writes OFF and
//      use interrupts instead by clearing bit 0 in this register.
//      


module csr_mgr
  #(
    parameter MAX_REQS_IN_FLIGHT = 32,
    parameter MAX_BURST_CNT = 8
    )
   (
    // CSR interface (MMIO on the host)
    ofs_plat_axi_mem_lite_if.to_source mmio64_to_afu,

    // Read engine control - initiate a read of num_lines from addr when enable is set.
    // Flow control is the host's responsibility, given the maximum number of
    // requests in flight and the host's knowledge of the number of uncompleted
    // commands.
    output copy_engine_pkg::t_rd_cmd rd_cmd,
    input  copy_engine_pkg::t_rd_state rd_state,

    // Write engine control - initiate a write of num_lines from addr when enable is set.
    // Write data comes from a read. For a given read/write pair, num_lines must match.
    output copy_engine_pkg::t_wr_cmd wr_cmd,
    input  copy_engine_pkg::t_wr_state wr_state
    );

    // Each interface names its associated clock and reset.
    logic clk;
    assign clk = mmio64_to_afu.clk;
    logic reset_n;
    assign reset_n = mmio64_to_afu.reset_n;


    // =========================================================================
    //
    //   CSR (MMIO) handling with AXI lite.
    //
    // =========================================================================

    //
    // The AXI lite interface is defined in
    // $OPAE_PLATFORM_ROOT/hw/lib/build/platform/ofs_plat_if/rtl/base_ifcs/axi/ofs_plat_axi_mem_lite_if.sv.
    // It contains fields defined by the AXI standard, though organized
    // slightly unusually. Instead of being a flat data structure, the
    // payload for each bus is a struct. The name of the AXI field is the
    // concatenation of the struct instance and field. E.g., AWADDR is
    // aw.addr. The use of structs makes it easier to bulk copy or bulk
    // initialize the full payload of a bus.
    //

    // The AFU ID is a unique ID for a given program.  Here we generated
    // one with the "uuidgen" program and stored it in the AFU's JSON file.
    // ASE and synthesis setup scripts automatically invoke afu_json_mgr
    // to extract the UUID into afu_json_info.vh.
    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    //
    // A valid AFU must implement a device feature list, starting at MMIO
    // address 0.  Every entry in the feature list begins with 5 64-bit
    // words: a device feature header, two AFU UUID words and two reserved
    // words.
    //

    // Use a copy of the MMIO interface as registers.
    ofs_plat_axi_mem_lite_if
      #(
        // PIM-provided macro to replicate identically sized instances of an
        // AXI lite interface.
        `OFS_PLAT_AXI_MEM_LITE_IF_REPLICATE_PARAMS(mmio64_to_afu)
        )
      mmio64_reg();

    // Is a CSR read request active this cycle? The test is simple because
    // the mmio64_reg.arvalid can only be set when the read response buffer
    // is empty.
    logic is_csr_read;
    assign is_csr_read = mmio64_reg.arvalid;

    // Is a CSR write request active this cycle?
    logic is_csr_write;
    assign is_csr_write = mmio64_reg.awvalid && mmio64_reg.wvalid;


    //
    // Receive MMIO read requests
    //

    // Ready for new request iff read request and response registers are empty
    assign mmio64_to_afu.arready = !mmio64_reg.arvalid && !mmio64_reg.rvalid;

    always_ff @(posedge clk)
    begin
        if (is_csr_read)
        begin
            // Current read request was handled
            mmio64_reg.arvalid <= 1'b0;
        end
        else if (mmio64_to_afu.arvalid && mmio64_to_afu.arready)
        begin
            // Receive new read request
            mmio64_reg.arvalid <= 1'b1;
            mmio64_reg.ar <= mmio64_to_afu.ar;
        end

        if (!reset_n) begin
            mmio64_reg.arvalid <= 1'b0;
        end
    end

    //
    // Decode register read addresses and respond with data.
    //

    assign mmio64_to_afu.rvalid = mmio64_reg.rvalid;
    assign mmio64_to_afu.r = mmio64_reg.r;

    always_ff @(posedge clk)
    begin
        if (is_csr_read)
        begin
            // New read response
            mmio64_reg.rvalid <= 1'b1;

            mmio64_reg.r <= '0;
            // The unique transaction ID matches responses to requests
            mmio64_reg.r.id <= mmio64_reg.ar.id;
            // Return user flags from request
            mmio64_reg.r.user <= mmio64_reg.ar.user;

            // AXI addresses are always in byte address space. Ignore the
            // low 3 bits to index 64 bit CSRs. Ignore high bits and let the
            // address space wrap.
            case (mmio64_reg.ar.addr[5:3])
              0: // AFU DFH (device feature header)
                begin
                    // Here we define a trivial feature list.  In this
                    // example, our AFU is the only entry in this list.
                    mmio64_reg.r.data <= '0;
                    // Feature type is AFU
                    mmio64_reg.r.data[63:60] <= 4'h1;
                    // End of list (last entry in list)
                    mmio64_reg.r.data[40] <= 1'b1;
                end

              // AFU_ID_L
              1: mmio64_reg.r.data <= afu_id[63:0];

              // AFU_ID_H
              2: mmio64_reg.r.data <= afu_id[127:64];

              // DFH_RSVD0
              3: mmio64_reg.r.data <= '0;

              // DFH_RSVD1
              4: mmio64_reg.r.data <= '0;

              // Platform information
              5: 
                begin
                    mmio64_reg.r.data <= '0;
                    // Maximum number of lines in a read or write burst
                    mmio64_reg.r.data[63:48] <= 16'(MAX_BURST_CNT);
                    // Maximum permitted number of requests in flight
                    mmio64_reg.r.data[47:32] <= 16'(MAX_REQS_IN_FLIGHT);
                    // Number of interrupt vectors available
                    mmio64_reg.r.data[31:24] <= 8'(`OFS_PLAT_PARAM_HOST_CHAN_NUM_INTR_VECS);
                    // Data bus width in bytes
                    mmio64_reg.r.data[23:16] <= 8'(ofs_plat_host_chan_pkg::DATA_WIDTH_BYTES);
                    // pClk frequency (MHz)
                    mmio64_reg.r.data[15:0] <= 16'(`OFS_PLAT_PARAM_CLOCKS_PCLK_FREQ);
                end

              6: mmio64_reg.r.data <= rd_state.num_lines_read;
              7: mmio64_reg.r.data <= wr_state.num_lines_write;

              default: mmio64_reg.r.data <= '0;
            endcase
        end
        else if (mmio64_to_afu.rready)
        begin
            // If a read response was pending it completed
            mmio64_reg.rvalid <= 1'b0;
        end

        if (!reset_n)
        begin
            mmio64_reg.rvalid <= 1'b0;
        end
    end


    //
    // CSR write handling.  Host software must tell the AFU the memory address
    // to which it should be writing.  The address is set by writing a CSR.
    //

    // Ready for new request iff write request register is empty. For simplicity,
    // not pipelined.
    assign mmio64_to_afu.awready = !mmio64_reg.awvalid && !mmio64_reg.bvalid;
    assign mmio64_to_afu.wready  = !mmio64_reg.wvalid && !mmio64_reg.bvalid;

    // Register incoming writes, waiting for both an address and a payload.
    always_ff @(posedge clk)
    begin
        if (is_csr_write)
        begin
            // Current write request was handled
            mmio64_reg.awvalid <= 1'b0;
            mmio64_reg.wvalid <= 1'b0;
        end
        else
        begin
            // Receive new write address
            if (mmio64_to_afu.awvalid && mmio64_to_afu.awready)
            begin
                mmio64_reg.awvalid <= 1'b1;
                mmio64_reg.aw <= mmio64_to_afu.aw;
            end

            // Receive new write data
            if (mmio64_to_afu.wvalid && mmio64_to_afu.wready)
            begin
                mmio64_reg.wvalid <= 1'b1;
                mmio64_reg.w <= mmio64_to_afu.w;
            end
        end

        if (!reset_n)
        begin
            mmio64_reg.awvalid <= 1'b0;
            mmio64_reg.wvalid <= 1'b0;
        end
    end

    // Generate a CSR write response once both address and data have arrived
    assign mmio64_to_afu.bvalid = mmio64_reg.bvalid;
    assign mmio64_to_afu.b = mmio64_reg.b;

    always_ff @(posedge clk)
    begin
        if (is_csr_write)
        begin
            // New write response
            mmio64_reg.bvalid <= 1'b1;

            mmio64_reg.b <= '0;
            mmio64_reg.b.id <= mmio64_reg.aw.id;
            mmio64_reg.b.user <= mmio64_reg.aw.user;
        end
        else if (mmio64_to_afu.bready)
        begin
            // If a write response was pending it completed
            mmio64_reg.bvalid <= 1'b0;
        end

        if (!reset_n)
        begin
            mmio64_reg.bvalid <= 1'b0;
        end
    end


    //
    // Decode CSR writes into read/write engine commands.
    //
    always_ff @(posedge clk)
    begin
        // There is no flow control on the module's outgoing read/write command
        // ports. If a request was trigger in the last cycle, it was sent.
        rd_cmd.enable <= 1'b0;
        wr_cmd.enable <= 1'b0;
        wr_cmd.intr_ack <= 1'b0;

        if (is_csr_write)
        begin
            // AXI addresses are always in byte address space. Ignore the
            // low 3 bits to index 64 bit CSRs. Ignore high bits and let the
            // address space wrap.
            case (mmio64_reg.aw.addr[6:3])
              // Read engine num_lines
              8: rd_cmd.num_lines <= mmio64_reg.w.data[$bits(rd_cmd.num_lines)-1 : 0];

              // Read start address
              9:
                begin
                    rd_cmd.addr <= mmio64_reg.w.data[$bits(rd_cmd.addr)-1 : 0];
                    // Trigger a host memory read
                    rd_cmd.enable <= 1'b1;
                end

              // Write engine num_lines and interrupt vector ID
              10:
                begin
                    wr_cmd.num_lines <= mmio64_reg.w.data[$bits(wr_cmd.num_lines)-1 : 0];
                    wr_cmd.intr_id <= mmio64_reg.w.data[32 +: $bits(wr_cmd.intr_id)];
                end

              // Write start address
              11:
                begin
                    wr_cmd.addr <= mmio64_reg.w.data[$bits(wr_cmd.addr)-1 : 0];
                    // Trigger a host memory write
                    wr_cmd.enable <= 1'b1;
                end

              // Interrupt ACK. The payload is ignored.
              12: wr_cmd.intr_ack <= 1'b1;

              // Completion status line config. When this is set, command completions
              // are indicated with writes to mem_status_addr instead of as interrupts.
              13:
                begin
                    // Bit 0 of the address is an enable flag
                    wr_cmd.use_mem_status <= mmio64_reg.w.data[0];
                    wr_cmd.mem_status_addr <= mmio64_reg.w.data[$bits(wr_cmd.mem_status_addr)-1 : 0];
                    wr_cmd.mem_status_addr[0] <= 1'b0;
                end
            endcase
        end
 
        if (!reset_n)
        begin
            rd_cmd.num_lines <= 1'b1;
            rd_cmd.enable <= 1'b0;
            wr_cmd.num_lines <= 1'b1;
            wr_cmd.enable <= 1'b0;
            wr_cmd.intr_ack <= 1'b0;
            wr_cmd.use_mem_status <= 1'b0;
        end
    end

    // synthesis translate_off
    always_ff @(posedge clk)
    begin
        if (rd_cmd.enable && reset_n)
        begin
            $display("CSR_MGR: Read 0x%0h lines, starting at addr 0x%0h",
                     rd_cmd.num_lines, rd_cmd.addr);
        end

        if (wr_cmd.enable && reset_n)
        begin
            $display("CSR_MGR: Write 0x%0h lines, starting at addr 0x%0h, %0s req comletion",
                     wr_cmd.num_lines, { wr_cmd.addr[$bits(wr_cmd.addr)-1 : 1], 1'b0 },
                     (wr_cmd.addr[0] ? "with" : "without"));
        end
    end
    // synthesis translate_on

endmodule
