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
`include "afu_json_info.vh"

//
// Avalon-MM version of hello world AFU example.
//

module hello_world_avalon
   (
    // CSR interface (MMIO on the host) -- normal Avalon memory
    ofs_plat_avalon_mem_if.to_source mmio64_to_afu,

    // Host memory (DMA) using an Avalon memory interface that has been
    // modified slightly to separate the read and write request channels.
    // The PIM and FIM take advantage of the separation to optimize
    // mapping to the host channel.
    ofs_plat_avalon_mem_rdwr_if.to_sink host_mem
    );

    // Each interface names its associated clock and reset.
    logic clk;
    assign clk = host_mem.clk;
    logic reset_n;
    assign reset_n = host_mem.reset_n;


    // =========================================================================
    //
    //   CSR (MMIO) handling with Avalon.
    //
    // =========================================================================

    //
    // The Avalon interface is defined in
    // $OPAE_PLATFORM_ROOT/hw/lib/build/platform/ofs_plat_if/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_if.sv.
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

    // Is a CSR read request active this cycle?
    logic is_csr_read;
    assign is_csr_read = mmio64_to_afu.read;

    // Is a CSR write request active this cycle?
    logic is_csr_write;
    assign is_csr_write = mmio64_to_afu.write;


    //
    // Receive MMIO read requests
    //

    // Always ready for a new CSR request
    assign mmio64_to_afu.waitrequest = 1'b0;

    //
    // Implement the device feature list by responding to MMIO reads.
    //
    always_ff @(posedge clk)
    begin
        // New read response? Avalon responses have no flow control.
        mmio64_to_afu.readdatavalid <= is_csr_read;

        mmio64_to_afu.response <= '0;
        mmio64_to_afu.readresponseuser <= mmio64_to_afu.user;

        // Avalon addresses are in the space of the data bus width.
        case (mmio64_to_afu.address[2:0])
          0: // AFU DFH (device feature header)
            begin
                // Here we define a trivial feature list.  In this
                // example, our AFU is the only entry in this list.
                mmio64_to_afu.readdata <= '0;
                // Feature type is AFU
                mmio64_to_afu.readdata[63:60] <= 4'h1;
                // End of list (last entry in list)
                mmio64_to_afu.readdata[40] <= 1'b1;
            end

          // AFU_ID_L
          1: mmio64_to_afu.readdata <= afu_id[63:0];

          // AFU_ID_H
          2: mmio64_to_afu.readdata <= afu_id[127:64];

          // DFH_RSVD0
          3: mmio64_to_afu.readdata <= '0;

          // DFH_RSVD1
          4: mmio64_to_afu.readdata <= '0;

          default: mmio64_to_afu.readdata <= '0;
        endcase

        if (!reset_n)
        begin
            mmio64_to_afu.readdatavalid <= 1'b0;
        end
    end


    //
    // CSR write handling. Host software must tell the AFU the memory address
    // to which it should be writing. The address is set by writing a CSR.
    //

    // Write response
    always_ff @(posedge clk)
    begin
        mmio64_to_afu.writeresponsevalid <= is_csr_write;
        mmio64_to_afu.writeresponse <= '0;
        mmio64_to_afu.writeresponseuser <= mmio64_to_afu.user;

        if (!reset_n)
        begin
            mmio64_to_afu.writeresponsevalid <= 1'b0;
        end
    end

    // We use MMIO address 0 to set the memory address.  The read and
    // write MMIO spaces are logically separate so we are free to use
    // whatever we like.  This may not be good practice for cleanly
    // organizing the MMIO address space, but it is legal.
    logic is_mem_addr_csr_write;
    assign is_mem_addr_csr_write = is_csr_write && (mmio64_to_afu.address == '0);

    // DMA address to which this AFU will write.
    localparam MEM_ADDR_WIDTH = ofs_plat_host_chan_pkg::ADDR_WIDTH_LINES;
    typedef logic [MEM_ADDR_WIDTH-1 : 0] t_mem_addr;
    t_mem_addr mem_addr;

    always_ff @(posedge clk)
    begin
        if (is_mem_addr_csr_write)
        begin
            // The host passes in a line address.
            mem_addr <= t_mem_addr'(mmio64_to_afu.writedata);
        end
    end


    // =========================================================================
    //
    //   Main AFU logic
    //
    // =========================================================================

    //
    // States in our simple example.
    //
    typedef enum logic [0:0]
    {
        STATE_IDLE,
        STATE_RUN
    }
    t_state;

    t_state state;

    //
    // State machine
    //
    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            state <= STATE_IDLE;
        end
        else
        begin
            // Trigger the AFU when mem_addr is set above.  (When the CPU
            // tells us the address to which the FPGA should write a message.)
            if ((state == STATE_IDLE) && is_mem_addr_csr_write)
            begin
                state <= STATE_RUN;
                $display("AFU running...");
            end

            // The AFU completes its task by writing a single line.  When
            // the line is written return to idle.  The write will happen
            // as long as the request channel is not full.
            if ((state == STATE_RUN) && !host_mem.wr_waitrequest)
            begin
                state <= STATE_IDLE;
                $display("AFU done...");
            end
        end
    end

    //
    // Write "Hello world!" to memory when in STATE_RUN.
    //
    always_comb
    begin
        host_mem.wr_write = (state == STATE_RUN);
        host_mem.wr_address = mem_addr;
        host_mem.wr_writedata = 'h0021646c726f77206f6c6c6548;
        host_mem.wr_burstcount = 1'b1;
        host_mem.wr_byteenable = ~64'b0;	// Byte mask (enable all)
        host_mem.wr_user = '0;
    end


    //
    // This AFU never makes a read request.
    //
    assign host_mem.rd_read = 1'b0;

endmodule
