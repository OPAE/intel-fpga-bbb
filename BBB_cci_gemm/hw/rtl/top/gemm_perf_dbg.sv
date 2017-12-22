//
// Copyright (c) 2017, Intel Corporation
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

`include "vendor_defines.vh"
import ccip_if_pkg::*;
module gemm_perf_dbg (
  input  logic        clk                             , // adf
  input  logic        rst                             , //sfda
  input  logic        i_go                            , ///adf
  `ifdef PERF_DBG_PERFORMANCE
  // Performance INPUT
  input  logic        i_req_rd_rsp_valid              ,
  input  logic        i_req_wr_rsp_valid              ,
  input  logic        i_req_read_mem_almfull          ,
  input  logic        i_req_write_mem_almfull         ,
  input  logic        i_ctl_gen_read_pe_stall_a_loaded,
  input  logic        i_ctl_gen_read_pe_stall_b_loaded,
  input  logic        i_ctl_gen_write_pe_stall        ,
  input  logic        i_ctl_gen_pe_compute            ,
                                                        // Performance OUTPUT
  output logic [63:0] csr_read_bw                     ,
  output logic [63:0] csr_write_bw                    ,
  output logic [63:0] csr_read_pe_stall               ,
  output logic [63:0] csr_write_pe_stall              ,
  output logic [63:0] csr_read_mem_almfull            ,
  output logic [63:0] csr_write_mem_almfull           ,
  output logic [63:0] csr_pe_compute_clocks           ,
  `endif
  input  logic [ 2:0] i_ctl_read_fsm                  , // This one is used in both PERFORMANCE AND DEBUG
  `ifdef PERF_DBG_DEBUG
                                                        // Debug INPUT
  input  logic [ 1:0] i_ctl_dmu_fsm                   ,
  input  logic [ 1:0] i_ctl_grid_fsm                  ,
  input  logic [31:0] i_ctl_num_workspace             ,
  input  logic [31:0] i_ctl_num_workload_a            ,
  input  logic [31:0] i_ctl_num_workload_b            ,
  input  logic [10:0] i_ctl_gen_pe_sections           ,
  input  logic [31:0] i_ctl_gen_pe_blocks             ,
  input  logic [31:0] i_ctl_gen_pe_completed          ,
                                                        // Debug OUTPUT
                                                        // -- Feeder
  output logic [63:0] csr_fsm_states                  ,
  output logic [63:0] csr_num_workload_a              ,
  output logic [63:0] csr_num_workload_b              ,
  output logic [63:0] csr_num_workload_block          ,
                                                        // -- PE Controller
  output logic [63:0] csr_pe_sections                 ,
  output logic [63:0] csr_pe_blocks                   ,
  output logic [63:0] csr_pe_completed                ,
  `endif
  `ifdef PERF_DBG_IF_DEBUG
                                                        // Interface Debug
  output logic [63:0] csr_num_mpf_read_req            ,
  output logic [63:0] csr_num_mpf_read_resp           ,
  output logic [63:0] csr_num_mpf_write_req           ,
  output logic [63:0] csr_num_mpf_write_resp          ,
  output logic [63:0] csr_num_async_read_req          ,
  output logic [63:0] csr_num_async_read_resp         ,
  output logic [63:0] csr_num_async_write_req         ,
  output logic [63:0] csr_num_async_write_resp        ,
  output logic [63:0] csr_num_ccip_read_req           ,
  output logic [63:0] csr_num_ccip_read_resp          ,
  output logic [63:0] csr_num_ccip_write_req          ,
  output logic [63:0] csr_num_ccip_write_resp         ,
  output logic [63:0] csr_num_vl0                     ,
  output logic [63:0] csr_num_vh0                     ,
  output logic [63:0] csr_num_vh1                     ,
  `endif
  output logic [63:0] csr_num_clocks
);
  
  localparam PERF_DBG_PIPELINE = 0;

  // Go Signal and Pipelining
  logic go;
  nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_GO (clk,rst,1'b1,i_go,go); 

  logic [63:0]        num_clocks;

  `ifdef PERF_DBG_PERFORMANCE
    // Perforance
    logic req_rd_rsp_valid              ;
    logic req_wr_rsp_valid              ;
    logic req_read_mem_almfull          ;
    logic req_write_mem_almfull         ;
    logic ctl_gen_read_pe_stall_a_loaded;
    logic ctl_gen_read_pe_stall_b_loaded;
    logic ctl_gen_write_pe_stall        ;
    logic ctl_gen_pe_compute            ;

    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_REQ_RD_RSP_VALID (clk,rst,1'b1,i_req_rd_rsp_valid,req_rd_rsp_valid);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_REQ_WR_RSP_VALID (clk,rst,1'b1,i_req_wr_rsp_valid,req_wr_rsp_valid);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_REQ_READ_MEM_ALMFULL (clk,rst,1'b1,i_req_read_mem_almfull,req_read_mem_almfull);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_REQ_WRITE_MEM_ALMFULL (clk,rst,1'b1,i_req_write_mem_almfull,req_write_mem_almfull);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GEN_READ_PE_STALL_A_LOADED (clk,rst,1'b1,i_ctl_gen_read_pe_stall_a_loaded,ctl_gen_read_pe_stall_a_loaded);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GEN_READ_PE_STALL_B_LOADED (clk,rst,1'b1,i_ctl_gen_read_pe_stall_b_loaded,ctl_gen_read_pe_stall_b_loaded);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GEN_WRITE_PE_STALL (clk,rst,1'b1,i_ctl_gen_write_pe_stall,ctl_gen_write_pe_stall);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GEN_PE_COMPUTE (clk,rst,1'b1,i_ctl_gen_pe_compute,ctl_gen_pe_compute);

    // Counters
    logic [63:0] read_bw          ;
    logic [63:0] write_bw         ;
    logic [63:0] read_pe_stall    ;
    logic [63:0] write_pe_stall   ;
    logic [63:0] read_mem_almfull ;
    logic [63:0] write_mem_almfull;
    logic [63:0] pe_compute_clocks;

  `endif
  logic [2:0] ctl_read_fsm; // This one is used in both PERFORMANCE AND DEBUG

  nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_READ_FSM (clk,rst,1'b1,i_ctl_read_fsm,ctl_read_fsm);
  `ifdef PERF_DBG_DEBUG
    logic [ 1:0] ctl_dmu_fsm       ;
    logic [ 1:0] ctl_grid_fsm      ;
    logic [31:0] ctl_num_workspace ;
    logic [31:0] ctl_num_workload_a;
    logic [31:0] ctl_num_workload_b;

    logic [10:0] ctl_gen_pe_sections ;
    logic [31:0] ctl_gen_pe_blocks   ;
    logic [31:0] ctl_gen_pe_completed;

    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_DMU_FSM (clk,rst,1'b1,i_ctl_dmu_fsm,ctl_dmu_fsm);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GRID_FSM (clk,rst,1'b1,i_ctl_grid_fsm,ctl_grid_fsm);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_NUM_WORKSPACE (clk,rst,1'b1,i_ctl_num_workspace,ctl_num_workspace);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_NUM_WORKLOAD_A (clk,rst,1'b1,i_ctl_num_workload_a,ctl_num_workload_a);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_NUM_WORKLOAD_B (clk,rst,1'b1,i_ctl_num_workload_b,ctl_num_workload_b);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GEN_PE_SECTIONS (clk,rst,1'b1,i_ctl_gen_pe_sections,ctl_gen_pe_sections);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GEN_PE_BLOCKS (clk,rst,1'b1,i_ctl_gen_pe_blocks,ctl_gen_pe_blocks);
    nBit_mLength_shiftRegister #(1,PERF_DBG_PIPELINE) PERF_DBG_CTL_GEN_PE_COMPLETED (clk,rst,1'b1,i_ctl_gen_pe_completed,ctl_gen_pe_completed);
  `endif



  always_ff @(posedge clk) begin
    // CSR Connections
    csr_num_clocks <= num_clocks;

    `ifdef PERF_DBG_PERFORMANCE
      // Performance
      csr_read_bw           <= read_bw;
      csr_write_bw          <= write_bw;
      csr_read_pe_stall     <= read_pe_stall;
      csr_write_pe_stall    <= write_pe_stall;
      csr_read_mem_almfull  <= read_mem_almfull;
      csr_write_mem_almfull <= write_mem_almfull;
      csr_pe_compute_clocks <= pe_compute_clocks;
    `endif

    `ifdef PERF_DBG_DEBUG
      // DEBUG
      csr_fsm_states <= {
        ctl_grid_fsm,// [7:6]
        2'b00,       // [6:5]
        ctl_dmu_fsm, // [4:3]
        1'b0,        // [3]
        ctl_read_fsm // [2:0]
      };
      
      csr_num_workload_block <= ctl_num_workspace;
      csr_num_workload_a     <= ctl_num_workload_a;
      csr_num_workload_b     <= ctl_num_workload_b;

      csr_pe_sections  <= ctl_gen_pe_sections;
      csr_pe_blocks    <= ctl_gen_pe_blocks;
      csr_pe_completed <= ctl_gen_pe_completed;
    `endif

    // --------------
    // START COUNTERS
    // --------------
    if (rst) begin
      num_clocks <= 0;

      `ifdef PERF_DBG_PERFORMANCE
        // Performance
        read_bw           <= 0;
        write_bw          <= 0;
        read_pe_stall     <= 0;
        write_pe_stall    <= 0;
        read_mem_almfull  <= 0;
        write_mem_almfull <= 0;
        pe_compute_clocks <= 0;
      `endif

    end else if (go) begin
      num_clocks <= num_clocks + 1;

      `ifdef PERF_DBG_PERFORMANCE
        // Performance
        if (req_rd_rsp_valid)
          read_bw <= read_bw + 1;
        if (req_wr_rsp_valid)
          write_bw <= write_bw + 1;
        if (req_read_mem_almfull)
          read_mem_almfull <= read_mem_almfull + 1;
        if (req_write_mem_almfull)
          write_mem_almfull <= write_mem_almfull + 1;

        if ((~ctl_gen_read_pe_stall_a_loaded || ~ctl_gen_read_pe_stall_b_loaded) && (ctl_read_fsm !== 7))
          read_pe_stall <= read_pe_stall + 1;
        if (ctl_gen_write_pe_stall)
          write_pe_stall <= write_pe_stall + 1;
        if (ctl_gen_pe_compute)
          pe_compute_clocks <= pe_compute_clocks + 1;
      `endif

    end
  end

  endmodule // gemm_perf_dbg
