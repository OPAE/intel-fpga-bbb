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
// Translate commands from the CSR engine into commands to local memory banks.
//

typedef enum logic[2:0] { IDLE,
                          TEST_WRITE,
                          TEST_READ,
                          RD_REQ,
                          RD_RSP,
                          WR_REQ,
                          WR_RSP } state_t;

module mem_fsm
   (
    input  clk,
    input  reset_n,

    // Commands to local memory banks
    ofs_plat_avalon_mem_if.to_sink mem_cmd,

    // AVL MM CSR Control Signals
    ofs_plat_avalon_mem_if.to_master mem_csr_to_fsm,

    input  logic mem_testmode,
    output logic [4:0] addr_test_status,
    output logic addr_test_done,
    output logic [1:0] rdwr_done,
    output logic [4:0] rdwr_status,
    input  logic rdwr_reset,
    output state_t fsm_state,
    output logic ready_for_sw_cmd,

    output logic [31:0] mem_errors,
    input  logic mem_error_clr
    );

    parameter ADDRESS_MAX_BIT = 6;

    state_t state;
    assign fsm_state = state;

    logic [32:0] address;
    assign mem_cmd.burstcount = mem_csr_to_fsm.burstcount;
    logic  [3:0] max_reads;
    logic [mem_cmd.BURST_CNT_WIDTH-1 : 0] burstcount;
    logic avs_readdatavalid_1;

    assign mem_cmd.address = mem_testmode? {'0, address[ADDRESS_MAX_BIT-1:0]}: mem_csr_to_fsm.address;
    assign mem_cmd.writedata = mem_csr_to_fsm.writedata;
    assign mem_cmd.byteenable = mem_csr_to_fsm.byteenable;

    function automatic logic [511:0] get_mask (logic [63:0] byteenable);
        logic [511:0] mask;
        for(int i=0; i<64; i++)
        begin
            mask[i*8 +: 8] = byteenable[i] ? {8{1'b1}}: {8{1'b0}};
        end
        return mask;
    endfunction

    // record memory errors
    always_ff @(posedge clk)
    begin
        if (!reset_n | mem_error_clr)
        begin
            mem_errors <= 0;
        end
        else if (mem_cmd.readdatavalid &&
                 ((mem_cmd.readdata & get_mask(mem_cmd.byteenable)) !=
                  (mem_csr_to_fsm.writedata & get_mask(mem_cmd.byteenable))))
        begin
            mem_errors <= mem_errors+1;
        end
    end

    assign mem_csr_to_fsm.response = '0;
    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            address <= '0;
            mem_cmd.write <= 1'b0;
            mem_cmd.read <= 1'b0;
            state <= IDLE;
            addr_test_done <= 1'b0;
            burstcount <= 1;
            ready_for_sw_cmd <= 0;
        end
        else
        begin
            case(state)
              IDLE:
                begin
                    ready_for_sw_cmd <= 1;
                    if (mem_testmode & ~addr_test_done)
                    begin
                        mem_cmd.write <= 1;
                        state <= TEST_WRITE;
                        ready_for_sw_cmd <= 0;
                    end else if (mem_csr_to_fsm.write)
                    begin
                        mem_cmd.write <= 1;
                        state <= WR_REQ;
                        ready_for_sw_cmd <= 0;
                    end else if (mem_csr_to_fsm.read)
                    begin
                        mem_cmd.read <= 1;
                        state <= RD_REQ;
                        ready_for_sw_cmd <= 0;
                    end
                end

              TEST_WRITE:
                begin
                    if (~mem_cmd.waitrequest)
                    begin
                        if (address == {ADDRESS_MAX_BIT{1'b1}})
                        begin
                            state <= TEST_READ;
                            mem_cmd.write <= 0;
                            mem_cmd.read <= 1;
                            address <= 0;
                        end
                        else
                        begin
                            address <= address + 1;
                            mem_cmd.write <= 1;
                        end
                    end
                end

              TEST_READ:
                begin
                    if (~mem_cmd.waitrequest)
                    begin
                        if (address == {ADDRESS_MAX_BIT{1'b1}})
                        begin
                            state <= IDLE;
                            mem_cmd.read <= 0;
                            addr_test_done <= 1;
                        end
                        else if (mem_cmd.readdatavalid)
                        begin
                            address <= address + 1;
                            mem_cmd.read <= 1;
                        end
                        else
                        begin
                            mem_cmd.read <= 0;
                        end
                    end
                end

              WR_REQ:
                begin //AVL MM Posted Write
                    if (~mem_cmd.waitrequest)
                    begin
                        if (mem_cmd.burstcount == burstcount )
                        begin
                            state <= WR_RSP;
                            mem_cmd.write <= 0;
                            burstcount <= 1;
                        end
                        else
                        begin
                            burstcount <= burstcount + 1;
                        end
                    end
                end

              WR_RSP:
                begin // wait for write response
                    state <= IDLE;
                end

              RD_REQ:
                begin // AVL MM Read non-posted
                    if (~mem_cmd.waitrequest)
                    begin
                        state <= RD_RSP;
                        mem_cmd.read <= 0;
                    end
                end

              RD_RSP:
                begin
                    if (mem_cmd.readdatavalid)
                    begin
                        if (burstcount == mem_cmd.burstcount)
                        begin
                            state <= IDLE;
                            burstcount <= 1;
                        end
                        else
                        begin
                            burstcount <= burstcount + 1;
                        end
                    end
                end
            endcase
        end // end else !reset_n
    end // posedge clk

    always_ff @(posedge clk)
    begin
        avs_readdatavalid_1 <= mem_cmd.readdatavalid;

        if (mem_cmd.readdatavalid)
            mem_csr_to_fsm.readdata <= 64'(mem_cmd.readdata);

        if (!reset_n)
            addr_test_status <= 0;
        else
        begin
            if (mem_cmd.readdatavalid)
            begin
                if (addr_test_done)
                    addr_test_status[1:0] <= 0;
                else if (avs_readdatavalid_1 &&
                         (mem_csr_to_fsm.readdata == mem_csr_to_fsm.writedata) &&
                         (state == TEST_READ))
                begin
                    addr_test_status[2] <= 1;
                end
            end

            if (state == TEST_WRITE)
            begin
                addr_test_status[2] <= 0;
            end
        end
    end

    always_ff @(posedge clk)
    begin
        if (rdwr_reset & (state != RD_RSP))
        begin
            rdwr_status <= '0;
            rdwr_done   <= '0;
        end
        else if (state == WR_RSP)
        begin
            rdwr_status[1:0] <= 0;
            rdwr_done[0] <= 1;
        end
        else if ((state == RD_RSP) & (mem_cmd.readdatavalid == 1))
        begin
            if (mem_cmd.burstcount == burstcount)
                rdwr_done[1] <= 1;
            if (~rdwr_status[3])
                rdwr_status[3:2] <= 0;
        end
    end

    always_ff @(posedge clk)
    begin
        if (!reset_n)
            max_reads <= 0;
        else if (mem_cmd.read == 1 & mem_cmd.readdatavalid == 0 & ~mem_cmd.waitrequest)
            max_reads <= max_reads + 1;
        else if (mem_cmd.readdatavalid == 1 & ((~mem_cmd.waitrequest& ~mem_cmd.read ) || (mem_cmd.waitrequest&mem_cmd.read)))
            max_reads <= max_reads - 1;
    end

endmodule
