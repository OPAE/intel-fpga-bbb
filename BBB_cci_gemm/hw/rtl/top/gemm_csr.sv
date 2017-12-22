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

module gemm_csr #(
  CCIP_VERSION_NUMBER  = 0       ,
  NEXT_DFH_BYTE_OFFSET = 24'h1000,
  CSR_COUNTER_WIDTH    = 64
) (
  input  wire                 clk                        , //                              clk_pll:    16UI clock
  input  wire                 rst                        , //                              rst:        ACTIVE HIGH soft reset
  // MMIO Requests from CCI-P
  input  t_ccip_c0_ReqMmioHdr cp2cr_MmioHdr              , // [31:0]                       CSR Request Hdr
  input  t_ccip_mmioData      cp2cr_MmioDin              , // [63:0]                       CSR read data
  input  logic                cp2cr_MmioWrEn             , //                              CSR write strobe
  input  logic                cp2cr_MmioRdEn             , //                              CSR read strobe
  // MMIO Responses to CCI-P
  output t_ccip_c2_RspMmioHdr cr2cp_MmioHdr              , // [11:0]                       CSR Response Hdr
  output t_ccip_mmioData      cr2cp_MmioDout             , // [63:0]                       CSR read data
  output logic                cr2cp_MmioDout_v           , //                              CSR read data valid
  `ifdef PERF_DBG
  // Performance and Debug
  input  wire  [63:0]         csr_num_clocks             ,
  `ifdef PERF_DBG_PERFORMANCE
  // Performance OUTPUT
  input  logic [63:0]         csr_read_bw                ,
  input  logic [63:0]         csr_write_bw               ,
  input  logic [63:0]         csr_read_pe_stall          ,
  input  logic [63:0]         csr_write_pe_stall         ,
  input  logic [63:0]         csr_read_mem_almfull       ,
  input  logic [63:0]         csr_write_mem_almfull      ,
  input  logic [63:0]         csr_pe_compute_clocks      ,
  `endif
  `ifdef PERF_DBG_DEBUG
  // Debug CSRS
  // -- Feeder
  input  logic [63:0]         csr_fsm_states             ,
  input  logic [63:0]         csr_num_workload_a         ,
  input  logic [63:0]         csr_num_workload_b         ,
  input  logic [63:0]         csr_num_workload_block     ,
  // -- PE Controller
  input  logic [63:0]         csr_pe_sections            ,
  input  logic [63:0]         csr_pe_blocks              ,
  input  logic [63:0]         csr_pe_completed           ,
  `endif
  `endif
  // connections to requestor
  output wire  [63:0]         cr2re_dsm_base             ,
  output wire  [63:0]         cr2re_cfg                  ,
  output wire  [63:0]         cr2re_ctl                  ,
  output wire  [63:0]         cr2re_src_address_a        ,
  output wire  [63:0]         cr2re_src_address_b        ,
  output wire  [63:0]         cr2re_dst_address_c        ,
  output wire  [63:0]         cr2re_num_blocks           ,
  output wire  [63:0]         cr2re_num_parts_a          ,
  output wire  [63:0]         cr2re_num_parts_b          ,
  output wire  [63:0]         cr2re_num_parts_c          ,
  output wire  [63:0]         cr2re_num_rows_x_block     ,
  output wire  [63:0]         cr2re_num_cols_x_block     ,
  output wire  [63:0]         cr2re_test_complete        ,
  output wire  [63:0]         cr2re_a_lead_interleave    ,
  output wire  [63:0]         cr2re_b_lead_interleave    ,
  output wire  [63:0]         cr2re_feeder_interleave    ,
  output wire  [63:0]         cr2re_feeder_interleave_rnd
);
  // --------------------------------------------------------------------------
  // BBB Attributes
  // --------------------------------------------------------------------------
  localparam END_OF_LIST = 1'h0; // Set this to 0 if there is another DFH beyond this

  //----------------------------------------------------------------------------
  // CSR Attributes
  //----------------------------------------------------------------------------
  localparam RO    = 3'h0;
  localparam RW    = 3'h1;
  localparam RsvdP = 3'h6;
  localparam RsvdZ = 3'h6;

  //---------------------------------------------------------
  // CSR Address Map ***** DO NOT MODIFY *****
  //---------------------------------------------------------
  localparam CSR_AFH_DFH_BASE = 16'h000; // 64b             // RO - Start for the DFH info for this AFU
  localparam CSR_AFH_ID_L     = 16'h008; // 64b             // RO - Lower 64 bits of the AFU ID
  localparam CSR_AFH_ID_H     = 16'h010; // 64b             // RO - Upper 64 bits of the AFU ID
  localparam CSR_DFH_RSVD0    = 16'h018; // 64b             // RO - Offset to next AFU
  localparam CSR_DFH_RSVD1    = 16'h020; // 64b             // RO - Reserved space for DFH managment(?)

  // GEMM Specific
  localparam CSR_AFU_DSM_BASE = 16'h100; // 64b             // RW - AFU DSM base address.

  // Configuration and Control
  localparam CSR_VERSION = 16'h110; // 64b             // RO   Version of the Systolic GEMM IP
  localparam CSR_CTL     = 16'h118; // 64b             // RW   Control CSR to start n stop the test
  localparam CSR_CFG     = 16'h120; // 64b             // RW   Configures test mode, wrthru, cont and delay mode

  // Address CSRs
  localparam CSR_SRC_ADDR_A = 16'h128; // 64b             // RW   Read Address for A Matrix
  localparam CSR_SRC_ADDR_B = 16'h130; // 64b             // RW   Read Address for B Matrix
  localparam CSR_DST_ADDR_C = 16'h138; // 64b             // RW   Write Address for C Matrix

  // Systolic GEMM Parameters
  localparam CSR_NUM_BLOCKS            = 16'h140; // 64b             // RW   Number of Block in the Common Dim
  localparam CSR_NUM_PARTS_A           = 16'h148; // 64b             // RW   Number of Parts of A in the Leading Dim of A
  localparam CSR_NUM_PARTS_B           = 16'h150; // 64b             // RW   Number of Parts of B in the Leading Dim of B
  localparam CSR_NUM_PARTS_C           = 16'h158; // 64b             // RW   Number of Parts of C in the Common Dim
  localparam CSR_NUM_ROWS_X_BLOCK      = 16'h160; // 64b             // RW   Rows * Number of Blocks
  localparam CSR_NUM_COLS_X_BLOCK      = 16'h168; // 64b             // RW   Cols * Number of Blocks
  localparam CSR_TEST_COMPLETE         = 16'h170; // 64b             // RW   Number of Cache Line until test finished
  localparam CSR_A_LEAD_INTERLEAVE     = 16'h178; // 64b             // RW   Contains A leading dimension interleaving
  localparam CSR_B_LEAD_INTERLEAVE     = 16'h180; // 64b             // RW   Contains B leading dimension interleaving
  localparam CSR_FEEDER_INTERLEAVE     = 16'h188; // 64b             // RW   Contains feeder/block dimension interleaving
  localparam CSR_FEEDER_INTERLEAVE_RND = 16'h190; // 64b             // RW   Contains feeder/block dimension interleaving

  // Performance Counters
  localparam CSR_NUM_CLOCKS        = 16'h300; // 64b             // RO   Number of clocks since go signal
  localparam CSR_READ_BW           = 16'h308; // 64b             // RO   Number of read responses
  localparam CSR_WRITE_BW          = 16'h310; // 64b             // RO   Number of write responses
  localparam CSR_READ_PE_STALL     = 16'h318; // 64b             // RO   Number of times the compute stalls due to reads
  localparam CSR_WRITE_PE_STALL    = 16'h320; // 64b             // RO   Number of times the compute stalls due to writes
  localparam CSR_READ_MEM_ALMFULL  = 16'h328; // 64b             // RO   Number of times the ALMFULL is high at the read interface
  localparam CSR_WRITE_MEM_ALMFULL = 16'h330; // 64b             // RO   Number of times the ALMFULL is high at the write interface
  localparam CSR_PE_COMPUTE_CLOCKS = 16'h338; // 64b             // RO   Number of Compute Cycles

  // Debug CSRs
  // -- Feeder Controller
  localparam CSR_FSM_STATES         = 16'h400; // 64b             // RO   Controller FSM States
  localparam CSR_NUM_WORKLOAD_A     = 16'h408; // 64b             // RO   The current num part A
  localparam CSR_NUM_WORKLOAD_B     = 16'h410; // 64b             // RO   The current num part B
  localparam CSR_NUM_WORKLOAD_BLOCK = 16'h418; // 64b             // RO   The current block
  // -- PE Controller
  localparam CSR_PE_SECTIONS  = 16'h420; // 64b             // RO   What stage in the interleaving
  localparam CSR_PE_BLOCKS    = 16'h428; // 64b             // RO   What stage in the block
  localparam CSR_PE_COMPLETED = 16'h430; // 64b             // RO   Number of drained cache lines

  // Interface Debug
  localparam CSR_NUM_MPF_READ_REQ     = 16'h500; // 64b             // RO   Number of read requests at MPF
  localparam CSR_NUM_MPF_READ_RESP    = 16'h508; // 64b             // RO   Number of read responses at MPF
  localparam CSR_NUM_MPF_WRITE_REQ    = 16'h510; // 64b             // RO   Number of write requests at MPF
  localparam CSR_NUM_MPF_WRITE_RESP   = 16'h518; // 64b             // RO   Number of write responses at MPF
  localparam CSR_NUM_ASYNC_READ_REQ   = 16'h520; // 64b             // RO   Number of read requests at the ASYNC
  localparam CSR_NUM_ASYNC_READ_RESP  = 16'h528; // 64b             // RO   Number of read responsed at the ASYNC
  localparam CSR_NUM_ASYNC_WRITE_REQ  = 16'h530; // 64b             // RO   Number of write requests at the ASYNC
  localparam CSR_NUM_ASYNC_WRITE_RESP = 16'h538; // 64b             // RO   Number of write responses at the ASYNC
  localparam CSR_NUM_CCIP_READ_REQ    = 16'h540; // 64b             // RO   Number of read requests at the CCIP
  localparam CSR_NUM_CCIP_READ_RESP   = 16'h548; // 64b             // RO   Number of read responses at the CCIP
  localparam CSR_NUM_CCIP_WRITE_REQ   = 16'h550; // 64b             // RO   Number of write requests at the CCIP
  localparam CSR_NUM_CCIP_WRITE_RESP  = 16'h558; // 64b             // RO   Number of write responses at the CCIP
  localparam CSR_NUM_VL0              = 16'h560; // 64b             // RO   Number of requests sent over VL0
  localparam CSR_NUM_VH0              = 16'h568; // 64b             // RO   Number of requests sent over VH0
  localparam CSR_NUM_VH1              = 16'h570; // 64b             // RO   Number of requests sent over VH1

  //---------------------------------------------------------

  localparam NO_STAGED_CSR = 16'hXXX   ; // used for NON late action CSRs
  localparam CFG_SEG_SIZE  = 16'h500>>3; // Range specified in number of 8B CSRs
  localparam[15:0]CFG_SEG_BEG    = 16'h0000;
  localparam CFG_SEG_END    = CFG_SEG_BEG+(CFG_SEG_SIZE<<3)                   ;
  localparam L_CFG_SEG_SIZE = $clog2(CFG_SEG_SIZE) == 0?1:$clog2(CFG_SEG_SIZE);

  localparam FEATURE_0_BEG = 18'h0000;

  //WARNING: The next localparam must match what is currently in the
  //          requestor.v file.  This should be moved to a global package/file
  //          that can be used, rather than in two files.  Future Work.  PKB
  // PAR Mode
  // Each Test implements a different functionality
  // Therefore it should really be treated like a different AFU
  // For ease of maintainability they are implemented in a single source tree
  // At compile time, user can decide which test mode is synthesized.
  `ifndef SIM_MODE // PAR_MODE
  `ifdef GEMM_MODE_16 // 16 Bit
    localparam AFU_ID_H = 64'h3117_91DC_97E9_4783;
    localparam AFU_ID_L = 64'h87b7_0D33_B119_0613;
  `elsif GEMM_MODE_8 // 8 Bit
    localparam AFU_ID_H = 64'hDA52_758F_3F2A_45C1;
    localparam AFU_ID_L = 64'h89DE_7762_7064_30EA;
  `elsif GEMM_MODE_4 // 4 Bit
    localparam AFU_ID_H = 64'hEB8A_D95C_CD7F_4689;
    localparam AFU_ID_L = 64'h8F08_BE95_1633_69E7;
  `elsif GEMM_MODE_1 // 1 Bit
    localparam AFU_ID_H = 64'hD0B6_0D89_F1FF_4082;
    localparam AFU_ID_L = 64'h9B76_7E33_9BC1_D6B6;
  `elsif GEMM_MODE_32 // 32 Bit
    localparam AFU_ID_H = 64'h64F6_FA35_6025_4E72;
    localparam AFU_ID_L = 64'hAD92_15C3_A431_73A9;
  `else
    ** Select a valid GEMM mode.
    `endif
    `else   // SIM_MODE
      // Temporary Workaround
      // Simulation tests are always expecting same AFU ID
      // ** To be Fixed **
      localparam AFU_ID_H = 64'hC000_C966_0D82_4272;
    localparam AFU_ID_L = 64'h9AEF_FE5F_8457_0612;
  `endif

  localparam AFU_VERSION = 64'h0000_0001_0001_0001;

  //----------------------------------------------------------------------------------------------------------------------------------------------

  // Register File
  reg [63:0] csr_reg[2**L_CFG_SEG_SIZE-1:0]; // register file

  wire [15:0] afu_csr_addr_4B = cp2cr_MmioHdr.address;
  wire [14:0] afu_csr_addr_8B = afu_csr_addr_4B[15:1];
  //wire [1:0]         afu_csr_length    = cp2cr_MmioHdr.length;
  wire            ip_select        = afu_csr_addr_8B[14:L_CFG_SEG_SIZE]==CFG_SEG_BEG[15:L_CFG_SEG_SIZE+3];
  t_ccip_mmioData afu_csr_wrdin_T1, afu_csr_dout_T3;
  t_ccip_mmioData afu_csr_dout_T2                                                                        ;
  reg             afu_csr_wren_T1, afu_csr_rden_T1, afu_csr_dout_v_T2, afu_csr_dout_v_T3;
  t_ccip_tid      afu_csr_tid_T1, afu_csr_tid_T2, afu_csr_tid_T3;
  (* maxfan=1 *)  reg [14:0]      afu_csr_offset_8B_T1;
  integer i;

  initial begin
    for (i=0;i<2**L_CFG_SEG_SIZE;i=i+1)
      csr_reg[i] = 64'h0;
  end

  assign cr2re_dsm_base = csr_reg[CSR_AFU_DSM_BASE>>3];

  assign cr2re_ctl = csr_reg[CSR_CTL>>3];
  assign cr2re_cfg = csr_reg[CSR_CFG>>3];

  assign cr2re_src_address_a = csr_reg[CSR_SRC_ADDR_A>>3];
  assign cr2re_src_address_b = csr_reg[CSR_SRC_ADDR_B>>3];
  assign cr2re_dst_address_c = csr_reg[CSR_DST_ADDR_C>>3];

  assign cr2re_num_blocks  = csr_reg[CSR_NUM_BLOCKS>>3];
  assign cr2re_num_parts_a = csr_reg[CSR_NUM_PARTS_A>>3];
  assign cr2re_num_parts_b = csr_reg[CSR_NUM_PARTS_B>>3];
  assign cr2re_num_parts_c = csr_reg[CSR_NUM_PARTS_C>>3];

  assign cr2re_num_rows_x_block = csr_reg[CSR_NUM_ROWS_X_BLOCK>>3];
  assign cr2re_num_cols_x_block = csr_reg[CSR_NUM_COLS_X_BLOCK>>3];
  assign cr2re_test_complete    = csr_reg[CSR_TEST_COMPLETE>>3];

  assign cr2re_a_lead_interleave     = csr_reg[CSR_A_LEAD_INTERLEAVE>>3];
  assign cr2re_b_lead_interleave     = csr_reg[CSR_B_LEAD_INTERLEAVE>>3];
  assign cr2re_feeder_interleave     = csr_reg[CSR_FEEDER_INTERLEAVE>>3];
  assign cr2re_feeder_interleave_rnd = cr2re_feeder_interleave[5:0] + cr2re_feeder_interleave[0];//csr_reg[CSR_FEEDER_INTERLEAVE_RND>>3];

  always_ff @(posedge clk)
    begin
      // -Stage T1-
      afu_csr_tid_T1       <= cp2cr_MmioHdr.tid;
      afu_csr_offset_8B_T1 <= afu_csr_addr_8B;

      afu_csr_wrdin_T1 <= cp2cr_MmioDin;

      afu_csr_wren_T1 <= 1'b0;
      afu_csr_rden_T1 <= 1'b0;

      if(ip_select) begin
        afu_csr_wren_T1 <= cp2cr_MmioWrEn;
        afu_csr_rden_T1 <= cp2cr_MmioRdEn;
      end

      // -Stage T2-
      afu_csr_dout_v_T2 <= afu_csr_rden_T1;
      afu_csr_tid_T2    <= afu_csr_tid_T1;

      // This is where we read for the register file
      afu_csr_dout_T2 <= csr_reg[afu_csr_offset_8B_T1];

      // -Stage T3-
      afu_csr_dout_v_T3 <= afu_csr_dout_v_T2;
      afu_csr_tid_T3    <= afu_csr_tid_T2;
      afu_csr_dout_T3   <= afu_csr_dout_T2;

      // -Stage T4-
      cr2cp_MmioDout   <= afu_csr_dout_T3;
      cr2cp_MmioDout_v <= afu_csr_dout_v_T3;
      cr2cp_MmioHdr    <= afu_csr_tid_T3;

      if(rst) begin
        cr2cp_MmioDout_v <= 1'b0;
      end

      // AFH DFH Declarations:
      // The AFU-DFH must have the following mapping
      //      [63:60] 4'b0001
      //      [59:52] Rsvd
      //      [51:48] 4b User defined AFU mimor version #
      //      [47:41] Rsvd
      //      [40]    End of List
      //      [39:16] 24'h0 because no other DFHs
      //      [15:12] 4b User defined AFU major version #
      //      [11:0]  12'h001 CCI-P version #
      set_attr(CSR_AFH_DFH_BASE,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        {4'b0001,      // Type=AFU
          8'h0,
          4'h0,         // AFU minor version #
          7'h0,
          END_OF_LIST,
          NEXT_DFH_BYTE_OFFSET,
          4'h1,         // AFU major version #
          CCIP_VERSION_NUMBER});    // CCI-P version #

      // The AFU ID
      set_attr(CSR_AFH_ID_L,
        NO_STAGED_CSR,
        1'b1,
        {64{RO}},
        AFU_ID_L);

      set_attr(CSR_AFH_ID_H,
        NO_STAGED_CSR,
        1'b1,
        {64{RO}},
        AFU_ID_H);


      set_attr(CSR_DFH_RSVD0,
        NO_STAGED_CSR,
        1'b1,
        {64{RsvdP}},
        64'h0);

      // And set the Reserved AFU DFH 0x020 block to Reserved
      set_attr(CSR_DFH_RSVD1,
        NO_STAGED_CSR,
        1'b1,
        {64{RsvdP}},
        64'h0);

      // CSR Declarations
      // These are the parts of the CSR Register that are unique
      // for the NLB AFU.  They are not required for the FIU.
      // The are used by the SW that accesses this AFU.
      set_attr(CSR_AFU_DSM_BASE,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_CTL,
        NO_STAGED_CSR,
        1'b1,
        {{32{RW}},
          {16{RsvdP}},
          {16{RW}}
        },
        64'h0
      );

      set_attr(CSR_CFG,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_VERSION,
        NO_STAGED_CSR,
        1'b1,
        {64{RO}},
        AFU_VERSION);


      set_attr(CSR_SRC_ADDR_A,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_SRC_ADDR_B,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_DST_ADDR_C,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_NUM_BLOCKS,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_NUM_PARTS_A,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );
      set_attr(CSR_NUM_PARTS_B,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );
      set_attr(CSR_NUM_PARTS_C,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_NUM_ROWS_X_BLOCK,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_NUM_COLS_X_BLOCK,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_TEST_COMPLETE,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_A_LEAD_INTERLEAVE,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_B_LEAD_INTERLEAVE,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_FEEDER_INTERLEAVE,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      set_attr(CSR_FEEDER_INTERLEAVE_RND,
        NO_STAGED_CSR,
        1'b1,
        {64{RW}},
        64'h0
      );

      `ifdef PERF_DBG
        set_attr(CSR_NUM_CLOCKS,
          NO_STAGED_CSR,
          1'b1,
          {64{RO}},
          csr_num_clocks
        );

        `ifdef PERF_DBG_PERFORMANCE
          set_attr(CSR_READ_BW,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_read_bw
          );

          set_attr(CSR_WRITE_BW,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_write_bw
          );

          set_attr(CSR_READ_PE_STALL,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_read_pe_stall
          );

          set_attr(CSR_WRITE_PE_STALL,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_write_pe_stall
          );

          set_attr(CSR_READ_MEM_ALMFULL,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_read_mem_almfull
          );

          set_attr(CSR_WRITE_MEM_ALMFULL,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_write_mem_almfull
          );

          set_attr(CSR_PE_COMPUTE_CLOCKS,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_pe_compute_clocks
          );
        `endif
        `ifdef PERF_DBG_DEBUG

          set_attr(CSR_FSM_STATES,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_fsm_states
          );

          set_attr(CSR_NUM_WORKLOAD_A,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_num_workload_a
          );

          set_attr(CSR_NUM_WORKLOAD_B,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_num_workload_b
          );

          set_attr(CSR_NUM_WORKLOAD_BLOCK,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_num_workload_block
          );

          set_attr(CSR_PE_SECTIONS,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_pe_sections
          );

          set_attr(CSR_PE_BLOCKS,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_pe_blocks
          );

          set_attr(CSR_PE_COMPLETED,
            NO_STAGED_CSR,
            1'b1,
            {64{RO}},
            csr_pe_completed
          );
        `endif
      `endif
    end


  //----------------------------------------------------------------------------------------------------------------------------------------------
  task automatic set_attr;
    input  [15:0]       csr_id;                           // byte aligned CSR address
    input [15:0]   staged_csr_id;                    // byte aligned CSR address for late action staged register
    input      conditional_wr;                   // write condition for RW, RWS, RWDL attributes
    input [3*64-1:0]   attr;                             // Attribute for each bit in the CSR
    input [63:0]   default_val;                      // Initial value on Reset
    reg [12:0]   csr_offset_8B;
    reg [12:0]   staged_csr_offset_8B;
    reg      this_write;
    integer      i;
    begin

      csr_offset_8B = csr_id[3+:L_CFG_SEG_SIZE];
      staged_csr_offset_8B = staged_csr_id[3+:L_CFG_SEG_SIZE];
      this_write = afu_csr_wren_T1 && (csr_offset_8B==afu_csr_offset_8B_T1) && conditional_wr;

      for(i=0; i<64; i=i+1) begin: foo
        casex ({attr[i*3+:3]})
          RW : begin                                                   // - Read Write
            if(rst)
              csr_reg[csr_offset_8B][i]   <= default_val[i];
            else if(this_write)
              begin
                csr_reg[csr_offset_8B][i]   <= afu_csr_wrdin_T1[i];
              end
          end

        RO : begin                                                   // - Read Only
          csr_reg[csr_offset_8B][i]      <= default_val[i];        // update status
        end

        /*RsvdZ*/ RsvdP: begin                                     // - Software must preserve these bits
          csr_reg[csr_offset_8B][i]      <= default_val[i];    // set default value
        end

        endcase
      end
    end
  endtask

endmodule

