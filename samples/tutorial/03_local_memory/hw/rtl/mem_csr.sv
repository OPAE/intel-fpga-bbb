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

    // Interface signals between CCI and AFU
    input  t_if_ccip_Rx cp2af_sRxPort,
    output t_if_ccip_Tx af2cp_sTxPort,

    // Map CSR commands to requests to the memory FSM
    ofs_plat_avalon_mem_if.to_slave mem_csr_to_fsm,
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

    localparam AFU_ID_L              = 16'h0002;     // AFU ID Lower
    localparam AFU_ID_H              = 16'h0004;     // AFU ID Higher 
    localparam SCRATCH_REG           = 16'h0020;     // Scratch Register
    localparam MEM_ADDRESS           = 16'h0040;     // AVMM Master Address
    localparam MEM_BURSTCOUNT        = 16'h0042;     // AVMM Master Burst Count
    localparam MEM_RDWR              = 16'h0044;     // AVMM Master Read/Write
    localparam MEM_WRDATA            = 16'h0046;     // AVMM Master Write Data
    localparam MEM_RDDATA            = 16'h0048;     // AVMM Master Read Data
    localparam MEM_ADDR_TESTMODE     = 16'h004A;     // Test Control Register        
    localparam MEM_ADDR_TEST_STATUS  = 16'h0060;     // Test Status Register
    localparam MEM_RDWR_STATUS       = 16'h0062;
    localparam MEM_BANK_SELECT       = 16'h0064;     // Memory bank selection register
    localparam READY_FOR_SW_CMD      = 16'h0066;     // "Ready for sw cmd" register. S/w must poll this register before issuing a read/write command to fsm
    localparam MEM_BYTEENABLE        = 16'h0068;     // Test byteenable
    localparam MEM_ERRORS            = 16'h006A;

    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    typedef logic [mem_csr_to_fsm.ADDR_WIDTH-1 : 0] t_local_mem_addr;

    // cast c0 header into ReqMmioHdr
    t_ccip_c0_ReqMmioHdr mmioHdr;
    assign mmioHdr = t_ccip_c0_ReqMmioHdr'(cp2af_sRxPort.c0.hdr);

    logic [63:0] scratch_reg;
    logic [2:0] mem_RDWR;

    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            af2cp_sTxPort.c0 <= '0;
            af2cp_sTxPort.c1 <= '0;
            af2cp_sTxPort.c2 <= '0;

            scratch_reg <= '0;

            mem_csr_to_fsm.address    <= '0;
            mem_csr_to_fsm.read       <= '0;
            mem_csr_to_fsm.write      <= '0;
            mem_csr_to_fsm.burstcount <= 1;
            mem_csr_to_fsm.writedata  <= '0;

            mem_testmode   <= '0;
            mem_RDWR       <= '0;
            mem_testmode   <= '0;
            rdwr_reset     <= 1;
            mem_bank_select <= '0;
            mem_csr_to_fsm.byteenable <= '0;
            mem_error_clr  <= 0;
        end
        else
        begin
            rdwr_reset     <= 0;
            af2cp_sTxPort.c2.mmioRdValid <= 0;
            mem_csr_to_fsm.read  <= mem_RDWR[0] &  mem_RDWR[1]; //[0] enable [1] 0-WR,1-RD
            mem_csr_to_fsm.write <= mem_RDWR[0] & !mem_RDWR[1];

            // set the registers on MMIO write request
            // these are user-defined AFU registers at offset 0x40 and 0x41
            if(cp2af_sRxPort.c0.mmioWrValid == 1)
            begin
                case(mmioHdr.address)
                  SCRATCH_REG: scratch_reg <= cp2af_sRxPort.c0.data[63:0];
                  MEM_ADDRESS: mem_csr_to_fsm.address <= t_local_mem_addr'(cp2af_sRxPort.c0.data);
                  MEM_BURSTCOUNT: mem_csr_to_fsm.burstcount <= cp2af_sRxPort.c0.data[11:0];
                  MEM_RDWR: mem_RDWR <= cp2af_sRxPort.c0.data[2:0];
                  MEM_WRDATA: mem_csr_to_fsm.writedata <= {8{cp2af_sRxPort.c0.data[63:0]}};
                  MEM_ADDR_TESTMODE : mem_testmode <= cp2af_sRxPort.c0.data[0];
                  MEM_BANK_SELECT: mem_bank_select <= $bits(mem_bank_select)'(cp2af_sRxPort.c0.data);
                  // sw programmable byteenables
                  MEM_BYTEENABLE: mem_csr_to_fsm.byteenable <= cp2af_sRxPort.c0.data[63:0];
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

            // serve MMIO read requests
            if(cp2af_sRxPort.c0.mmioRdValid == 1)
            begin
                af2cp_sTxPort.c2.hdr.tid <= mmioHdr.tid; // copy TID
                case(mmioHdr.address)
                  // AFU header
                  16'h0000: af2cp_sTxPort.c2.data <= {
                                                      4'b0001, // Feature type = AFU
                                                      8'b0,    // reserved
                                                      4'b0,    // afu minor revision = 0
                                                      7'b0,    // reserved
                                                      1'b1,    // end of DFH list = 1 
                                                      24'b0,   // next DFH offset = 0
                                                      4'b0,    // afu major revision = 0
                                                      12'b0    // feature ID = 0
                                                      };            
                  AFU_ID_L:             af2cp_sTxPort.c2.data <= afu_id[63:0];   // afu id low
                  AFU_ID_H:             af2cp_sTxPort.c2.data <= afu_id[127:64]; // afu id hi
                  16'h0006:             af2cp_sTxPort.c2.data <= 64'h0; // next AFU
                  16'h0008:             af2cp_sTxPort.c2.data <= 64'h0; // reserved
                  SCRATCH_REG:          af2cp_sTxPort.c2.data <= scratch_reg; // Scratch Register
                  MEM_ADDRESS:          af2cp_sTxPort.c2.data <= 64'(mem_csr_to_fsm.address);
                  MEM_BURSTCOUNT:       af2cp_sTxPort.c2.data <= 64'(mem_csr_to_fsm.burstcount);
                  MEM_RDWR:             af2cp_sTxPort.c2.data <= {62'd0, mem_RDWR};
                  MEM_WRDATA:           af2cp_sTxPort.c2.data <= mem_csr_to_fsm.writedata;
                  MEM_RDDATA:           af2cp_sTxPort.c2.data <= mem_csr_to_fsm.readdata; 
                  MEM_ADDR_TESTMODE:    af2cp_sTxPort.c2.data <= 64'(mem_testmode);
                  MEM_ADDR_TEST_STATUS: af2cp_sTxPort.c2.data <= 64'({NUM_LOCAL_MEM_BANKS,
                                                                      16'({addr_test_done, 3'd0, addr_test_status})});
                  READY_FOR_SW_CMD:     af2cp_sTxPort.c2.data <= ready_for_sw_cmd;
                  MEM_BYTEENABLE:       af2cp_sTxPort.c2.data <= mem_csr_to_fsm.byteenable;
                  // MEM_ERRORs records the count of memory errors during the transfer
                  MEM_ERRORS:           af2cp_sTxPort.c2.data <= mem_errors;
                  MEM_RDWR_STATUS:
                    begin 
                        af2cp_sTxPort.c2.data <= {54'd0,
                                                  fsm_state,         // 9:7
                                                  rdwr_done[1],      //   6
                                                  rdwr_status[3:2],  // 5:4
                                                  1'b0,              //   3
                                                  rdwr_done[0],      //   2
                                                  rdwr_status[1:0]}; // 1:0
                        rdwr_reset     <= 1;
                    end 
                  MEM_BANK_SELECT:  af2cp_sTxPort.c2.data <= 64'(mem_bank_select);
                  default:  af2cp_sTxPort.c2.data <= 64'h0;
                endcase

                af2cp_sTxPort.c2.mmioRdValid <= 1; // post response
            end
            else
            begin
                if (mem_csr_to_fsm.read | mem_csr_to_fsm.write) mem_RDWR[0] <= 0;
            end 
        end
    end
endmodule
