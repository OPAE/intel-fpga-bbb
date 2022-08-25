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
// Implement a basic AFU CSR space, including a set of commands for generating
// local memory requests.
//

`include "ofs_plat_if.vh"
`include "afu_json_info.vh"

module mem_csr
  #(
    parameter NUM_LOCAL_MEM_BANKS = 2
    )
   (
    input  clk,
    input  reset_n,

    // CSR interface (MMIO on the host)
    ofs_plat_axi_mem_lite_if.to_source mmio64_to_afu,

    // Map CSR commands to requests to the memory FSM
    ofs_plat_avalon_mem_if.to_sink mem_csr_to_fsm,
    input  logic [31:0] mem_errors,
    output logic mem_error_clr,

    // control and status
    output logic mem_testmode,
    input  logic [4:0] addr_test_status,
    input  logic addr_test_done, 
    input  logic [1:0] rdwr_done,  
    input  logic [4:0] rdwr_status, 
    output logic rdwr_reset,
    input  logic [2:0] fsm_state,
    output logic [$clog2(NUM_LOCAL_MEM_BANKS)-1:0] mem_bank_select,
    input  logic ready_for_sw_cmd
    );

    localparam AFU_ID_L              = 8'h02;     // AFU ID Lower
    localparam AFU_ID_H              = 8'h04;     // AFU ID Higher 
    localparam SCRATCH_REG           = 8'h20;     // Scratch Register
    localparam MEM_ADDRESS           = 8'h40;     // AVMM Master Address
    localparam MEM_BURSTCOUNT        = 8'h42;     // AVMM Master Burst Count
    localparam MEM_RDWR              = 8'h44;     // AVMM Master Read/Write
    localparam MEM_WRDATA            = 8'h46;     // AVMM Master Write Data
    localparam MEM_RDDATA            = 8'h48;     // AVMM Master Read Data
    localparam MEM_ADDR_TESTMODE     = 8'h4A;     // Test Control Register        
    localparam MEM_ADDR_TEST_STATUS  = 8'h60;     // Test Status Register
    localparam MEM_RDWR_STATUS       = 8'h62;
    localparam MEM_BANK_SELECT       = 8'h64;     // Memory bank selection register
    localparam READY_FOR_SW_CMD      = 8'h66;     // "Ready for sw cmd" register. S/w must poll this register before issuing a read/write command to fsm
    localparam MEM_BYTEENABLE        = 8'h68;     // Test byteenable
    localparam MEM_ERRORS            = 8'h6A;

    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    typedef logic [mem_csr_to_fsm.ADDR_WIDTH-1 : 0] t_local_mem_addr;
    logic [63:0] scratch_reg;
    logic [2:0] mem_RDWR;

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
    // Implement the device feature list by responding to MMIO reads.
    //

    assign mmio64_to_afu.rvalid = mmio64_reg.rvalid;
    assign mmio64_to_afu.r = mmio64_reg.r;

    always_ff @(posedge clk)
    begin
        rdwr_reset <= 0;

        if (is_csr_read)
        begin
            // New read response
            mmio64_reg.rvalid <= 1'b1;

            mmio64_reg.r <= '0;
            // The unique transaction ID matches responses to requests
            mmio64_reg.r.id <= mmio64_reg.ar.id;
            // Return user flags from request
            mmio64_reg.r.user <= mmio64_reg.ar.user;

            // AXI addresses are always in byte address space. The address
            // offset localparams are to 32 bit words.
            case (mmio64_reg.ar.addr[2 +: 8])
              // AFU header
              8'h00: mmio64_reg.r.data <= {
                                            4'b0001, // Feature type = AFU
                                            8'b0,    // reserved
                                            4'b0,    // afu minor revision = 0
                                            7'b0,    // reserved
                                            1'b1,    // end of DFH list = 1 
                                            24'b0,   // next DFH offset = 0
                                            4'b0,    // afu major revision = 0
                                            12'b0    // feature ID = 0
                                            };            
              AFU_ID_L:             mmio64_reg.r.data <= afu_id[63:0];   // afu id low
              AFU_ID_H:             mmio64_reg.r.data <= afu_id[127:64]; // afu id hi
              8'h06:                mmio64_reg.r.data <= 64'h0; // next AFU
              8'h08:                mmio64_reg.r.data <= 64'h0; // reserved
              SCRATCH_REG:          mmio64_reg.r.data <= scratch_reg; // Scratch Register
              MEM_ADDRESS:          mmio64_reg.r.data <= 64'(mem_csr_to_fsm.address);
              MEM_BURSTCOUNT:       mmio64_reg.r.data <= 64'(mem_csr_to_fsm.burstcount);
              MEM_RDWR:             mmio64_reg.r.data <= {62'd0, mem_RDWR};
              MEM_WRDATA:           mmio64_reg.r.data <= mem_csr_to_fsm.writedata;
              MEM_RDDATA:           mmio64_reg.r.data <= mem_csr_to_fsm.readdata; 
              MEM_ADDR_TESTMODE:    mmio64_reg.r.data <= 64'(mem_testmode);
              MEM_ADDR_TEST_STATUS: mmio64_reg.r.data <= 64'({NUM_LOCAL_MEM_BANKS,
                                                             16'({addr_test_done, 3'd0, addr_test_status})});
              READY_FOR_SW_CMD:     mmio64_reg.r.data <= ready_for_sw_cmd;
              MEM_BYTEENABLE:       mmio64_reg.r.data <= mem_csr_to_fsm.byteenable;
              // MEM_ERRORs records the count of memory errors during the transfer
              MEM_ERRORS:           mmio64_reg.r.data <= mem_errors;
              MEM_RDWR_STATUS:
                begin 
                    mmio64_reg.r.data <= {54'd0,
                                          fsm_state,         // 9:7
                                          rdwr_done[1],      //   6
                                          rdwr_status[3:2],  // 5:4
                                          1'b0,              //   3
                                          rdwr_done[0],      //   2
                                          rdwr_status[1:0]}; // 1:0
                    rdwr_reset <= 1;
                end 
              MEM_BANK_SELECT:      mmio64_reg.r.data <= 64'(mem_bank_select);
              default:              mmio64_reg.r.data <= '0;
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
            rdwr_reset <= 1;
        end
    end


    //
    // CSR write handling.  Host software must tell the AFU the memory address
    // to which it should be writing.  The address is set by writing a CSR.
    //

    // Ready for new request iff write request register is empty
    assign mmio64_to_afu.awready = !mmio64_reg.awvalid && !mmio64_reg.bvalid;
    assign mmio64_to_afu.wready  = !mmio64_reg.wvalid && !mmio64_reg.bvalid;

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

    // Write response
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

    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            scratch_reg <= '0;

            mem_csr_to_fsm.address    <= '0;
            mem_csr_to_fsm.read       <= '0;
            mem_csr_to_fsm.write      <= '0;
            mem_csr_to_fsm.burstcount <= 1;
            mem_csr_to_fsm.writedata  <= '0;

            mem_testmode   <= '0;
            mem_RDWR       <= '0;
            mem_testmode   <= '0;
            mem_bank_select <= '0;
            mem_csr_to_fsm.byteenable <= '0;
            mem_error_clr  <= 0;
        end
        else
        begin
            mem_csr_to_fsm.read  <= mem_RDWR[0] &  mem_RDWR[1]; //[0] enable [1] 0-WR,1-RD
            mem_csr_to_fsm.write <= mem_RDWR[0] & !mem_RDWR[1];
            mem_RDWR[0] <= 0;

            // set the registers on MMIO write request
            // these are user-defined AFU registers at offset 0x40 and 0x41
            if (is_csr_write)
            begin
                case (mmio64_reg.aw.addr[2 +: 8])
                  SCRATCH_REG: scratch_reg <= mmio64_reg.w.data[63:0];
                  MEM_ADDRESS: mem_csr_to_fsm.address <= t_local_mem_addr'(mmio64_reg.w.data);
                  MEM_BURSTCOUNT: mem_csr_to_fsm.burstcount <= mmio64_reg.w.data[11:0];
                  MEM_RDWR: mem_RDWR <= mmio64_reg.w.data[2:0];
                  MEM_WRDATA: mem_csr_to_fsm.writedata <= {8{mmio64_reg.w.data[63:0]}};
                  MEM_ADDR_TESTMODE : mem_testmode <= mmio64_reg.w.data[0];
                  MEM_BANK_SELECT: mem_bank_select <= $bits(mem_bank_select)'(mmio64_reg.w.data);
                  // sw programmable byteenables
                  MEM_BYTEENABLE: mem_csr_to_fsm.byteenable <= mmio64_reg.w.data[63:0];
                  // write any value to MEM_ERRORS register to clear errors
                  MEM_ERRORS: mem_error_clr <= 1'b1;
                endcase
            end
            else
            begin
                mem_error_clr <= 0;
            end

            if (addr_test_done == 1)
            begin
                mem_testmode <= 0;
            end
        end
    end
endmodule
