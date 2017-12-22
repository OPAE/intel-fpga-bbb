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

module gemm_arb #(parameter PEND_THRESH=1, ADDR_LMT=20, MDATA=14) (
  input  logic                clk                             ,
  input  logic                rst                             ,
  output logic [ADDR_LMT-1:0] ab2re_WrAddr                    ,
  output logic [        15:0] ab2re_WrTID                     ,
  output logic [       511:0] ab2re_WrDin                     ,
  output logic                ab2re_WrFence                   ,
  output logic                ab2re_WrEn                      ,
  output logic                ab2re_WrSop                     ,
  output logic [         0:1] ab2re_WrLen                     ,
  input  logic                re2ab_WrSent                    ,
  input  logic                re2ab_WrAlmFull                 ,
  output logic [ADDR_LMT-1:0] ab2re_RdAddr                    ,
  output logic [        15:0] ab2re_RdTID                     ,
  output logic                ab2re_RdEn                      ,
  output logic                ab2re_RdSop                     ,
  output logic [         0:1] ab2re_RdLen                     ,
  input  logic                re2ab_RdSent                    ,
  input  logic                re2ab_RdRspValid                ,
  input  logic                re2ab_UMsgValid                 ,
  input  logic [        15:0] re2ab_RdRsp                     ,
  input  logic [       511:0] re2ab_RdData                    ,
  input  logic                re2ab_WrRspValid                ,
  input  logic [         1:0] re2ab_WrRspCLnum                ,
  input  logic [        15:0] re2ab_WrRsp                     ,
  input  logic                re2xy_go                        ,
  input  logic [        31:0] re2xy_NumPartA                  ,
  input  logic [        31:0] re2xy_NumPartB                  ,
  input  logic [        31:0] re2xy_NumPartC                  ,
  input  logic [        31:0] re2xy_NumBlock                  ,
  input  logic [        31:0] re2xy_NumRowsXBlock             ,
  input  logic [        31:0] re2xy_NumColsXBlock             ,
  input  logic [        31:0] re2xy_TestComplete              ,
  input  logic [        31:0] re2xy_ALeadInterleave           ,
  input  logic [        31:0] re2xy_BLeadInterleave           ,
  input  logic [        31:0] re2xy_FeederInterleave          ,
  input  logic [        31:0] re2xy_FeederInterleaveRnd       ,
  output logic                ab2re_TestCmp                   ,
  output logic [       255:0] ab2re_ErrorInfo                 ,
  output logic                ab2re_ErrorValid                ,
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
  output logic                ab2re_ab_workspace_sel          ,
  output logic [        31:0] ab2re_stall_count
);

  //------------------------------------------------------------------------------------------------------------------------
  //      rp_gemm2 signal declarations
  //------------------------------------------------------------------------------------------------------------------------

  wire [ADDR_LMT-1:0] gem2ab_WrAddr   ; // [ADDR_LMT-1:0]        app_cnt:           write address
  wire [        15:0] gem2ab_WrTID    ; // [15:0]                app_cnt:           meta data
  wire [       511:0] gem2ab_WrDin    ; // [511:0]               app_cnt:           Cache line data
  wire                gem2ab_WrEn     ; //                       app_cnt:           write enable
  wire                gem2ab_WrSop    ; //                       app_cnt:           write enable
  wire [         0:1] gem2ab_WrLen    ; //                       app_cnt:           write enable
  wire                gem2ab_WrFence  ; //                       app_cnt:           read enable
  reg                 ab2gem_WrSent   ; //                       app_cnt:           write issued
  reg                 ab2gem_WrAlmFull; //                       app_cnt:           write fifo almost full

  wire [ADDR_LMT-1:0] gem2ab_RdAddr; // [ADDR_LMT-1:0]        app_cnt:           Reads may yield to writes
  wire [        15:0] gem2ab_RdTID ; // [15:0]                app_cnt:           meta data
  wire                gem2ab_RdEn  ; //                       app_cnt:           read enable
  wire                gem2ab_RdSop ; //                       app_cnt:           write enable
  wire [         0:1] gem2ab_RdLen ; //                       app_cnt:           write enable
  reg                 ab2gem_RdSent; //                       app_cnt:           read issued

  reg                ab2gem_RdRspValid; //                       app_cnt:           read response valid
  reg                ab2gem_UMsgValid ; //                       app_cnt:           UMsg valid
  reg                ab2gem_CfgValid  ; //                       app_cnt:           Cfg valid
  reg [        15:0] ab2gem_RdRsp     ; // [15:0]                app_cnt:           read response header
  reg [ADDR_LMT-1:0] ab2gem_RdRspAddr ; // [ADDR_LMT-1:0]        app_cnt:           read response address
  reg [       511:0] ab2gem_RdData    ; // [511:0]               app_cnt:           read data
  reg                ab2gem_stallRd   ; //                       app_cnt:           read stall

  reg                ab2gem_WrRspValid; //                       app_cnt:           write response valid
  reg [         1:0] ab2gem_WrRspCLnum; //                       app_cnt:           write response valid
  reg [        15:0] ab2gem_WrRsp     ; // [15:0]                app_cnt:           write response header
  reg [ADDR_LMT-1:0] ab2gem_WrRspAddr ; // [Addr_LMT-1:0]        app_cnt:           write response address

  wire         gem2ab_TestCmp   ; //                       arbiter:           Test completion flag
  wire [255:0] gem2ab_ErrorInfo ; // [255:0]               arbiter:           error information
  wire         gem2ab_ErrorValid; //                       arbiter:           test has detected an error

  logic        gem2ab_ab_workspace_sel;
  logic [31:0] gem2ab_stall_count     ;

  // local variables
  reg         re2ab_RdRspValid_q, re2ab_RdRspValid_qq;
  reg         re2ab_WrRspValid_q, re2ab_WrRspValid_qq;
  reg [  1:0] re2ab_WrRspCLnum_q, re2ab_WrRspCLnum_qq;
  reg         re2ab_UMsgValid_q, re2ab_UMsgValid_qq;
  reg [ 15:0] re2ab_RdRsp_q, re2ab_RdRsp_qq;
  reg [ 15:0] re2ab_WrRsp_q, re2ab_WrRsp_qq;
  reg [511:0] re2ab_RdData_q, re2ab_RdData_qq;

  //------------------------------------------------------------------------------------------------------------------------
  // Arbitrataion Memory instantiation
  //------------------------------------------------------------------------------------------------------------------------
  wire [ADDR_LMT-1:0] arbmem_rd_dout;
  wire [ADDR_LMT-1:0] arbmem_wr_dout;

  nlb_gram_sdp #(
    .BUS_SIZE_ADDR(MDATA   ),
    .BUS_SIZE_DATA(ADDR_LMT),
    .GRAM_MODE    (2'd3    )
  ) arb_rd_mem (
    .clk  (clk                   ),
    .we   (ab2re_RdEn            ),
    .waddr(ab2re_RdTID[MDATA-1:0]),
    .din  (ab2re_RdAddr          ),
    .raddr(re2ab_RdRsp[MDATA-1:0]),
    .dout (arbmem_rd_dout        )
  );

  nlb_gram_sdp #(
    .BUS_SIZE_ADDR(MDATA   ),
    .BUS_SIZE_DATA(ADDR_LMT),
    .GRAM_MODE    (2'd3    )
  ) arb_wr_mem (
    .clk  (clk                   ),
    .we   (ab2re_WrEn            ),
    .waddr(ab2re_WrTID[MDATA-1:0]),
    .din  (ab2re_WrAddr          ),
    .raddr(re2ab_WrRsp[MDATA-1:0]),
    .dout (arbmem_wr_dout        )
  );

  //------------------------------------------------------------------------------------------------------------------------
  always_ff @(posedge clk)
    begin
      re2ab_RdData_q  <= re2ab_RdData;
      re2ab_RdRsp_q   <= re2ab_RdRsp;
      re2ab_WrRsp_q   <= re2ab_WrRsp;
      re2ab_RdData_qq <= re2ab_RdData_q;
      re2ab_RdRsp_qq  <= re2ab_RdRsp_q;
      re2ab_WrRsp_qq  <= re2ab_WrRsp_q;
      if(rst)
        begin
          re2ab_RdRspValid_q  <= 0;
          re2ab_UMsgValid_q   <= 0;
          re2ab_WrRspValid_q  <= 0;
          re2ab_WrRspCLnum_q  <= 0;
          re2ab_RdRspValid_qq <= 0;
          re2ab_UMsgValid_qq  <= 0;
          re2ab_WrRspValid_qq <= 0;
          re2ab_WrRspCLnum_qq <= 0;
        end
      else
        begin
          re2ab_RdRspValid_q  <= re2ab_RdRspValid;
          re2ab_UMsgValid_q   <= re2ab_UMsgValid;
          re2ab_WrRspValid_q  <= re2ab_WrRspValid;
          re2ab_WrRspCLnum_q  <= re2ab_WrRspCLnum;
          re2ab_RdRspValid_qq <= re2ab_RdRspValid_q;
          re2ab_UMsgValid_qq  <= re2ab_UMsgValid_q;
          re2ab_WrRspValid_qq <= re2ab_WrRspValid_q;
          re2ab_WrRspCLnum_qq <= re2ab_WrRspCLnum_q;
        end
    end

  always_comb
    begin
      // OUTPUTs
      ab2re_WrAddr     = 0;
      ab2re_WrTID      = 0;
      ab2re_WrDin      = 'hx;
      ab2re_WrFence    = 0;
      ab2re_WrEn       = 0;
      ab2re_WrSop      = 0;
      ab2re_WrLen      = 0;
      ab2re_RdAddr     = 0;
      ab2re_RdTID      = 0;
      ab2re_RdEn       = 0;
      ab2re_RdSop      = 0;
      ab2re_RdLen      = 0;
      ab2re_TestCmp    = 0;
      ab2re_ErrorInfo  = 'h0;
      ab2re_ErrorValid = 0;

      // RP GEMM2
      ab2gem_WrSent     = 0;
      ab2gem_WrAlmFull  = 0;
      ab2gem_RdSent     = 0;
      ab2gem_RdRspValid = 0;
      ab2gem_RdRsp      = 0;
      ab2gem_RdRspAddr  = 0;
      ab2gem_RdData     = 'hx;
      ab2gem_WrRspValid = 0;
      ab2gem_WrRspCLnum = 0;
      ab2gem_WrRsp      = 0;
      ab2gem_WrRspAddr  = 0;

      ab2re_ab_workspace_sel = 0;
      ab2re_stall_count      = 0;

      // ---------------------------------------------------------------------------------------------------------------------
      //      Input to tests
      // ---------------------------------------------------------------------------------------------------------------------
      `ifdef SIM_MODE
        // Input
        ab2gem_WrSent     = re2ab_WrSent;
        ab2gem_WrAlmFull  = re2ab_WrAlmFull;
        ab2gem_RdSent     = re2ab_RdSent;
        ab2gem_RdRspValid = re2ab_RdRspValid_qq;
        ab2gem_UMsgValid  = re2ab_UMsgValid_qq;
        ab2gem_RdRsp      = re2ab_RdRsp_qq;
        ab2gem_RdRspAddr  = arbmem_rd_dout;
        ab2gem_RdData     = re2ab_RdData_qq;
        ab2gem_WrRspValid = re2ab_WrRspValid_qq;
        ab2gem_WrRspCLnum = re2ab_WrRspCLnum_qq;
        ab2gem_WrRsp      = re2ab_WrRsp_qq;
        ab2gem_WrRspAddr  = arbmem_wr_dout;

        // Output
        ab2re_WrAddr     = gem2ab_WrAddr;
        ab2re_WrTID      = gem2ab_WrTID;
        ab2re_WrDin      = gem2ab_WrDin;
        ab2re_WrFence    = gem2ab_WrFence;
        ab2re_WrEn       = gem2ab_WrEn;
        ab2re_WrSop      = gem2ab_WrSop;
        ab2re_WrLen      = gem2ab_WrLen;
        ab2re_RdAddr     = gem2ab_RdAddr;
        ab2re_RdTID      = gem2ab_RdTID;
        ab2re_RdEn       = gem2ab_RdEn;
        ab2re_RdSop      = gem2ab_RdSop;
        ab2re_RdLen      = gem2ab_RdLen;
        ab2re_TestCmp    = gem2ab_TestCmp;
        ab2re_ErrorInfo  = gem2ab_ErrorInfo;
        ab2re_ErrorValid = gem2ab_ErrorValid;

        ab2re_ab_workspace_sel = gem2ab_ab_workspace_sel;
        ab2re_stall_count      = gem2ab_stall_count;

      `else  // NOT SIM_MODE
        // PAR MODE
        // Input
        ab2gem_WrSent     = re2ab_WrSent;
        ab2gem_WrAlmFull  = re2ab_WrAlmFull;
        ab2gem_RdSent     = re2ab_RdSent;
        ab2gem_RdRspValid = re2ab_RdRspValid_qq;
        ab2gem_UMsgValid  = re2ab_UMsgValid_qq;
        ab2gem_RdRsp      = re2ab_RdRsp_qq;
        ab2gem_RdRspAddr  = arbmem_rd_dout;
        ab2gem_RdData     = re2ab_RdData_qq;
        ab2gem_WrRspValid = re2ab_WrRspValid_qq;
        ab2gem_WrRspCLnum = re2ab_WrRspCLnum_qq;
        ab2gem_WrRsp      = re2ab_WrRsp_qq;
        ab2gem_WrRspAddr  = arbmem_wr_dout;

        // Output
        ab2re_WrAddr     = gem2ab_WrAddr;
        ab2re_WrTID      = gem2ab_WrTID;
        ab2re_WrDin      = gem2ab_WrDin;
        ab2re_WrFence    = gem2ab_WrFence;
        ab2re_WrEn       = gem2ab_WrEn;
        ab2re_WrSop      = gem2ab_WrSop;
        ab2re_WrLen      = gem2ab_WrLen;
        ab2re_RdAddr     = gem2ab_RdAddr;
        ab2re_RdTID      = gem2ab_RdTID;
        ab2re_RdEn       = gem2ab_RdEn;
        ab2re_RdSop      = gem2ab_RdSop;
        ab2re_RdLen      = gem2ab_RdLen;
        ab2re_TestCmp    = gem2ab_TestCmp;
        ab2re_ErrorInfo  = gem2ab_ErrorInfo;
        ab2re_ErrorValid = gem2ab_ErrorValid;

        ab2re_ab_workspace_sel = gem2ab_ab_workspace_sel;
        ab2re_stall_count      = gem2ab_stall_count;

      `endif
    end

  gemm_mod #(
    .PEND_THRESH(PEND_THRESH),
    .ADDR_LMT   (ADDR_LMT   ),
    .MDATA      (MDATA      )
  ) INST_GEMM_MOD (
    .clk                             (clk                             ),
    .rst                             (rst                             ),
    // Requestor Input
    .re2xy_go                        (re2xy_go                        ),
    .re2xy_NumBlock                  (re2xy_NumBlock                  ),
    .re2xy_NumPartA                  (re2xy_NumPartA                  ),
    .re2xy_NumPartB                  (re2xy_NumPartB                  ),
    .re2xy_NumPartC                  (re2xy_NumPartC                  ),
    .re2xy_NumRowsXBlock             (re2xy_NumRowsXBlock             ),
    .re2xy_NumColsXBlock             (re2xy_NumColsXBlock             ),
    .re2xy_TestComplete              (re2xy_TestComplete              ),
    .re2xy_ALeadInterleave           (re2xy_ALeadInterleave           ),
    .re2xy_BLeadInterleave           (re2xy_BLeadInterleave           ),
    .re2xy_FeederInterleave          (re2xy_FeederInterleave          ),
    .re2xy_FeederInterleaveRnd       (re2xy_FeederInterleaveRnd       ),
    
    // Arbiter Write Input
    .ab2gem_WrSent                   (ab2gem_WrSent                   ),
    .ab2gem_WrAlmFull                (ab2gem_WrAlmFull                ),
    .ab2gem_WrRspValid_T0            (ab2gem_WrRspValid               ),
    .ab2gem_WrRspCLnum_T0            (ab2gem_WrRspCLnum               ),
    .ab2gem_WrRsp_T0                 (ab2gem_WrRsp                    ),
    .ab2gem_WrRspAddr_T0             (ab2gem_WrRspAddr                ),
    
    // Arbiter Read Input
    .ab2gem_RdSent                   (ab2gem_RdSent                   ),
    .ab2gem_RdRspValid_T0            (ab2gem_RdRspValid               ),
    .ab2gem_RdRsp_T0                 (ab2gem_RdRsp                    ),
    .ab2gem_RdRspAddr_T0             (ab2gem_RdRspAddr                ),
    .ab2gem_RdData_T0                (ab2gem_RdData                   ),
    
    // Arbiter Write Output
    .gem2ab_WrAddr                   (gem2ab_WrAddr                   ),
    .gem2ab_WrTID                    (gem2ab_WrTID                    ),
    .gem2ab_WrDin                    (gem2ab_WrDin                    ),
    .gem2ab_WrEn                     (gem2ab_WrEn                     ),
    .gem2ab_WrSop                    (gem2ab_WrSop                    ),
    .gem2ab_WrLen                    (gem2ab_WrLen                    ),
    .gem2ab_WrFence                  (gem2ab_WrFence                  ),
    
    // Arbiter Read Output
    .gem2ab_RdAddr                   (gem2ab_RdAddr                   ),
    .gem2ab_RdTID                    (gem2ab_RdTID                    ),
    .gem2ab_RdEn                     (gem2ab_RdEn                     ),
    .gem2ab_RdSop                    (gem2ab_RdSop                    ),
    .gem2ab_RdLen                    (gem2ab_RdLen                    ),
    
    
    .gem2ab_TestCmp                  (gem2ab_TestCmp                  ),
    .gem2ab_ErrorInfo                (gem2ab_ErrorInfo                ),
    .gem2ab_ErrorValid               (gem2ab_ErrorValid               ),
    
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
    
    .gem2ab_ab_workspace_sel         (gem2ab_ab_workspace_sel         ),
    .gem2ab_stall_count              (gem2ab_stall_count              )
  );
endmodule
