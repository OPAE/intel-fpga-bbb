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

module gemm_ctl #(
  CL_WIDTH         = 512,
  ADDR_LMT         = 20 ,
  MDATA            = 14 ,
  NUM_ROWS         = 10 ,
  NUM_COLS         = 16 ,
  INTERLEAVE_DEPTH = 16 ,
  NUM_BUFFERS      = 2
) (
  input  logic                clk                 , //                       csi_top:           clk
  input  logic                test_Resetb         , //                       csi_top:           soft reset - active low
  // Requestor Input
  input  logic                re2xy_go            , //                       requestor:         start of frame recvd
  input  logic                re2xy_Cont          , //                       requestor:         continuous mode
  input  logic [        31:0] re2xy_NumBlock      , // [31:0]                requestor:         number of blocks
  input  logic [        31:0] re2xy_NumPartA      , // [31:0]                requestor:         number of parts in A
  input  logic [        31:0] re2xy_NumPartB      , // [31:0]                requestor:         number of parts in B
  input  logic [        31:0] re2xy_NumPartC      , // [31:0]                requestor:         number of parts in C
  input  logic [        31:0] re2xy_NumRowsXBlock , // [31:0]                requestor:         number of number of Rows * Blocks
  input  logic [        31:0] re2xy_NumColsXBlock , // [31:0]                requestor:         number of number of Cols * Blocks
  input  logic [        31:0] re2xy_TestComplete  , // [31:0]                requestor:         number of Test Completion Total
  // Arbiter Write Input
  input  logic                ab2gem_WrSent       , //                       arb:               write issued
  input  logic                ab2gem_WrAlmFull    , //                       arb:               write fifo almost full
  input  logic                ab2gem_WrRspValid   , //                       arb:               write response valid
  input  logic [         1:0] ab2gem_WrRspCLnum   , //                       arb:               write response valid
  input  logic [        15:0] ab2gem_WrRsp        , // [15:0]                arb:               write response header
  input  logic [ADDR_LMT-1:0] ab2gem_WrRspAddr    , // [Addr_LMT-1:0]        arb:               write response address
  // Arbiter Read Input
  input  logic                ab2gem_RdSent       , //                       arb:               read issued
  input  logic                ab2gem_RdRspValid   , //                       arb:               read response valid
  input  logic [        15:0] ab2gem_RdRsp        , // [15:0]                arb:               read response header
  input  logic [ADDR_LMT-1:0] ab2gem_RdRspAddr    , // [ADDR_LMT-1:0]        arb:               read response address
  input  logic [       511:0] ab2gem_RdData       , // [511:0]               arb:               read data
  // Arbiter Write Output
  output logic [ADDR_LMT-1:0] gem2ab_WrAddr       , // [ADDR_LMT-1:0]        arb:               write address
  output logic [        15:0] gem2ab_WrTID        , // [15:0]                arb:               meta data
  output logic [       511:0] gem2ab_WrDin        , // [511:0]               arb:               Cache line data
  output logic                gem2ab_WrEn         , //                       arb:               write enable
  output logic                gem2ab_WrFence      , //                       arb:               read enable
  output logic [         0:1] gem2ab_WrLen        , //                       arb:               read enable
  output logic                gem2ab_WrSop        , //                       arb:               read enable
  // Arbiter Read Output
  output logic [ADDR_LMT-1:0] gem2ab_RdAddr       , // [ADDR_LMT-1:0]        arb:               Reads may yield to writes
  output logic [        15:0] gem2ab_RdTID        , // [15:0]                arb:               meta data
  output logic                gem2ab_RdEn         , //                       arb:               read enable
  output logic [         0:1] gem2ab_RdLen        , //                       arb:               read enable
  output logic                gem2ab_RdSop        , //                       arb:               read enable
  output logic                gem2ab_TestCmp      , //                       arb:               Test completion flag
  output logic [       255:0] gem2ab_ErrorInfo    , // [255:0]               arb:               error information
  output logic                gem2ab_ErrorValid   , //                       arb:               test has detected an error
  // Grid Interface Signals
  input  logic [CL_WIDTH-1:0] grid_out            ,
  input  logic                grid_out_valid      ,
  input  logic                a_full              ,
  input  logic                b_full              ,
  output logic                grid_interface_rdy  ,
  output logic [CL_WIDTH-1:0] a_data              ,
  output logic                a_wr_req            ,
  output logic [CL_WIDTH-1:0] b_data              ,
  output logic                b_wr_req            ,
  output logic [         2:0] i_ctl_read_fsm      , // This one is used in both PERFORMANCE AND DEBUG
  `ifdef PERF_DBG_DEBUG
  output logic [         1:0] i_ctl_dmu_fsm       ,
  output logic [         1:0] i_ctl_grid_fsm      ,
  output logic [        31:0] i_ctl_num_workspace ,
  output logic [        31:0] i_ctl_num_workload_a,
  output logic [        31:0] i_ctl_num_workload_b,
  `endif
  output logic                ab_workspace_sel    ,
  input  logic [        31:0] a_lead_interleave   ,
  input  logic [        31:0] b_lead_interleave   ,
  input  logic [        31:0] feeder_interleave
);

  // -----------------------------------------------------------------------------------------------------------------------------

  // Logger ID
  int log;

  // ---
  // FSM
  // ---
  // Registers
  reg [2:0] read_fsm;
  reg [1:0] dmu_fsm ;
  reg [1:0] grid_fsm;

  // States
  // Read FSM
  localparam [2:0] STATE_READ_IDLE             = 0;
  localparam [2:0] STATE_READ_SEND_REQ         = 1;
  localparam [2:0] STATE_READ_CALC_OFFSET_1    = 2;
  localparam [2:0] STATE_READ_CALC_OFFSET_2    = 3;
  localparam [2:0] STATE_READ_CALC_OFFSET_DONE = 4;
  localparam [2:0] STATE_READ_CHANGE_WORKLOAD  = 5;
  localparam [2:0] STATE_READ_NULL             = 7;

  // DMU FSM
  localparam [1:0] STATE_DMU_IDLE   = 0;
  localparam [1:0] STATE_DMU_FILL_A = 1;
  localparam [1:0] STATE_DMU_FILL_B = 2;

  // PE FSM Write Out
  localparam [1:0] STATE_GRID_MEM_IDLE     = 0;
  localparam [1:0] STATE_GRID_MEM_SEND_REQ = 1;
  localparam [1:0] STATE_GRID_MEM_WAIT     = 2;
  localparam [1:0] STATE_GRID_MEM_DONE     = 3;

  // -----------------------------------------------------------------------------------------------------------------------------

  // -----------------
  // Control Registers
  // -----------------
  logic [31:0] num_read_req ;
  logic [31:0] num_read_rsp ;
  logic [31:0] num_write_req;
  logic [31:0] num_write_rsp;

  // Meta Data Registers
  logic [MDATA-1:0] rd_mdata, wr_mdata; // Not Sure how important this is...

  logic [0:1] wr_len, rd_len, rd_len_q;
  logic [0:1] wr_len_count, rd_len_count;

  // Workload - Block Registers
  logic [31:0] num_rows_x_block;
  logic [31:0] num_cols_x_block;

  // Static Offset Parts for Timing Optimisations
  logic [ADDR_LMT-1:0] rd_addr_a_offset_p1_static;
  logic [ADDR_LMT-1:0] rd_addr_a_offset_p2_static;
  logic [ADDR_LMT-1:0] rd_addr_b_offset_p1_static;
  logic [ADDR_LMT-1:0] rd_addr_b_offset_p2_static;

  // Static Offset Mult Results for Timing Optimisations
  logic [ADDR_LMT-1:0] rd_addr_a_offset_p1_static_mult;
  logic [ADDR_LMT-1:0] rd_addr_a_offset_p2_static_mult;
  logic [ADDR_LMT-1:0] rd_addr_b_offset_p1_static_mult;
  logic [ADDR_LMT-1:0] rd_addr_b_offset_p2_static_mult;

  // READ FSM address offset parts
  logic [ADDR_LMT-1:0] rd_addr_a_offset_p1;
  logic [ADDR_LMT-1:0] rd_addr_a_offset_p2;
  logic [ADDR_LMT-1:0] rd_addr_b_offset_p1;
  logic [ADDR_LMT-1:0] rd_addr_b_offset_p2;

  // WRITE FSM address offset
  logic [ADDR_LMT-1:0] grid_wr_addr;

  // --------------------------
  // Workload Counter Registers
  // --------------------------
  logic [31:0] num_workspace   ;
  logic [31:0] num_workspace_q ;
  logic [31:0] num_workload_a  ;
  logic [31:0] num_workload_a_q;
  logic [31:0] num_workload_b  ;
  logic [31:0] num_workload_b_q;
  logic        workspace_switch;

  // -------------------------------------
  // DMU FSM Control and Counter Registers
  // -------------------------------------
  logic [31:0] num_a_el;
  logic [31:0] num_b_el;

  // ----------------
  // GRID FSM Control
  // ----------------
  logic [CL_WIDTH-1:0] grid_fifo_out        ;
  logic                grid_fifo_rd_req     ;
  logic                grid_fifo_rd_req_q   ;
  logic                grid_fifo_empty      ;
  logic                grid_fifo_empty_q    ;
  logic                grid_fifo_full       ;
  logic [         8:0] grid_fifo_usedw      ;
  logic                grid_fifo_almost_full;
  logic                grid_fifo_wr_req     ;

  // -------------
  // Test Complete
  // -------------
  logic [31:0] test_complete_flag;
  logic [31:0] partC             ;

  // --------------------
  // Timing Optimisations
  // --------------------
  logic [31:0] re2xy_NumPartA_q   ;
  logic [31:0] re2xy_NumPartA_q_m1;
  logic [31:0] re2xy_NumPartB_q   ;
  logic [31:0] re2xy_NumPartB_q_m1;
  logic [31:0] re2xy_NumBlock_q   ;

  // Read and Write Control Statics
  //localparam BLOCK_SIZE = 256;
  logic [31:0] a_block_size       ;
  logic [31:0] b_block_size       ;
  logic [31:0] num_rows_block     ;
  logic [31:0] num_cols_block     ;
  logic [31:0] a_workspace_x_block;
  logic [31:0] b_workspace_x_block;

  logic [31:0] feeder_interleave_q;

  // -----------------------------------------------------------------------------------------------------------------------------

  // ------------------------
  // CSR Timing Optimisations
  // ------------------------
  // Set Maximum Fanout to 1
  nBit_mLength_shiftRegister #(32,7) NUM_PARTA_Q (clk,test_Resetb,1'b1,re2xy_NumPartA,re2xy_NumPartA_q);
  nBit_mLength_shiftRegister #(32,7) NUM_PARTB_Q (clk,test_Resetb,1'b1,re2xy_NumPartB,re2xy_NumPartB_q);
  nBit_mLength_shiftRegister #(32,7) NUM_BLOCK_Q (clk,test_Resetb,1'b1,re2xy_NumBlock,re2xy_NumBlock_q);
  nBit_mLength_shiftRegister #(32,7) FEEDER_INTERLEAVE_Q (clk,test_Resetb,1'b1,feeder_interleave>>1,feeder_interleave_q);

  nBit_mLength_shiftRegister #(32,7) NUM_ROWS_X_BLOCK_Q (clk,test_Resetb,1'b1,re2xy_NumRowsXBlock,num_rows_x_block);
  nBit_mLength_shiftRegister #(32,7) NUM_COLS_X_BLOCK_Q (clk,test_Resetb,1'b1,re2xy_NumColsXBlock,num_cols_x_block);
  nBit_mLength_shiftRegister #(32,7) TEST_COMPLETE_Q (clk,test_Resetb,1'b1,re2xy_TestComplete,test_complete_flag);

  // ---------------------------------------------
  // Read FSM Change Workload Timing Optimisations
  // ---------------------------------------------
  nBit_mLength_shiftRegister #(32,7) NUM_PARTA_M1_Q (clk,test_Resetb,1'b1,re2xy_NumPartA-1,re2xy_NumPartA_q_m1);
  nBit_mLength_shiftRegister #(32,7) NUM_PARTB_M1_Q (clk,test_Resetb,1'b1,re2xy_NumPartB-1,re2xy_NumPartB_q_m1);

  logic [31:0] a_block_size_q;
  logic [31:0] b_block_size_q;

  nBit_mLength_shiftRegister #(32,3) A_BLOCK_SIZE_Q (clk,test_Resetb,1'b1,a_block_size,a_block_size_q);
  nBit_mLength_shiftRegister #(32,3) B_BLOCK_SIZE_Q (clk,test_Resetb,1'b1,b_block_size,b_block_size_q);

  // -------------------------------
  // Block Size Timing Optimisations
  // -------------------------------
  mBit_nMult #(
    .DATA_WIDTH(32),
    .LATENCY   (3 )
  ) A_BLOCK_SIZE_M (
    .clk(clk                ),
    .rst(test_Resetb        ),
    .ena(1'b1               ),
    .a  (feeder_interleave_q),
    .b  (a_lead_interleave  ),
    .m  (a_block_size       )
  );

  mBit_nMult #(
    .DATA_WIDTH(32),
    .LATENCY   (3 )
  ) B_BLOCK_SIZE_M (
    .clk(clk                ),
    .rst(test_Resetb        ),
    .ena(1'b1               ),
    .a  (feeder_interleave_q),
    .b  (b_lead_interleave  ),
    .m  (b_block_size       )
  );

  mBit_nMult #(
    .DATA_WIDTH(32),
    .LATENCY   (3 )
  ) NUM_ROWS_BLOCK_M (
    .clk(clk           ),
    .rst(test_Resetb   ),
    .ena(1'b1          ),
    .a  (NUM_ROWS      ),
    .b  (a_block_size_q),
    .m  (num_rows_block)
  );

  mBit_nMult #(
    .DATA_WIDTH(32),
    .LATENCY   (3 )
  ) NUM_COLS_BLOCK_M (
    .clk(clk           ),
    .rst(test_Resetb   ),
    .ena(1'b1          ),
    .a  (NUM_COLS      ),
    .b  (b_block_size_q),
    .m  (num_cols_block)
  );

  // --------------------------------------------
  // Read FSM Static Address Timing Optimisations
  // --------------------------------------------

  // Mult Latency
  localparam CTL_MULT_LATENCY = 2 ;
  localparam NEG_AMOUNT       = 14;

  logic [31:0] num_rows_block_q     ;
  logic [31:0] num_cols_block_q     ;
  logic [31:0] num_rows_block_neg_q ;
  logic [31:0] num_cols_block_neg_q ;
  logic [31:0] num_rows_block_neg1_q;
  logic [31:0] num_cols_block_neg1_q;

  nBit_mLength_shiftRegister #(32,3) NUM_ROWS_BLOCK_Q (clk,test_Resetb,1'b1,num_rows_block,num_rows_block_q);
  nBit_mLength_shiftRegister #(32,3) NUM_COLS_BLOCK_Q (clk,test_Resetb,1'b1,num_cols_block,num_cols_block_q);

  nBit_mLength_shiftRegister #(32,3) NUM_ROWS_BLOCK_NEG_Q (clk,test_Resetb,1'b1,num_rows_block_q-NEG_AMOUNT,num_rows_block_neg_q);
  nBit_mLength_shiftRegister #(32,3) NUM_COLS_BLOCK_NEG_Q (clk,test_Resetb,1'b1,num_cols_block_q-NEG_AMOUNT,num_cols_block_neg_q);

  nBit_mLength_shiftRegister #(32,3) NUM_ROWS_BLOCK_NEG1_Q (clk,test_Resetb,1'b1,num_rows_block_q-1,num_rows_block_neg1_q);
  nBit_mLength_shiftRegister #(32,3) NUM_COLS_BLOCK_NEG1_Q (clk,test_Resetb,1'b1,num_cols_block_q-1,num_cols_block_neg1_q);

  nBit_mLength_shiftRegister #(32,CTL_MULT_LATENCY) NUM_WORKSPACE_Q (clk,test_Resetb,1'b1,num_workspace,num_workspace_q);
  nBit_mLength_shiftRegister #(32,CTL_MULT_LATENCY) NUM_WORKLOAD_A_Q (clk,test_Resetb,1'b1,num_workload_a,num_workload_a_q);
  nBit_mLength_shiftRegister #(32,CTL_MULT_LATENCY) NUM_WORKLOAD_B_Q (clk,test_Resetb,1'b1,num_workload_b,num_workload_b_q);

  // Stage 1
  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) A_WORKSPACE_M (
    .clk(clk                ),
    .rst(test_Resetb        ),
    .ena(1'b1               ),
    .a  (num_workspace[31:1]),
    .b  (a_block_size_q     ),
    .m  (a_workspace_x_block)
  );

  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) B_WORKSPACE_M (
    .clk(clk                ),
    .rst(test_Resetb        ),
    .ena(1'b1               ),
    .a  (num_workspace[31:1]),
    .b  (b_block_size_q     ),
    .m  (b_workspace_x_block)
  );


  // Stage 2
  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) RD_ADDR_A_OFFSET_P1_STATIC (
    .clk(clk                            ),
    .rst(test_Resetb                    ),
    .ena(1'b1                           ),
    .a  (b_workspace_x_block            ),
    .b  (NUM_COLS                       ),
    .m  (rd_addr_a_offset_p1_static_mult)
  );

  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) RD_ADDR_B_OFFSET_P1_STATIC (
    .clk(clk                            ),
    .rst(test_Resetb                    ),
    .ena(1'b1                           ),
    .a  (a_workspace_x_block            ),
    .b  (NUM_ROWS                       ),
    .m  (rd_addr_b_offset_p1_static_mult)
  );

  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) RD_ADDR_B_OFFSET_P2_STATIC (
    .clk(clk                            ),
    .rst(test_Resetb                    ),
    .ena(1'b1                           ),
    .a  (num_workload_a                 ),
    .b  (num_rows_x_block               ),
    .m  (rd_addr_b_offset_p2_static_mult)
  );

  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) RD_ADDR_A_OFFSET_P2_STATIC (
    .clk(clk                            ),
    .rst(test_Resetb                    ),
    .ena(1'b1                           ),
    .a  (num_workload_b                 ),
    .b  (num_cols_x_block               ),
    .m  (rd_addr_a_offset_p2_static_mult)
  );

  // Stage 3
  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) RD_ADDR_B_OFFSET_P2_STATIC_F (
    .clk(clk                            ),
    .rst(test_Resetb                    ),
    .ena(1'b1                           ),
    .a  (rd_addr_b_offset_p2_static_mult),
    .b  (a_block_size_q                 ),
    .m  (rd_addr_b_offset_p2_static     )
  );

  mBit_nMult #(
    .DATA_WIDTH(32              ),
    .LATENCY   (CTL_MULT_LATENCY)
  ) RD_ADDR_A_OFFSET_P2_STATIC_F (
    .clk(clk                            ),
    .rst(test_Resetb                    ),
    .ena(1'b1                           ),
    .a  (rd_addr_a_offset_p2_static_mult),
    .b  (b_block_size_q                 ),
    .m  (rd_addr_a_offset_p2_static     )
  );


  // -----------------------------------------------------------------------------------------------------------------------------

  // -----------------------------------
  // Workload - Block Offset Calculation
  // -----------------------------------
  assign partC = re2xy_NumPartC;

  // ---------------
  // Request Vs Used
  // ---------------
  logic [31:0] a_req ;
  logic [31:0] a_use ;
  logic        a_stop;
  assign a_stop = ((a_req - a_use) > (NUM_BUFFERS-2)) || a_full;

  logic [31:0] b_req ;
  logic [31:0] b_use ;
  logic        b_stop;
  assign b_stop = ((b_req - b_use) > (NUM_BUFFERS-2)) || b_full;

  // -----------------------------------
  // Read FSM Static Address Assignments
  // -----------------------------------
  assign rd_addr_a_offset_p1_static = rd_addr_a_offset_p1_static_mult;
  assign rd_addr_b_offset_p1_static = rd_addr_b_offset_p1_static_mult;

  // For Clarity
  assign workspace_switch = num_workspace[0];

  // ---------------------------------
  // Performance and Debug Connections
  // ---------------------------------
  assign i_ctl_read_fsm = read_fsm;

  `ifdef PERF_DBG_DEBUG
    assign i_ctl_dmu_fsm        = dmu_fsm;
    assign i_ctl_grid_fsm       = grid_fsm;
    assign i_ctl_num_workspace  = num_workspace;
    assign i_ctl_num_workload_a = num_workload_a;
    assign i_ctl_num_workload_b = num_workload_b;
  `endif

  // Control Mult Latency Counter
  logic [$clog2(CTL_MULT_LATENCY*3):0] ctl_mult_counter;

  // CacheLine Checker Flag
  logic [3:0] cl_checker;
  assign cl_checker = workspace_switch ? rd_addr_a_offset_p1[3:0] + rd_addr_a_offset_p2[3:0] :  rd_addr_b_offset_p1[3:0] + rd_addr_b_offset_p2[3:0];

  // --------
  // READ FSM
  // --------
  // We partition the read offset calcaultion over to states (2cycles) to
  // meet timing
  always @(posedge clk) begin : CTL_FSM
    case (read_fsm) /* synthesis parallel_case */
      STATE_READ_IDLE : begin
        rd_addr_a_offset_p1 <= 0;
        rd_addr_a_offset_p2 <= 0;
        rd_addr_b_offset_p1 <= 0;
        rd_addr_b_offset_p2 <= 0;
        ctl_mult_counter    <= 0;

        read_fsm <= STATE_READ_CALC_OFFSET_1;
      end
      // Timing Optimisation Case
      STATE_READ_CALC_OFFSET_1 : begin
        if (ctl_mult_counter == CTL_MULT_LATENCY*3) begin
          read_fsm <= STATE_READ_CALC_OFFSET_2;
        end
        else begin
          ctl_mult_counter <= ctl_mult_counter + 1;
          read_fsm         <= read_fsm;
        end
      end
      // Timing Optimisation Case
      STATE_READ_CALC_OFFSET_2 : begin
        rd_addr_a_offset_p1 <= rd_addr_a_offset_p1_static;
        rd_addr_b_offset_p1 <= rd_addr_b_offset_p1_static;
        rd_addr_a_offset_p2 <= rd_addr_a_offset_p2_static;
        rd_addr_b_offset_p2 <= rd_addr_b_offset_p2_static;

        read_fsm <= STATE_READ_CALC_OFFSET_DONE;
      end
      STATE_READ_CALC_OFFSET_DONE : begin
        if(workspace_switch) begin // Read B
          gem2ab_RdAddr <= rd_addr_a_offset_p1 + rd_addr_a_offset_p2;
        end else begin
          gem2ab_RdAddr <= rd_addr_b_offset_p1 + rd_addr_b_offset_p2;
        end
        // Set the Number of Cache Line read req make sure that it is aligned...
        rd_len   <= 2'b00; //cl_checker[1:0] == 2'b00 ? 2'b11 : 2'b00;
        rd_len_q <= 2'b00; //cl_checker[1:0] == 2'b00 ? 2'b11 : 2'b00;

        num_read_req <= 0;
        rd_mdata     <= 0;
        // Now if we are ready to go then begin reading in the data
        if(re2xy_go) begin
          // Here we check to see if we have finished
          if(num_workload_a<re2xy_NumPartA_q && num_workload_b<re2xy_NumPartB_q) begin
            // If we haven't finished then we want to make sure that our
            // feeders can accept data.
            if (!(a_stop || b_stop)) begin
              // If they can accept data, start pumping it in
              read_fsm <= STATE_READ_SEND_REQ;
            end else begin
              // otherwise we dont want to change the offset so we hold
              read_fsm <= read_fsm;
            end
          end else begin
            // If we have finished then go into a null state
            read_fsm <= STATE_READ_NULL;
          end
        end
      end
      STATE_READ_SEND_REQ : begin
        rd_len_q <= rd_len;
        if (ab2gem_RdSent) begin
          gem2ab_RdAddr <= gem2ab_RdAddr + rd_len_q + 1;
          num_read_req  <= num_read_req + rd_len_q + 1;
          if((num_read_req > num_rows_block_neg_q) && !workspace_switch && (rd_len == 2'b11)) begin
            rd_len <= 2'b00;
          end else if ((num_read_req < num_rows_block_neg_q) && !workspace_switch && (rd_len == 2'b00)) begin
            if (gem2ab_RdAddr[1:0] == 2'b10) begin
              rd_len <= 2'b00; //2'b11;
            end
          end else if((num_read_req == num_rows_block_neg1_q) && !workspace_switch) begin
            ab_workspace_sel <= 1'b1;
            read_fsm         <= STATE_READ_IDLE;
            num_workspace    <= num_workspace + 1;
            a_req            <= a_req + 1;
          end
          if((num_read_req > num_cols_block_neg_q) && workspace_switch && (rd_len == 2'b11)) begin
            rd_len <= 2'b00;
          end else if ((num_read_req < num_cols_block_neg_q) && workspace_switch && (rd_len == 2'b00)) begin
            if (gem2ab_RdAddr[1:0] == 2'b10) begin
              rd_len <= 2'b00; //2'b11;
            end
          end else if((num_read_req == num_cols_block_neg1_q) && workspace_switch) begin
            ab_workspace_sel <= 1'b0;
            read_fsm         <= STATE_READ_CHANGE_WORKLOAD;
            num_workspace    <= num_workspace + 1;
            b_req            <= b_req + 1;
          end
        end
      end
      STATE_READ_CHANGE_WORKLOAD : begin
        if(num_workspace == (re2xy_NumBlock_q[31:0] << 1)) begin
          num_workspace <= 0;
          if(num_workload_a_q < (re2xy_NumPartA_q_m1)) begin
            num_workload_a <= num_workload_a + 1;
          end else begin
            num_workload_a <= 0;
            num_workload_b <= num_workload_b + 1;
          end
          if((num_workload_a_q == (re2xy_NumPartA_q_m1)) && (num_workload_b_q == (re2xy_NumPartB_q_m1))) begin
            read_fsm <= STATE_READ_NULL; // end of reads
          end else begin
            read_fsm <= STATE_READ_IDLE;
          end
        end else begin
          read_fsm <= STATE_READ_IDLE;
        end
      end
      default : begin
        read_fsm <= read_fsm;
      end
    endcase

    // -----------------------------------------------------------------------------------------------------------------------------

    // -------
    // DMU FSM
    // -------
    case(dmu_fsm) /*synthesis parallel_case */
      STATE_DMU_IDLE : begin
        a_wr_req <= 1'b0;
        a_data   <= 0;
        b_wr_req <= 1'b0;
        b_data   <= 0;
        num_a_el <= 0;
        num_b_el <= 0;

        if(re2xy_go) begin
          dmu_fsm <= STATE_DMU_FILL_A;
        end else begin
          dmu_fsm <= dmu_fsm;
        end
      end
      STATE_DMU_FILL_A : begin
        if(ab2gem_RdRspValid && (num_a_el == num_rows_block_q)) begin
          // We have reached the end of A and will move onto B
          b_wr_req <= 1'b1;
          b_data   <= ab2gem_RdData;
          num_b_el <= 1;

          a_wr_req <= 1'b0;
          a_data   <= 0;
          num_a_el <= 0;

          dmu_fsm <= STATE_DMU_FILL_B;
          a_use   <= a_use + 1;
        end else if(ab2gem_RdRspValid) begin
          a_wr_req <= 1'b1;
          a_data   <= ab2gem_RdData;
          num_a_el <= num_a_el + 1;

          b_wr_req <= 1'b0;
          b_data   <= 0;
        end else begin
          a_wr_req <= 1'b0;
          a_data   <= 0;

          b_wr_req <= 1'b0;
          b_data   <= 0;
          if(num_a_el == num_rows_block_q) begin
            dmu_fsm  <= STATE_DMU_FILL_B;
            a_use    <= a_use + 1;
            num_a_el <= 0;
          end
        end
      end
      STATE_DMU_FILL_B : begin
        if(ab2gem_RdRspValid && (num_b_el == num_cols_block_q)) begin
          a_wr_req <= 1'b1;
          a_data   <= ab2gem_RdData;
          num_a_el <= 1;

          b_wr_req <= 1'b0;
          b_data   <= 0;
          num_b_el <= 0;

          dmu_fsm <= STATE_DMU_FILL_A;
          b_use   <= b_use + 1;
        end else if(ab2gem_RdRspValid) begin
          b_wr_req <= 1'b1;
          b_data   <= ab2gem_RdData;
          num_b_el <= num_b_el + 1;

          a_wr_req <= 1'b0;
          a_data   <= 0;
        end else begin
          b_wr_req <= 1'b0;
          b_data   <= 0;

          a_wr_req <= 1'b0;
          a_data   <= 0;
          if(num_b_el == num_cols_block_q) begin
            dmu_fsm  <= STATE_DMU_FILL_A;
            b_use    <= b_use + 1;
            num_b_el <= 0;
          end
        end
      end
      default : begin
        dmu_fsm <= dmu_fsm;
      end
    endcase



    // -----------------------------------------------------------------------------------------------------------------------------

    // ---------
    // WRITE FSM
    // ---------
    case(grid_fsm) /*synthesis parallel_case */
      STATE_GRID_MEM_IDLE : begin
        if ((test_complete_flag == num_write_rsp) && re2xy_go) begin
          grid_fsm         <= STATE_GRID_MEM_DONE;
          grid_fifo_rd_req <= 1'b0;
        end else if(!grid_fifo_empty & !ab2gem_WrAlmFull) begin
          grid_fsm         <= STATE_GRID_MEM_SEND_REQ;
          grid_fifo_rd_req <= 1'b1;
        end else begin
          grid_fsm         <= grid_fsm;
          grid_fifo_rd_req <= 1'b0;
        end
      end
      STATE_GRID_MEM_SEND_REQ : begin
        if ((test_complete_flag==num_write_rsp) && re2xy_go) begin
          grid_fsm         <= STATE_GRID_MEM_DONE;
          grid_fifo_rd_req <= 1'b0;
        end else if(ab2gem_WrAlmFull | grid_fifo_empty) begin
          grid_fsm         <= STATE_GRID_MEM_IDLE;
          grid_fifo_rd_req <= 1'b0;
        end else  begin
          grid_fifo_rd_req <= 1'b1;
          grid_fsm         <= grid_fsm;
        end
      end
      STATE_GRID_MEM_DONE : begin
        grid_fsm <= STATE_GRID_MEM_IDLE;
      end
      default : begin
        grid_fsm <= grid_fsm;
      end
    endcase

    // -----------------------------------------------------------------------------------------------------------------------------

    if(gem2ab_RdEn && ab2gem_RdSent) begin
      if((num_workspace == 0 & rd_mdata==num_rows_block_neg1_q) | (num_workspace == 1 && rd_mdata==num_cols_block_neg1_q)) begin
        rd_mdata <= 0;
      end else begin
        rd_mdata <= rd_mdata + 1;
      end
    end

    if (ab2gem_RdRspValid) begin
      num_read_rsp <= num_read_rsp + 1;
    end

    if(gem2ab_WrEn) begin
      wr_mdata <= wr_mdata + 1;
    end
    if((num_write_req > (test_complete_flag - 10)) && re2xy_go && (wr_len_count == 2'b11)) begin
      wr_len_count <= 2'b00;
      wr_len       <= 2'b00;
    end else if ((grid_fifo_rd_req_q & !grid_fifo_empty_q) && (wr_len == 2'b11)) begin
      num_write_req <= num_write_req + 1;
      wr_len_count  <= wr_len_count + 1'b1;
    end


    if(ab2gem_WrRspValid) begin
      num_write_rsp <= num_write_rsp + ab2gem_WrRspCLnum + 1;
    end

    if(test_complete_flag==num_write_rsp && re2xy_go) begin
      gem2ab_TestCmp <= 1'b1;
    end

    if(gem2ab_WrEn && ab2gem_WrSent==0) begin
      gem2ab_ErrorValid <= 1'b1;
      gem2ab_ErrorInfo  <= 1'b1;
    end

    if(test_Resetb) begin
      gem2ab_WrAddr  <= 0;
      gem2ab_WrEn    <= 0;
      gem2ab_WrFence <= 0;
      gem2ab_RdAddr  <= 0;

      gem2ab_TestCmp    <= 0;
      gem2ab_ErrorInfo  <= 0;
      gem2ab_ErrorValid <= 0;

      read_fsm <= 0;
      dmu_fsm  <= 0;
      grid_fsm <= 0;

      rd_mdata <= 0;
      wr_mdata <= 0;

      wr_len   <= 2'b00; //2'b11;
      rd_len   <= 2'b00;
      rd_len_q <= 2'b00;

      wr_len_count <= 2'b00;
      rd_len_count <= 2'b00;

      num_read_req  <= 16'h1;
      num_read_rsp  <= 0;
      num_write_req <= 0;
      num_write_rsp <= 0;

      a_data   <= 0;
      a_wr_req <= 0;
      b_data   <= 0;
      b_wr_req <= 0;

      num_workspace    <= 0;
      num_workload_a   <= 0;
      num_workload_b   <= 0;
      ab_workspace_sel <= 0;

      num_a_el <= 0;
      num_b_el <= 0;

      a_req <= 0;
      b_req <= 0;
      a_use <= 0;
      b_use <= 0;

      grid_wr_addr       <= 0;
      grid_interface_rdy <= 0;

      grid_fifo_rd_req   <= 0;
      grid_fifo_rd_req_q <= 0;
      grid_fifo_wr_req   <= 0;
      grid_fifo_empty_q  <= 0;

      rd_addr_a_offset_p1 <= 0;
      rd_addr_a_offset_p2 <= 0;
      rd_addr_b_offset_p1 <= 0;
      rd_addr_b_offset_p2 <= 0;

      gem2ab_WrDin <= 0;
    end else begin
      grid_fifo_rd_req_q <= grid_fifo_rd_req;
      grid_fifo_empty_q  <= grid_fifo_empty;

      grid_interface_rdy <= ~grid_fifo_almost_full;

      gem2ab_WrEn  <= grid_fifo_rd_req_q & !grid_fifo_empty_q;
      gem2ab_WrSop <= (wr_len_count == 2'b00);
      gem2ab_WrLen <= wr_len;


      gem2ab_WrAddr <= grid_wr_addr - wr_len_count;
      gem2ab_WrDin  <= grid_fifo_out;
      if(grid_fifo_rd_req_q & !grid_fifo_empty_q) begin
        grid_wr_addr <= grid_wr_addr + 1;
      end
    end
  end

  always @(*) begin
    gem2ab_WrTID            = 0;
    gem2ab_RdTID            = 0;
    gem2ab_WrTID[MDATA-1:0] = wr_mdata;
    gem2ab_RdTID[MDATA-1:0] = rd_mdata;

    gem2ab_RdLen = rd_len_q;
    gem2ab_RdEn  = (read_fsm == 2'h1) & ((~workspace_switch & ~a_full) | (workspace_switch & ~b_full));

  end

  // -----------------------------------------------------------------------------------------------------------------------------

  // ----------------
  // Grid Output FIFO
  // ----------------
  pe_out_fifo GRID_OUT_FIFO (
    .data       (grid_out             ),
    .wrreq      (grid_out_valid       ),
    .rdreq      (grid_fifo_rd_req     ),
    .clock      (clk                  ),
    .sclr       (test_Resetb          ),
    .q          (grid_fifo_out        ),
    .usedw      (grid_fifo_usedw      ),
    .full       (grid_fifo_full       ),
    .empty      (grid_fifo_empty      ),
    .almost_full(grid_fifo_almost_full)
  );

endmodule
