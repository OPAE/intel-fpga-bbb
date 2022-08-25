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
// Simple shell that instantiates a CSR controller and a local memory
// initiator.
//

`include "ofs_plat_if.vh"

module hello_mem_afu
  #(
    parameter NUM_LOCAL_MEM_BANKS = 2
    )
   (
    input  clk,
    input  reset_n,

    // CSR interface (MMIO on the host)
    ofs_plat_axi_mem_lite_if.to_source mmio64_to_afu,

    // Commands to local memory banks
    ofs_plat_avalon_mem_if.to_sink mem_cmd,

    output logic [$clog2(NUM_LOCAL_MEM_BANKS)-1:0] mem_bank_select
    );

    // This instance of an Avalon memory interface is used for forwarding
    // commands from the CSR controller to the FSM that will generate
    // commands to memory banks.
    ofs_plat_avalon_mem_if
      #(
        `LOCAL_MEM_AVALON_MEM_PARAMS_DEFAULT
        )
      mem_csr_to_fsm();

    logic mem_testmode;
    logic ready_for_sw_cmd;

    logic [4:0] addr_test_status;
    logic addr_test_done;

    logic [1:0] rdwr_done;
    logic [4:0] rdwr_status;
    logic rdwr_reset;

    logic [2:0] fsm_state;
    logic mem_error_clr;
    logic [31:0] mem_errors;

    //
    // The CSR interface takes commands from the host (via MMIO) and generates
    // requests to the local memory finite state machine.
    //
    mem_csr
      #(
        .NUM_LOCAL_MEM_BANKS(NUM_LOCAL_MEM_BANKS)
        )
      csr
       (
        .clk,
        .reset_n,

        .mmio64_to_afu,
        .mem_csr_to_fsm,

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

    //
    // Translate requests from the mem_csr module to commands to local memory.
    //
    mem_fsm fsm
       (
        .clk,
        .reset_n,

        // AVL MM CSR Control Signals
        .mem_csr_to_fsm,

        .mem_testmode           (mem_testmode),
        .addr_test_status       (addr_test_status),
        .addr_test_done         (addr_test_done),
        .rdwr_done              (rdwr_done),
        .rdwr_status            (rdwr_status),
        .rdwr_reset             (rdwr_reset),
        .fsm_state              (fsm_state),
        .ready_for_sw_cmd       (ready_for_sw_cmd),

        // Interface to local memory banks
        .mem_cmd,
        .mem_error_clr          (mem_error_clr),
        .mem_errors             (mem_errors)
        );

endmodule
