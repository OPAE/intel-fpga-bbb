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
module gemm_top #(
  TXHDR_WIDTH       = 61    ,
  RXHDR_WIDTH       = 18    ,
  DATA_WIDTH        = 512   ,
  MPF_DFH_MMIO_ADDR = 'h1000
) (
  input  logic        clk          ,
  input  logic        rst          ,
  input  t_if_ccip_Rx cp2af_sRxPort,
  output t_if_ccip_Tx af2cp_sTxPort
);

  localparam PEND_THRESH = 7   ;
  localparam ADDR_LMT    = 26  ;
  localparam MDATA       = 'd11;

  t_if_ccip_Tx af2cp_sTxPort_c;

  wire [   ADDR_LMT-1:0] ab2re_WrAddr    ;
  wire [           15:0] ab2re_WrTID     ;
  wire [DATA_WIDTH -1:0] ab2re_WrDin     ;
  wire                   ab2re_WrFence   ;
  wire                   ab2re_WrEn      ;
  wire                   re2ab_WrSent    ;
  wire                   re2ab_WrAlmFull ;
  wire [   ADDR_LMT-1:0] ab2re_RdAddr    ;
  wire [           15:0] ab2re_RdTID     ;
  wire                   ab2re_RdEn      ;
  wire                   re2ab_RdSent    ;
  wire                   re2ab_RdRspValid;
  wire                   re2ab_UMsgValid ;
  wire                   re2ab_CfgValid  ;
  wire [           15:0] re2ab_RdRsp     ;
  wire [DATA_WIDTH -1:0] re2ab_RdData    ;
  wire                   re2ab_stallRd   ;
  wire                   re2ab_WrRspValid;
  wire [           15:0] re2ab_WrRsp     ;
  (* `KEEP_WIRE *) wire                         re2xy_go;

  wire re2xy_Cont   ;
  wire ab2re_TestCmp;
  (* `KEEP_WIRE *) wire [255:0] ab2re_ErrorInfo;
  wire ab2re_ErrorValid;

  wire [63:0] csr_src_address_a        ;
  wire [63:0] csr_src_address_b        ;
  wire [63:0] csr_dst_address_c        ;
  wire [31:0] csr_num_blocks           ;
  wire [31:0] csr_num_parts_a          ;
  wire [31:0] csr_num_parts_b          ;
  wire [31:0] csr_num_parts_c          ;
  wire [31:0] csr_num_rows_x_block     ;
  wire [31:0] csr_num_cols_x_block     ;
  wire [31:0] csr_test_complete        ;
  wire [31:0] csr_a_lead_interleave    ;
  wire [31:0] csr_b_lead_interleave    ;
  wire [31:0] csr_feeder_interleave    ;
  wire [31:0] csr_feeder_interleave_rnd;

  wire [63:0] cr2re_cfg     ;
  wire [31:0] cr2re_ctl     ;
  wire [63:0] cr2re_dsm_base;

  logic       ab2re_RdSop;
  logic [1:0] ab2re_WrLen;
  logic [1:0] ab2re_RdLen;
  logic       ab2re_WrSop;

  logic        ab2re_ab_workspace_sel;
  logic [31:0] ab2re_stall_count     ;

  logic       re2ab_RdRspFormat;
  logic [1:0] re2ab_RdRspCLnum ;
  logic       re2ab_WrRspFormat;
  logic [1:0] re2ab_WrRspCLnum ;
  logic [1:0] re2xy_multiCL_len;

  reg [1:0] rd_len;
  reg [1:0] wr_len;

  reg rst_q = 1'b1;
  always @(posedge clk)
    begin
      rd_len <= 0;
      wr_len <= 0;
      rst_q  <= rst;
    end

  requestor #(
    .PEND_THRESH(PEND_THRESH),
    .ADDR_LMT   (ADDR_LMT   ),
    .TXHDR_WIDTH(TXHDR_WIDTH),
    .RXHDR_WIDTH(RXHDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH )
  ) INST_GEMM_REQUESTOR (
    .clk                   (clk                   ),
    .rst                   (rst_q                 ),
    
    // CCIP
    .af2cp_sTxPort         (af2cp_sTxPort_c       ),
    .cp2af_sRxPort         (cp2af_sRxPort         ),
    
    // Configuration
    .csr_cfg               (cr2re_cfg             ),
    
    // Control
    .csr_ctl               (cr2re_ctl             ),
    
    // Address
    .csr_dsm_base          (cr2re_dsm_base        ),
    .csr_src_address_a     (csr_src_address_a     ),
    .csr_src_address_b     (csr_src_address_b     ),
    .csr_dst_address_c     (csr_dst_address_c     ),
    
    .ab2re_WrAddr          (ab2re_WrAddr          ),
    .ab2re_WrTID           (ab2re_WrTID           ),
    .ab2re_WrDin           (ab2re_WrDin           ),
    .ab2re_WrFence         (ab2re_WrFence         ),
    .ab2re_WrEn            (ab2re_WrEn            ),
    .re2ab_WrSent          (re2ab_WrSent          ),
    .re2ab_WrAlmFull       (re2ab_WrAlmFull       ),
    
    .ab2re_RdAddr          (ab2re_RdAddr          ),
    .ab2re_RdTID           (ab2re_RdTID           ),
    .ab2re_RdEn            (ab2re_RdEn            ),
    .re2ab_RdSent          (re2ab_RdSent          ),
    
    .re2ab_RdRspValid      (re2ab_RdRspValid      ),
    .re2ab_UMsgValid       (re2ab_UMsgValid       ),
    .re2ab_RdRsp           (re2ab_RdRsp           ),
    .re2ab_RdData          (re2ab_RdData          ),
    .re2ab_WrRspValid      (re2ab_WrRspValid      ),
    .re2ab_WrRsp           (re2ab_WrRsp           ),
    .re2xy_go              (re2xy_go              ),
    .ab2re_ab_workspace_sel(ab2re_ab_workspace_sel),
    .ab2re_stall_count     (ab2re_stall_count     ),
    .ab2re_TestCmp         (ab2re_TestCmp         ),
    .ab2re_ErrorInfo       (ab2re_ErrorInfo       ),
    .ab2re_ErrorValid      (ab2re_ErrorValid      ),
    
    .ab2re_RdLen           (ab2re_RdLen           ),
    .ab2re_RdSop           (ab2re_RdSop           ),
    .ab2re_WrLen           (ab2re_WrLen           ),
    .ab2re_WrSop           (ab2re_WrSop           ),
    
    .re2ab_RdRspFormat     (re2ab_RdRspFormat     ),
    .re2ab_RdRspCLnum      (re2ab_RdRspCLnum      ),
    .re2ab_WrRspFormat     (re2ab_WrRspFormat     ),
    .re2ab_WrRspCLnum      (re2ab_WrRspCLnum      ),
    
    .re2xy_multiCL_len     (                      )
  );

  // Performance and Debug
  `ifdef PERF_DBG_PERFORMANCE
    logic i_ctl_gen_read_pe_stall_b_loaded;
    logic i_ctl_gen_read_pe_stall_a_loaded;
    logic i_ctl_gen_write_pe_stall        ;
    logic i_ctl_gen_pe_compute            ;
  `endif
  logic [2:0] i_ctl_read_fsm;
  `ifdef PERF_DBG_DEBUG

    logic [ 1:0] i_ctl_dmu_fsm       ;
    logic [ 1:0] i_ctl_grid_fsm      ;
    logic [31:0] i_ctl_num_workspace ;
    logic [31:0] i_ctl_num_workload_a;
    logic [31:0] i_ctl_num_workload_b;

    logic [10:0] i_ctl_gen_pe_sections ;
    logic [31:0] i_ctl_gen_pe_blocks   ;
    logic [31:0] i_ctl_gen_pe_completed;
  `endif

  gemm_arb #(
    .PEND_THRESH(PEND_THRESH),
    .ADDR_LMT   (ADDR_LMT   ),
    .MDATA      (MDATA      )
  ) INST_GEMM_ARB (
    .clk                             (clk                             ),
    .rst                             (rst_q                           ),
    .ab2re_WrAddr                    (ab2re_WrAddr                    ),
    .ab2re_WrTID                     (ab2re_WrTID                     ),
    .ab2re_WrDin                     (ab2re_WrDin                     ),
    .ab2re_WrFence                   (ab2re_WrFence                   ),
    .ab2re_WrEn                      (ab2re_WrEn                      ),
    .ab2re_WrSop                      (ab2re_WrSop                      ),
    .ab2re_WrLen                     (ab2re_WrLen                     ),
    .re2ab_WrSent                    (re2ab_WrSent                    ),
    .re2ab_WrAlmFull                 (re2ab_WrAlmFull                 ),

    .ab2re_RdAddr                    (ab2re_RdAddr                    ),
    .ab2re_RdTID                     (ab2re_RdTID                     ),
    .ab2re_RdEn                      (ab2re_RdEn                      ),
    .ab2re_RdSop                      (ab2re_RdSop                      ),
    .ab2re_RdLen                     (ab2re_RdLen                     ),
    .re2ab_RdSent                    (re2ab_RdSent                    ),

    .re2ab_RdRspValid                (re2ab_RdRspValid                ),
    .re2ab_UMsgValid                 (re2ab_UMsgValid                 ),
    .re2ab_RdRsp                     (re2ab_RdRsp                     ),
    .re2ab_RdData                    (re2ab_RdData                    ),

    .re2ab_WrRspValid                (re2ab_WrRspValid                ),
    .re2ab_WrRspCLnum                (re2ab_WrRspCLnum                ),
    .re2ab_WrRsp                     (re2ab_WrRsp                     ),

    .re2xy_go                        (re2xy_go                        ),
    .re2xy_NumPartA                  (csr_num_parts_a                 ),
    .re2xy_NumPartB                  (csr_num_parts_b                 ),
    .re2xy_NumPartC                  (csr_num_parts_c                 ),
    .re2xy_NumBlock                  (csr_num_blocks                  ),
    .re2xy_NumRowsXBlock             (csr_num_rows_x_block            ),
    .re2xy_NumColsXBlock             (csr_num_cols_x_block            ),
    .re2xy_TestComplete              (csr_test_complete               ),
    .re2xy_ALeadInterleave           (csr_a_lead_interleave           ),
    .re2xy_BLeadInterleave           (csr_b_lead_interleave           ),
    .re2xy_FeederInterleave          (csr_feeder_interleave           ),
    .re2xy_FeederInterleaveRnd          (csr_feeder_interleave_rnd           ),

    .ab2re_TestCmp                   (ab2re_TestCmp                   ),
    .ab2re_ErrorInfo                 (ab2re_ErrorInfo                 ),
    .ab2re_ErrorValid                (ab2re_ErrorValid                ),

    `ifdef PERF_DBG_PERFORMANCE
      .i_ctl_gen_read_pe_stall_a_loaded(i_ctl_gen_read_pe_stall_a_loaded),
        .i_ctl_gen_read_pe_stall_b_loaded(i_ctl_gen_read_pe_stall_b_loaded),
          .i_ctl_gen_write_pe_stall        (i_ctl_gen_write_pe_stall        ),
            .i_ctl_gen_pe_compute            (i_ctl_gen_pe_compute            ),
            `endif
            .i_ctl_read_fsm                  (i_ctl_read_fsm                  ),
            `ifdef PERF_DBG_DEBUG
              .i_ctl_dmu_fsm                   (i_ctl_dmu_fsm                   ),
                .i_ctl_grid_fsm                  (i_ctl_grid_fsm                  ),
                  .i_ctl_num_workspace             (i_ctl_num_workspace             ),
                    .i_ctl_num_workload_a            (i_ctl_num_workload_a            ),
                      .i_ctl_num_workload_b            (i_ctl_num_workload_b            ),

                        .i_ctl_gen_pe_sections           (i_ctl_gen_pe_sections           ),
                          .i_ctl_gen_pe_blocks             (i_ctl_gen_pe_blocks             ),
                            .i_ctl_gen_pe_completed          (i_ctl_gen_pe_completed          ),
                            `endif

                            .ab2re_ab_workspace_sel          (ab2re_ab_workspace_sel          ),
                            .ab2re_stall_count               (ab2re_stall_count               )
                          );

                          t_ccip_c0_ReqMmioHdr cp2cr_MmioHdr   ;
                          logic                cp2cr_MmioWrEn  ;
                          logic                cp2cr_MmioRdEn  ;
                          t_ccip_mmioData      cp2cr_MmioDin   ;
                          t_ccip_mmioData      cr2cp_MmioDout  ;
                          logic                cr2cp_MmioDout_v;
                          t_ccip_c2_RspMmioHdr cr2cp_MmioHdr   ;

                          always_comb
                            begin
                              cp2cr_MmioHdr  = t_ccip_c0_ReqMmioHdr'(cp2af_sRxPort.c0.hdr);
                              cp2cr_MmioWrEn = cp2af_sRxPort.c0.mmioWrValid;
                              cp2cr_MmioRdEn = cp2af_sRxPort.c0.mmioRdValid;
                              cp2cr_MmioDin  = cp2af_sRxPort.c0.data[CCIP_MMIODATA_WIDTH-1:0];

                              af2cp_sTxPort                = af2cp_sTxPort_c;
                              af2cp_sTxPort.c2.hdr         = cr2cp_MmioHdr;
                              af2cp_sTxPort.c2.data        = cr2cp_MmioDout;
                              af2cp_sTxPort.c2.mmioRdValid = cr2cp_MmioDout_v;
                            end


                          // Performance and Debug CSRs
                          localparam CSR_COUNTER_WIDTH = 64;
                          `ifdef PERF_DBG
                            logic [CSR_COUNTER_WIDTH-1:0] csr_num_clocks;
                          `endif

                          `ifdef PERF_DBG_PERFORMANCE
                            logic [CSR_COUNTER_WIDTH-1:0] csr_read_bw          ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_write_bw         ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_read_pe_stall    ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_write_pe_stall   ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_read_mem_almfull ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_write_mem_almfull;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_pe_compute_clocks;
                          `endif

                          `ifdef PERF_DBG_DEBUG
                            logic [CSR_COUNTER_WIDTH-1:0] csr_fsm_states;

                            // Debug CSRS
                            // -- Feeder
                            logic [CSR_COUNTER_WIDTH-1:0] csr_fsm_states        ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_num_workload_a    ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_num_workload_b    ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_num_workload_block;
                            // -- PE Controller
                            logic [CSR_COUNTER_WIDTH-1:0] csr_pe_sections ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_pe_blocks   ;
                            logic [CSR_COUNTER_WIDTH-1:0] csr_pe_completed;
                          `endif

                          // GEMM CSRs
  gemm_csr #(
    .CCIP_VERSION_NUMBER (CCIP_VERSION_NUMBER),
    .NEXT_DFH_BYTE_OFFSET(MPF_DFH_MMIO_ADDR  ),
    .CSR_COUNTER_WIDTH   (CSR_COUNTER_WIDTH  )
  ) INST_GEMM_CSR (
    .clk                    (clk                   ),
    .rst                    (rst_q                 ),
    
    // MMIO CSR Requests
    .cp2cr_MmioHdr          (cp2cr_MmioHdr         ),
    .cp2cr_MmioDin          (cp2cr_MmioDin         ),
    .cp2cr_MmioWrEn         (cp2cr_MmioWrEn        ),
    .cp2cr_MmioRdEn         (cp2cr_MmioRdEn        ),
    .cr2cp_MmioHdr          (cr2cp_MmioHdr         ),
    .cr2cp_MmioDout         (cr2cp_MmioDout        ),
    .cr2cp_MmioDout_v       (cr2cp_MmioDout_v      ),
    `ifdef PERF_DBG
    // Performance and Debug CSRs
    .csr_num_clocks         (csr_num_clocks        ),
    `ifdef PERF_DBG_PERFORMANCE
    // Performance OUTPUT
    .csr_read_bw            (csr_read_bw           ),
    .csr_write_bw           (csr_write_bw          ),
    .csr_read_pe_stall      (csr_read_pe_stall     ),
    .csr_write_pe_stall     (csr_write_pe_stall    ),
    .csr_read_mem_almfull   (csr_read_mem_almfull  ),
    .csr_write_mem_almfull  (csr_write_mem_almfull ),
    .csr_pe_compute_clocks  (csr_pe_compute_clocks ),
    `endif
    `ifdef PERF_DBG_DEBUG
    // Debug CSRS
    // -- Feeder
    .csr_fsm_states         (csr_fsm_states        ),
    .csr_num_workload_a     (csr_num_workload_a    ),
    .csr_num_workload_b     (csr_num_workload_b    ),
    .csr_num_workload_block (csr_num_workload_block),
    // -- PE Controller
    .csr_pe_sections        (csr_pe_sections       ),
    .csr_pe_blocks          (csr_pe_blocks         ),
    .csr_pe_completed       (csr_pe_completed      ),
    `endif
    `endif
    // CSR Exposed to the Requestor
    .cr2re_dsm_base         (cr2re_dsm_base        ),
    .cr2re_cfg              (cr2re_cfg             ),
    .cr2re_ctl              (cr2re_ctl             ),
    .cr2re_src_address_a    (csr_src_address_a     ),
    .cr2re_src_address_b    (csr_src_address_b     ),
    .cr2re_dst_address_c    (csr_dst_address_c     ),
    
    // CSR Exposed to the GEMM
    .cr2re_num_blocks       (csr_num_blocks        ),
    .cr2re_num_parts_a      (csr_num_parts_a       ),
    .cr2re_num_parts_b      (csr_num_parts_b       ),
    .cr2re_num_parts_c      (csr_num_parts_c       ),
    .cr2re_num_rows_x_block (csr_num_rows_x_block  ),
    .cr2re_num_cols_x_block (csr_num_cols_x_block  ),
    .cr2re_test_complete    (csr_test_complete     ),
    .cr2re_a_lead_interleave(csr_a_lead_interleave ),
    .cr2re_b_lead_interleave(csr_b_lead_interleave ),
    .cr2re_feeder_interleave(csr_feeder_interleave ),
    .cr2re_feeder_interleave_rnd(csr_feeder_interleave_rnd )
  );

                          `ifdef PERF_DBG
                            // GEMM Performance and Debug Gather Module
    gemm_perf_dbg INST_GEMM_PERF_DBG (
      .clk                             (clk                             ),
      .rst                             (rst_q                           ),
      .i_go                            (re2xy_go                        ),
      
      `ifdef PERF_DBG_PERFORMANCE
      // Performance INPUT
      .i_req_rd_rsp_valid              (re2ab_RdRspValid                ),
      .i_req_wr_rsp_valid              (re2ab_WrRspValid                ),
      .i_req_read_mem_almfull          (cp2af_sRxPort.c0TxAlmFull       ),
      .i_req_write_mem_almfull         (cp2af_sRxPort.c1TxAlmFull       ),
      .i_ctl_gen_read_pe_stall_a_loaded(i_ctl_gen_read_pe_stall_a_loaded),
      .i_ctl_gen_read_pe_stall_b_loaded(i_ctl_gen_read_pe_stall_b_loaded),
      .i_ctl_gen_write_pe_stall        (i_ctl_gen_write_pe_stall        ),
      .i_ctl_gen_pe_compute            (i_ctl_gen_pe_compute            ),
      
      // Performance OUTPUT
      .csr_read_bw                     (csr_read_bw                     ),
      .csr_write_bw                    (csr_write_bw                    ),
      .csr_read_pe_stall               (csr_read_pe_stall               ),
      .csr_write_pe_stall              (csr_write_pe_stall              ),
      .csr_read_mem_almfull            (csr_read_mem_almfull            ),
      .csr_write_mem_almfull           (csr_write_mem_almfull           ),
      .csr_pe_compute_clocks           (csr_pe_compute_clocks           ),
      `endif
      .i_ctl_read_fsm                  (i_ctl_read_fsm                  ),
      `ifdef PERF_DBG_DEBUG
      // Debug INPUT
      .i_ctl_dmu_fsm                   (i_ctl_dmu_fsm                   ),
      .i_ctl_grid_fsm                  (i_ctl_grid_fsm                  ),
      .i_ctl_num_workspace             (i_ctl_num_workspace             ),
      .i_ctl_num_workload_a            (i_ctl_num_workload_a            ),
      .i_ctl_num_workload_b            (i_ctl_num_workload_b            ),
      
      .i_ctl_gen_pe_sections           (i_ctl_gen_pe_sections           ),
      .i_ctl_gen_pe_blocks             (i_ctl_gen_pe_blocks             ),
      .i_ctl_gen_pe_completed          (i_ctl_gen_pe_completed          ),
      
      // Debug CSRS
      // -- Feeder
      .csr_fsm_states                  (csr_fsm_states                  ),
      .csr_num_workload_a              (csr_num_workload_a              ),
      .csr_num_workload_b              (csr_num_workload_b              ),
      .csr_num_workload_block          (csr_num_workload_block          ),
      // -- PE Controller
      .csr_pe_sections                 (csr_pe_sections                 ),
      .csr_pe_blocks                   (csr_pe_blocks                   ),
      .csr_pe_completed                (csr_pe_completed                ),
      `endif
      `ifdef PERF_DBG_IF_DEBUG
      // Interface Debug
      .csr_num_mpf_read_req            (                                ),
      .csr_num_mpf_read_resp           (                                ),
      .csr_num_mpf_write_req           (                                ),
      .csr_num_mpf_write_resp          (                                ),
      
      .csr_num_async_read_req          (                                ),
      .csr_num_async_read_resp         (                                ),
      .csr_num_async_write_req         (                                ),
      .csr_num_async_write_resp        (                                ),
      
      .csr_num_ccip_read_req           (                                ),
      .csr_num_ccip_read_resp          (                                ),
      .csr_num_ccip_write_req          (                                ),
      .csr_num_ccip_write_resp         (                                ),
      
      .csr_num_vl0                     (                                ),
      .csr_num_vh0                     (                                ),
      .csr_num_vh1                     (                                ),
      `endif
      
      .csr_num_clocks                  (csr_num_clocks                  )
    );
                          `endif

                        endmodule
