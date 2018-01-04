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

`default_nettype none
module gemm_mod #(parameter PEND_THRESH=1, ADDR_LMT=20, MDATA=14) (
  input  wire                 clk                             , //                      csi_top:            Clk_400
  input  wire                 rst                             ,
  output logic [ADDR_LMT-1:0] gem2ab_WrAddr                   , // [ADDR_LMT-1:0]        arb:               write address
  output logic [        15:0] gem2ab_WrTID                    , // [15:0]                arb:               meta data
  output logic [       511:0] gem2ab_WrDin                    , // [511:0]               arb:               Cache line data
  output logic                gem2ab_WrEn                     , //                       arb:               write enable
  output logic                gem2ab_WrSop                    , //                       arb:               write enable
  output logic [         0:1] gem2ab_WrLen                    , //                       arb:               write enable
  output logic                gem2ab_WrFence                  , //                       arb:               read enable
  input  wire                 ab2gem_WrSent                   , //                       arb:               write issued
  input  wire                 ab2gem_WrAlmFull                , //                       arb:               write fifo almost full
  output logic [ADDR_LMT-1:0] gem2ab_RdAddr                   , // [ADDR_LMT-1:0]        arb:               Reads may yield to writes
  output logic [        15:0] gem2ab_RdTID                    , // [15:0]                arb:               meta data
  output logic                gem2ab_RdEn                     , //                       arb:               read enable
  output logic                gem2ab_RdSop                    , //                       arb:               write enable
  output logic [         0:1] gem2ab_RdLen                    , //                       arb:               write enable
  input  wire                 ab2gem_RdSent                   , //                       arb:               read issued
  input  wire                 ab2gem_RdRspValid_T0            , //                       arb:               read response valid
  input  wire  [        15:0] ab2gem_RdRsp_T0                 , // [15:0]                arb:               read response header
  input  wire  [ADDR_LMT-1:0] ab2gem_RdRspAddr_T0             , // [ADDR_LMT-1:0]        arb:               read response address
  input  wire  [       511:0] ab2gem_RdData_T0                , // [511:0]               arb:               read data
  input  wire                 ab2gem_WrRspValid_T0            , //                       arb:               write response valid
  input  wire  [         1:0] ab2gem_WrRspCLnum_T0            , //                       arb:               write response valid
  input  wire  [        15:0] ab2gem_WrRsp_T0                 , // [15:0]                arb:               write response header
  input  wire  [ADDR_LMT-1:0] ab2gem_WrRspAddr_T0             , // [Addr_LMT-1:0]        arb:               write response address
  input  wire                 re2xy_go                        , //                       requestor:         start of frame recvd
  input  wire  [        31:0] re2xy_NumPartA                  , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_NumPartB                  , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_NumPartC                  , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_NumBlock                  , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_NumRowsXBlock             , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_NumColsXBlock             , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_TestComplete              , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_ALeadInterleave           , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_BLeadInterleave           , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_FeederInterleave          , // [31:0]                requestor:         number of cache lines
  input  wire  [        31:0] re2xy_FeederInterleaveRnd       , // [31:0]                requestor:         number of cache lines
  output logic                gem2ab_TestCmp                  , //                       arb:               Test completion flag
  output logic [       255:0] gem2ab_ErrorInfo                , // [255:0]               arb:               error information
  output logic                gem2ab_ErrorValid               , //                       arb:               test has detected an error
  // Performance INPUT
  `ifdef PERF_DBG_PERFORMANCE
  output logic                i_ctl_gen_read_pe_stall_a_loaded,
  output logic                i_ctl_gen_read_pe_stall_b_loaded,
  output logic                i_ctl_gen_write_pe_stall        ,
  output logic                i_ctl_gen_pe_compute            ,
  `endif
  output logic [         2:0] i_ctl_read_fsm                  , // This one is used in both PERFORMANCE AND DEBUG
  `ifdef PERF_DBG_DEBUG
                                                                // Debug output
  output logic [         1:0] i_ctl_dmu_fsm                   ,
  output logic [         1:0] i_ctl_grid_fsm                  ,
  output logic [        31:0] i_ctl_num_workspace             ,
  output logic [        31:0] i_ctl_num_workload_a            ,
  output logic [        31:0] i_ctl_num_workload_b            ,
  output logic [        10:0] i_ctl_gen_pe_sections           ,
  output logic [        31:0] i_ctl_gen_pe_blocks             ,
  output logic [        31:0] i_ctl_gen_pe_completed          ,
  `endif
  output logic                gem2ab_ab_workspace_sel         ,
  output logic [        31:0] gem2ab_stall_count
);
  // ---------------------------------------------------------------------------

  localparam CL_WIDTH   = 512;
  localparam NUM_COLS   = 16 ;
  localparam PE_LATENCY = 1  ;

  // ------------------------
  // Supported Configurations
  // ------------------------
  // * FP32, FXD16, FXD8, FXD1
  `ifdef GEMM_MODE_16 // 16 Bit
    localparam DATA_WIDTH = 16;
  `elsif GEMM_MODE_8 // 8 Bit
    localparam DATA_WIDTH = 8;
  `elsif GEMM_MODE_4 // 4 Bit
    localparam DATA_WIDTH = 4;
  `elsif GEMM_MODE_1 // 1 Bit
    localparam DATA_WIDTH = 1;
  `elsif GEMM_MODE_32 // 1 Bit
    localparam DATA_WIDTH = 32;
  `else
    ** Select a valid GEMM mode.
    `endif
    localparam FRAC_WIDTH = 5 ;
    localparam ACCU_WIDTH = 32;
    // * 10, 12, 14, 16, 18, 20
    localparam NUM_ROWS = 10;

    // INTERLEAVING Parameters
    localparam A_INTERLEAVING   = 32;
    localparam B_INTERLEAVING   = 32;
    localparam INTERLEAVE_DEPTH = 16;

    localparam NUM_BUFFERS = 3;

    // ----------------------------
    // Auto Calculate VECTOR_LENGTH
    // ----------------------------
    localparam VECTOR_LENGTH = 256/DATA_WIDTH;

    //------------------------------------------------------------------------------------------------------------------------

    logic gemm_ctl_gen_en_a;
    logic gemm_ctl_gen_en_b;

    logic [CL_WIDTH-1:0] gemm_data_a;
    logic [CL_WIDTH-1:0] gemm_data_b;

    logic [31:0] gemm_workload_num               ;
    logic        gemm_ctl_gen_write_interface_rdy;

    logic [CL_WIDTH-1:0] gemm_data_c            ;
    logic                gemm_ctl_gen_data_valid;

    logic gemm_ctl_gen_fd_a_full;
    logic gemm_ctl_gen_fd_b_full;

    logic [31:0] a_lead_interleave    ;
    logic [31:0] b_lead_interleave    ;
    logic [31:0] feeder_interleave    ;
    logic [31:0] feeder_interleave_rnd;
    //------------------------------------------------------------------------------------------------------------------------

    // Timing Optimsations for Reset
    reg rst_q;
  nBit_mLength_shiftRegister #(1,4,4) TEST_RESETB_Q (clk,1'b0,1'b1,rst,rst_q); 

    reg          re2xy_go_q;
  nBit_mLength_shiftRegister #(1,1) RE2XY_GO_Q (clk,rst,1'b1,re2xy_go,re2xy_go_q);

    // Timing Optimisation for Interleaving Factors
  nBit_mLength_shiftRegister #(32,3) A_INTERLEAVE_Q (clk,rst,1'b1,re2xy_ALeadInterleave,a_lead_interleave);
  nBit_mLength_shiftRegister #(32,3) B_INTERLEAVE_Q (clk,rst,1'b1,re2xy_BLeadInterleave,b_lead_interleave);
  nBit_mLength_shiftRegister #(32,3) F_INTERLEAVE_Q (clk,rst,1'b1,re2xy_FeederInterleave,feeder_interleave);
  nBit_mLength_shiftRegister #(32,3) F_INTERLEAVE_RND_Q (clk,rst,1'b1,re2xy_FeederInterleaveRnd,feeder_interleave_rnd);

    //------------------------------------------------------------------------------------------------------------------------

  gemm_ctl #(
    .CL_WIDTH        (CL_WIDTH        ),
    .ADDR_LMT        (ADDR_LMT        ),
    .MDATA           (MDATA           ),
    .NUM_ROWS        (NUM_ROWS        ),
    .NUM_COLS        (NUM_COLS        ),
    .INTERLEAVE_DEPTH(INTERLEAVE_DEPTH),
    .NUM_BUFFERS     (NUM_BUFFERS     )
  ) INST_GEMM_CTL (
    .clk                 (clk                             ),
    .test_Resetb         (rst_q                           ),
    
    // Requestor Input
    .re2xy_go            (re2xy_go_q                      ),
    .re2xy_NumBlock      (re2xy_NumBlock                  ),
    .re2xy_NumPartA      (re2xy_NumPartA                  ),
    .re2xy_NumPartB      (re2xy_NumPartB                  ),
    .re2xy_NumPartC      (re2xy_NumPartC                  ),
    .re2xy_NumRowsXBlock (re2xy_NumRowsXBlock             ),
    .re2xy_NumColsXBlock (re2xy_NumColsXBlock             ),
    .re2xy_TestComplete  (re2xy_TestComplete              ),
    
    // Arbiter Write Input
    .ab2gem_WrSent       (ab2gem_WrSent                   ),
    .ab2gem_WrAlmFull    (ab2gem_WrAlmFull                ),
    .ab2gem_WrRspValid   (ab2gem_WrRspValid_T0            ),
    .ab2gem_WrRspCLnum   (ab2gem_WrRspCLnum_T0            ),
    .ab2gem_WrRsp        (ab2gem_WrRsp_T0                 ),
    .ab2gem_WrRspAddr    (ab2gem_WrRspAddr_T0             ),
    
    // Arbiter Read Input
    .ab2gem_RdSent       (ab2gem_RdSent                   ),
    .ab2gem_RdRspValid   (ab2gem_RdRspValid_T0            ),
    .ab2gem_RdRsp        (ab2gem_RdRsp_T0                 ),
    .ab2gem_RdRspAddr    (ab2gem_RdRspAddr_T0             ),
    .ab2gem_RdData       (ab2gem_RdData_T0                ),
    
    // Arbiter Write Output
    .gem2ab_WrAddr       (gem2ab_WrAddr                   ),
    .gem2ab_WrTID        (gem2ab_WrTID                    ),
    .gem2ab_WrDin        (gem2ab_WrDin                    ),
    .gem2ab_WrEn         (gem2ab_WrEn                     ),
    .gem2ab_WrSop        (gem2ab_WrSop                    ),
    .gem2ab_WrLen        (gem2ab_WrLen                    ),
    .gem2ab_WrFence      (gem2ab_WrFence                  ),
    
    // Arbiter Read Output
    .gem2ab_RdAddr       (gem2ab_RdAddr                   ),
    .gem2ab_RdTID        (gem2ab_RdTID                    ),
    .gem2ab_RdEn         (gem2ab_RdEn                     ),
    .gem2ab_RdSop        (gem2ab_RdSop                    ),
    .gem2ab_RdLen        (gem2ab_RdLen                    ),
    
    
    .gem2ab_TestCmp      (gem2ab_TestCmp                  ),
    .gem2ab_ErrorInfo    (gem2ab_ErrorInfo                ),
    .gem2ab_ErrorValid   (gem2ab_ErrorValid               ),
    
    .i_ctl_read_fsm      (i_ctl_read_fsm                  ),
    `ifdef PERF_DBG_DEBUG
    .i_ctl_dmu_fsm       (i_ctl_dmu_fsm                   ),
    .i_ctl_grid_fsm      (i_ctl_grid_fsm                  ),
    .i_ctl_num_workspace (i_ctl_num_workspace             ),
    .i_ctl_num_workload_a(i_ctl_num_workload_a            ),
    .i_ctl_num_workload_b(i_ctl_num_workload_b            ),
    `endif
    
    .ab_workspace_sel    (gem2ab_ab_workspace_sel         ),
    
    // Grid Interface Signals
    .grid_out            (gemm_data_c                     ),
    .grid_out_valid      (gemm_ctl_gen_data_valid         ),
    
    .a_full              (gemm_ctl_gen_fd_a_full          ),
    .b_full              (gemm_ctl_gen_fd_b_full          ),
    
    .grid_interface_rdy  (gemm_ctl_gen_write_interface_rdy),
    
    .a_data              (gemm_data_a                     ),
    .a_wr_req            (gemm_ctl_gen_en_a               ),
    
    .b_data              (gemm_data_b                     ),
    .b_wr_req            (gemm_ctl_gen_en_b               ),
    .a_lead_interleave   (a_lead_interleave               ),
    .b_lead_interleave   (b_lead_interleave               ),
    .feeder_interleave   (feeder_interleave_rnd           )
  );

  gemm_gen #(
    .DATA_WIDTH      (DATA_WIDTH      ),
    .ACCU_WIDTH      (ACCU_WIDTH      ),
    .FRAC_WIDTH      (FRAC_WIDTH      ),
    .VECTOR_LENGTH   (VECTOR_LENGTH   ),
    .PE_LATENCY      (PE_LATENCY      ),
    .NUM_ROWS        (NUM_ROWS        ),
    .NUM_COLS        (NUM_COLS        ),
    .A_INTERLEAVING  (A_INTERLEAVING  ),
    .B_INTERLEAVING  (B_INTERLEAVING  ),
    .INTERLEAVE_DEPTH(INTERLEAVE_DEPTH),
    .NUM_BUFFERS     (NUM_BUFFERS     )
  ) INST_GEMM_GEN (
    .clk                             (clk                             ),
    
    .rst                             (rst_q                           ),
    .ena                             (re2xy_go_q                      ),
    
    .wr_data_a_mem                   (gemm_data_a                     ),
    .wr_data_b_mem                   (gemm_data_b                     ),
    
    .wr_en_a_mem                     (gemm_ctl_gen_en_a               ),
    .wr_en_b_mem                     (gemm_ctl_gen_en_b               ),
    
    .workload_num                    (re2xy_NumBlock                  ),
    .parts_c                         (re2xy_NumPartC                  ),
    .a_lead_interleave               (a_lead_interleave               ),
    .b_lead_interleave               (b_lead_interleave               ),
    .feeder_interleave               (feeder_interleave               ),
    .feeder_interleave_rnd           (feeder_interleave_rnd           ),
    .write_interface_rdy             (gemm_ctl_gen_write_interface_rdy),
    
    .grid_out                        (gemm_data_c                     ),
    .grid_out_valid                  (gemm_ctl_gen_data_valid         ),
    
    .fd_a_full                       (gemm_ctl_gen_fd_a_full          ),
    .fd_b_full                       (gemm_ctl_gen_fd_b_full          ),
    
    `ifdef PERF_DBG_PERFORMANCE
    .i_ctl_gen_read_pe_stall_a_loaded(i_ctl_gen_read_pe_stall_a_loaded),
    .i_ctl_gen_read_pe_stall_b_loaded(i_ctl_gen_read_pe_stall_b_loaded),
    .i_ctl_gen_write_pe_stall        (i_ctl_gen_write_pe_stall        ),
    .i_ctl_gen_pe_compute            (i_ctl_gen_pe_compute            ),
    `endif
    `ifdef PERF_DBG_DEBUG
    .i_ctl_gen_pe_sections           (i_ctl_gen_pe_sections           ),
    .i_ctl_gen_pe_blocks             (i_ctl_gen_pe_blocks             ),
    .i_ctl_gen_pe_completed          (i_ctl_gen_pe_completed          ),
    `endif
    
    .stall_count                     (gem2ab_stall_count              )
  );

  endmodule
