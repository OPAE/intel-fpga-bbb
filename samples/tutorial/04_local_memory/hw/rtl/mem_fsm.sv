// ***************************************************************************
// Copyright (c) 2013-2017, Intel Corporation All Rights Reserved.
// The source code contained or described herein and all  documents related to
// the  source  code  ("Material")  are  owned by  Intel  Corporation  or  its
// suppliers  or  licensors.    Title  to  the  Material  remains  with  Intel
// Corporation or  its suppliers  and licensors.  The Material  contains trade
// secrets and  proprietary  and  confidential  information  of  Intel or  its
// suppliers and licensors.  The Material is protected  by worldwide copyright
// and trade secret laws and treaty provisions. No part of the Material may be
// copied,    reproduced,    modified,    published,     uploaded,     posted,
// transmitted,  distributed,  or  disclosed  in any way without Intel's prior
// express written permission.
// ***************************************************************************
// TODO future improvements move sticky registers to HSL module implmentation

`include "platform_if.vh"
import local_mem_cfg_pkg::*;

typedef enum logic[2:0] { IDLE,
                          TEST_WRITE,
                          TEST_READ,
                          RD_REQ,
                          RD_RSP,
                          WR_REQ,
                          WR_RSP } state_t;

module mem_fsm
 (
	// ---------------------------global signals-------------------------------------------------
  input	clk,
  input	reset,

  // - AMM Master Signals signals
  output t_local_mem_data avs_writedata,
  input	 t_local_mem_data avs_readdata,
  output t_local_mem_addr avs_address,
  input	 logic	          avs_waitrequest,
  output logic            avs_write,
  output logic            avs_read,
  output t_local_mem_byte_mask    avs_byteenable,
  output t_local_mem_burst_cnt    avs_burstcount,

  input                   avs_readdatavalid,

  // AVL MM CSR Control Signals
  input t_local_mem_addr avm_address,
  input                  avm_write,
  input                  avm_read,
  input t_local_mem_data avm_writedata,
  input t_local_mem_burst_cnt avm_burstcount,
  output t_local_mem_data avm_readdata,
  output logic [1:0]     avm_response,
  input t_local_mem_byte_mask avm_byteenable,

  input                  mem_testmode,
  output logic [4:0]     addr_test_status,
  output logic           addr_test_done,
  output logic [1:0]     rdwr_done,
  output logic [4:0]     rdwr_status,
  input                  rdwr_reset,
  output state_t         fsm_state,
  output logic           ready_for_sw_cmd,

  output reg [31:0]      mem_errors,
  input                  mem_error_clr
);

parameter ADDRESS_MAX_BIT = 10;

state_t state;
assign fsm_state = state;

logic [32:0] address;
assign avs_burstcount = avm_burstcount;
logic  [3:0] max_reads = 0;
t_local_mem_burst_cnt burstcount;
logic avs_readdatavalid_1 = 0;

assign avs_address = mem_testmode? {'0, address[ADDRESS_MAX_BIT-1:0]}: avm_address;
assign avs_writedata = avm_writedata;
assign avs_byteenable = avm_byteenable;

function automatic logic [511:0] get_mask (logic [63:0] byteenable);
  logic [511:0] mask;
  for(int i=0; i<64; i++) begin
    mask[i*8 +: 8] = byteenable[i]? {8{1'b1}}:
                                    {8{1'b0}};
  end
  return mask;
endfunction

// record memory errors

always_ff @(posedge clk) begin
  if(reset | mem_error_clr)
    mem_errors <= 0;
  else
    if(avs_readdatavalid && ((avs_readdata & get_mask(avs_byteenable)) != (avm_writedata & get_mask(avs_byteenable))))
      mem_errors <= mem_errors+1;
end

assign avm_response = '0;
always_ff @(posedge clk) begin
  if(reset) begin
    address        <= '0;
    avs_write      <= '0;
    avs_read       <= 0;
    state          <= IDLE;
    addr_test_done <= '0;
    burstcount     <= 1;
    ready_for_sw_cmd <= 0;
  end
  else begin
    case(state)
      IDLE: begin
        ready_for_sw_cmd <= 1;
        if (mem_testmode & ~addr_test_done)begin
          avs_write <= 1;
          state <= TEST_WRITE;
          ready_for_sw_cmd <= 0;
        end else if (avm_write) begin
          avs_write <= 1;
          state <= WR_REQ;
          ready_for_sw_cmd <= 0;
        end else if (avm_read) begin
          avs_read <= 1;
          state <= RD_REQ;
          ready_for_sw_cmd <= 0;
        end
      end

      TEST_WRITE: begin
        if (~avs_waitrequest) begin
          if (address == {ADDRESS_MAX_BIT{1'b1}}) begin
            state <= TEST_READ;
            avs_write <= 0;
            avs_read <= 1;
            address <= 0;
          end
          else begin
            address <= address + 1;
            avs_write <= 1;
          end
        end
      end

      TEST_READ: begin
        if (~avs_waitrequest) begin
          if (address == {ADDRESS_MAX_BIT{1'b1}}) begin
            state <= IDLE;
            avs_read <= 0;
            addr_test_done <= 1;
          end else if (avs_readdatavalid) begin
            address <= address + 1;
            avs_read <= 1;
          end
          else begin
            avs_read <= 0;
          end
        end
      end

      WR_REQ: begin //AVL MM Posted Write
        if (~avs_waitrequest) begin
          if (avs_burstcount == burstcount ) begin
            state <= WR_RSP;
            avs_write <= 0;
            burstcount <= 1;
          end else
            burstcount++;
        end
      end

      WR_RSP: begin // wait for write response
        state <= IDLE;
      end

      RD_REQ: begin // AVL MM Read non-posted
        if (~avs_waitrequest) begin
          state <= RD_RSP;
          avs_read <= 0;
        end
      end

      RD_RSP: begin
        if (avs_readdatavalid) begin
          if (burstcount == avs_burstcount) begin
            state <= IDLE;
            burstcount <= 1;
          end
          else begin
            burstcount++;
          end
        end
      end
    endcase
  end // end else reset
end // posedge clk

always_ff @(posedge clk) begin
  avs_readdatavalid_1 <= avs_readdatavalid;

  if (avs_readdatavalid)
    avm_readdata <= 64'(avs_readdata);

  if(reset)
    addr_test_status <= 0;
  else begin
    if (avs_readdatavalid & addr_test_done)
      addr_test_status[1:0] <= 0;//avs_response;
    else if (avs_readdatavalid)
      if (avs_readdatavalid_1 & (avm_readdata == avm_writedata))
        if (state == TEST_READ)
          addr_test_status[2] <= 1;
        if (state == TEST_WRITE)
          addr_test_status[2] <= 0;
  end
end

always_ff @(posedge clk) begin
  if (rdwr_reset & (state != RD_RSP)) begin
    rdwr_status <= '0;
    rdwr_done   <= '0;
  end
  else if (state == WR_RSP) begin
    rdwr_status[1:0] <= 0;//avs_response;
    rdwr_done[0] <= 1;
  end
  else if ((state == RD_RSP) & (avs_readdatavalid == 1)) begin
    if(avs_burstcount == burstcount)
      rdwr_done[1] <= 1;
      if (~rdwr_status[3])
        rdwr_status[3:2] <= 0;//avs_response;
  end
end

always_ff @(posedge clk) begin
  if (reset)
    max_reads <= 0;
  else  if (avs_read == 1 & avs_readdatavalid == 0 & ~avs_waitrequest)
    max_reads++;
  else if (avs_readdatavalid == 1 & ((~avs_waitrequest& ~avs_read ) || (avs_waitrequest&avs_read)))
    max_reads <= max_reads - 1;
end

endmodule
