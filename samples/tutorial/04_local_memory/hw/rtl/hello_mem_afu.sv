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
//
// Module Name:         hello_mem_afu.sv
// Project:             Hello Memory AFU
// Modified:            PSG - ADAPT
// Description:         Demonstrates simple transactions to DCP memory interface
//
// Hello_Mem_AFU is provided as as starting point for developing AFUs that
// transact with the external memory interface (EMIF). It lets you trigger
// transactions to EMIF using simple CCIP MMIO writes and reads.
//
// It is strongly recommended:
// - register all AFU inputs and outputs
// - output registers should be initialized with a reset
// - Host Writes and Reads must be sent on Virtual Channel (VC): VH0 - PCIe0 link
// - MMIO addressing must be QuardWord Aligned (Quadword = 8 bytes)
// - AFU_ID must be re-generated for new AFUs.
//
// Scratch_Reg[63:0] @ Byte Address 0x0080 is provided to test MMIO Reads and Writes to the AFU.
//
// Restrictions of Avalon memory interface (verify with Colleen)
// - No response status is supported
// - No support for posted writes
//

`include "platform_if.vh"
import local_mem_cfg_pkg::*;

module hello_mem_afu
  #(
    parameter NUM_LOCAL_MEM_BANKS = 2
    )
 (
        // ---------------------------global signals-------------------------------------------------
  input clk,
  input SoftReset,      //CCI interface reset. The Accelerator IP must use this Reset. ACTIVE HIGH

        // ---------------------------IF signals between CCI and AFU  --------------------------------
  input   t_if_ccip_Rx  cp2af_sRxPort,
  output  t_if_ccip_Tx  af2cp_sTxPort,

  // --------------------------- AMM signals
  output  t_local_mem_data  avs_writedata,
  input   t_local_mem_data  avs_readdata,
  output  t_local_mem_addr  avs_address,
  input   logic             avs_waitrequest,
  output  logic             avs_write,
  output  logic             avs_read,
  output  t_local_mem_byte_mask  avs_byteenable,
  output  t_local_mem_burst_cnt  avs_burstcount,
  input                     avs_readdatavalid,

  output logic [$clog2(NUM_LOCAL_MEM_BANKS)-1:0] mem_bank_select
);

  t_local_mem_data avm_writedata;
  t_local_mem_data avm_readdata;
  t_local_mem_byte_mask avm_byteenable;
  wire mem_testmode;
  wire         ready_for_sw_cmd;

  wire [4:0]   addr_test_status;
  wire         addr_test_done;

  t_local_mem_addr      avm_address;
  t_local_mem_burst_cnt avm_burstcount;
  wire [1:0]   avm_response;
  wire         avm_read;
  wire         avm_write;

  wire  [1:0]  rdwr_done;
  wire  [4:0]  rdwr_status;
  wire         rdwr_reset;

  wire  [2:0]  fsm_state;
  wire mem_error_clr;
  wire [31:0]  mem_errors;

  mem_csr
   #(
     .NUM_LOCAL_MEM_BANKS(NUM_LOCAL_MEM_BANKS)
     )
   csr
   (
    .clk                    (clk),
    .SoftReset              (SoftReset ),

    .cp2af_sRxPort          (cp2af_sRxPort),
    .af2cp_sTxPort          (af2cp_sTxPort),

    .avm_address            (avm_address),
    .avm_write              (avm_write),
    .avm_read               (avm_read),
    .avm_burstcount         (avm_burstcount),
    .avm_readdata           (avm_readdata),
    .avm_response           (avm_response),
    .avm_writedata          (avm_writedata),
    .avm_byteenable         (avm_byteenable),

    .mem_testmode           (mem_testmode),
    .addr_test_status       (addr_test_status),
    .addr_test_done         (addr_test_done),
    .rdwr_done              (rdwr_done),
    .rdwr_status            (rdwr_status),
    .rdwr_reset             (rdwr_reset),
    .fsm_state              (fsm_state),
    .mem_bank_select        (mem_bank_select),
    .ready_for_sw_cmd       (ready_for_sw_cmd),
    .mem_error_clr          (mem_error_clr),
    .mem_errors             (mem_errors)
   );

  mem_fsm fsm
   (
    .clk                    (clk ),
    .reset                  (SoftReset ),

     // AVL MM CSR Control Signals
    .avm_address            (avm_address),
    .avm_write              (avm_write),
    .avm_read               (avm_read),
    .avm_burstcount         (avm_burstcount),
    .avm_readdata           (avm_readdata),
    .avm_writedata          (avm_writedata),
    .avm_byteenable         (avm_byteenable),

    .mem_testmode           (mem_testmode),
    .addr_test_status       (addr_test_status),
    .addr_test_done         (addr_test_done),
    .rdwr_done              (rdwr_done),
    .rdwr_status            (rdwr_status),
    .rdwr_reset             (rdwr_reset),
    .fsm_state              (fsm_state),
    .ready_for_sw_cmd       (ready_for_sw_cmd),

     //AVL MM Master Interface
    .avs_writedata          (avs_writedata ),
    .avs_readdata           (avs_readdata ),
    .avs_address            (avs_address ),
    .avs_waitrequest        (avs_waitrequest ),
    .avs_write              (avs_write ),
    .avs_read               (avs_read ),
    .avm_response           (avm_response),
    .avs_byteenable         (avs_byteenable ),
    .avs_burstcount         (avs_burstcount),
    .avs_readdatavalid      (avs_readdatavalid),
    .mem_error_clr          (mem_error_clr),
    .mem_errors             (mem_errors)
   );

endmodule
