//
// Copyright (c) 2016, Intel Corporation
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

module gemm_gen #(
  DATA_WIDTH       = 8  ,
  ACCU_WIDTH       = 8  ,
  FRAC_WIDTH       = 5  ,
  VECTOR_LENGTH    = 32 ,
  PE_LATENCY       = 1  ,
  NUM_ROWS         = 10 ,
  NUM_COLS         = 16 ,
  A_INTERLEAVING   = 32 ,
  B_INTERLEAVING   = 32 ,
  INTERLEAVE_DEPTH = 16 ,
  CL_WIDTH         = 512,
  NUM_BUFFERS      = 2
) (
  input  wire                 clk                             ,
  input  wire                 rst                             ,
  input  wire                 ena                             ,
  input  wire  [CL_WIDTH-1:0] wr_data_a_mem                   ,
  input  wire  [CL_WIDTH-1:0] wr_data_b_mem                   ,
  input  wire                 wr_en_a_mem                     ,
  input  wire                 wr_en_b_mem                     ,
  input  wire  [        31:0] workload_num                    ,
  input  wire  [        31:0] parts_c                         ,
  input  wire  [        31:0] a_lead_interleave               ,
  input  wire  [        31:0] b_lead_interleave               ,
  input  wire  [        31:0] feeder_interleave               ,
  input  wire  [        31:0] feeder_interleave_rnd           ,
  input  wire                 write_interface_rdy             ,
  output wire  [CL_WIDTH-1:0] grid_out                        ,
  output wire                 grid_out_valid                  ,
  output wire                 fd_a_full                       ,
  output wire                 fd_b_full                       ,
  `ifdef PERF_DBG_PERFORMANCE
  output logic                i_ctl_gen_read_pe_stall_a_loaded,
  output logic                i_ctl_gen_read_pe_stall_b_loaded,
  output logic                i_ctl_gen_write_pe_stall        ,
  output logic                i_ctl_gen_pe_compute            ,
  `endif
  `ifdef PERF_DBG_DEBUG
  output logic [        10:0] i_ctl_gen_pe_sections           ,
  output logic [        31:0] i_ctl_gen_pe_blocks             ,
  output logic [        31:0] i_ctl_gen_pe_completed          ,
  `endif
  output wire  [        31:0] stall_count
);
  // ---------------------------------------------------------------------------

  localparam VECTOR_WIDTH = DATA_WIDTH*VECTOR_LENGTH;
  localparam OUT_WIDTH    = 32                      ;
  localparam ENA_PIPELINE = 3                       ;

  // ---------------------------------------------------------------------------

  wire gen_ctl_dp_rst;
  wire gen_ctl_dp_ena;

  wire gen_ctl_dp_di_ena;

  wire gen_ctl_dp_acc_fin ;
  wire gen_ctl_dp_acc_res ;
  wire gen_ctl_dp_acc_stop;

  wire gen_ctl_dp_drain_rdy  [0:NUM_COLS-1];
  wire gen_ctl_dp_drain_valid[0:NUM_COLS-1];

  wire gen_ctl_dp_fd_a_wr_en ;
  wire gen_ctl_dp_fd_a_rd_en ;
  wire gen_ctl_dp_fd_a_loaded;
  wire gen_ctl_dp_fd_a_full  ;

  wire gen_ctl_dp_fd_b_wr_en ;
  wire gen_ctl_dp_fd_b_rd_en ;
  wire gen_ctl_dp_fd_b_loaded;
  wire gen_ctl_dp_fd_b_full  ;

  // ---------------------------------------------------------------------------

  // Reset Timing Optimisation
  reg rst_q;
  always @(posedge clk) begin
    rst_q <= rst;
  end

  logic [31:0] a_lead_interleave_q    ;
  logic [31:0] b_lead_interleave_q    ;
  logic [31:0] feeder_interleave_q    ;
  logic [31:0] feeder_interleave_rnd_q;

  nBit_mLength_shiftRegister #(32,3) A_INTERLEAVE_QQ (clk,rst,1'b1,a_lead_interleave,a_lead_interleave_q);
  nBit_mLength_shiftRegister #(32,3) B_INTERLEAVE_QQ (clk,rst,1'b1,b_lead_interleave,b_lead_interleave_q);
  nBit_mLength_shiftRegister #(32,3) F_INTERLEAVE_QQ (clk,rst,1'b1,feeder_interleave,feeder_interleave_q);
  nBit_mLength_shiftRegister #(32,3) F_INTERLEAVE_RND_QQ (clk,rst,1'b1,feeder_interleave_rnd,feeder_interleave_rnd_q);

  // ---------------------------------------------------------------------------

  // --------------
  // Control Module
  // --------------
  gemm_ctl_gen #(
    .DATA_WIDTH      (DATA_WIDTH      ),
    .FRAC_WIDTH      (FRAC_WIDTH      ),
    .VECTOR_LENGTH   (VECTOR_LENGTH   ),
    .PE_LATENCY      (PE_LATENCY      ),
    .ENA_PIPELINE    (ENA_PIPELINE    ),
    .NUM_ROWS        (NUM_ROWS        ),
    .NUM_COLS        (NUM_COLS        ),
    .A_INTERLEAVING  (A_INTERLEAVING  ),
    .B_INTERLEAVING  (B_INTERLEAVING  ),
    .INTERLEAVE_DEPTH(INTERLEAVE_DEPTH)
  ) INST_GEMM_CTL_GEN (
    .clk                             (clk                             ),
    
    .rst                             (rst_q                           ),
    .ena                             (ena                             ),
    
    .wr_en_a_mem                     (wr_en_a_mem                     ),
    .wr_en_b_mem                     (wr_en_b_mem                     ),
    
    .write_interface_rdy             (write_interface_rdy             ),
    
    .sc_ena                          (gen_ctl_dp_ena                  ),
    .di_ena                          (gen_ctl_dp_di_ena               ),
    .acc_fin                         (gen_ctl_dp_acc_fin              ),
    .acc_res                         (gen_ctl_dp_acc_res              ),
    .acc_stop                        (gen_ctl_dp_acc_stop             ),
    
    .drain_rdy                       (gen_ctl_dp_drain_rdy            ),
    .drain_valid                     (gen_ctl_dp_drain_valid          ),
    
    .workload_num                    (workload_num                    ),
    .parts_c                         (parts_c                         ),
    
    .a_lead_interleave               (a_lead_interleave_q             ),
    .b_lead_interleave               (b_lead_interleave_q             ),
    .feeder_interleave               (feeder_interleave_q             ),
    
    .fd_a_wr_en                      (gen_ctl_dp_fd_a_wr_en           ),
    .fd_a_rd_en                      (gen_ctl_dp_fd_a_rd_en           ),
    .fd_a_loaded                     (gen_ctl_dp_fd_a_loaded          ),
    .fd_a_full                       (gen_ctl_dp_fd_a_full            ),
    
    .fd_b_wr_en                      (gen_ctl_dp_fd_b_wr_en           ),
    .fd_b_rd_en                      (gen_ctl_dp_fd_b_rd_en           ),
    .fd_b_loaded                     (gen_ctl_dp_fd_b_loaded          ),
    .fd_b_full                       (gen_ctl_dp_fd_b_full            ),
    
    .grid_out_valid                  (grid_out_valid                  ),
    .fda_full                        (fd_a_full                       ),
    .fdb_full                        (fd_b_full                       ),
    
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
    
    .stall_count                     (stall_count                     )
  );

  // -------------------
  // Datapath Generation
  // -------------------
  gemm_dp_gen #(
    .DATA_WIDTH      (DATA_WIDTH      ),
    .ACCU_WIDTH      (ACCU_WIDTH      ),
    .FRAC_WIDTH      (FRAC_WIDTH      ),
    .VECTOR_LENGTH   (VECTOR_LENGTH   ),
    .PE_LATENCY      (PE_LATENCY      ),
    .ENA_PIPELINE    (ENA_PIPELINE    ),
    .NUM_ROWS        (NUM_ROWS        ),
    .NUM_COLS        (NUM_COLS        ),
    .A_INTERLEAVING  (A_INTERLEAVING  ),
    .B_INTERLEAVING  (B_INTERLEAVING  ),
    .INTERLEAVE_DEPTH(INTERLEAVE_DEPTH),
    .NUM_BUFFERS     (NUM_BUFFERS     )
  ) INST_GEMM_DP_GEN (
    .clk                      (clk                    ),
    .rst                      (rst_q                  ),
    .ena                      (gen_ctl_dp_ena         ),
    
    .di_ena                   (gen_ctl_dp_di_ena      ),
    
    .a_lead_interleave        (a_lead_interleave_q    ),
    .b_lead_interleave        (b_lead_interleave_q    ),
    .feeder_interleave        (feeder_interleave_q    ),
    .feeder_interleave_rnd    (feeder_interleave_rnd_q),
    
    .acc_fin                  (gen_ctl_dp_acc_fin     ),
    .acc_res                  (gen_ctl_dp_acc_res     ),
    .acc_stop                 (gen_ctl_dp_acc_stop    ),
    
    .drain_rdy                (gen_ctl_dp_drain_rdy   ),
    .drain_valid              (gen_ctl_dp_drain_valid ),
    
    .fd_a_wr_en               (gen_ctl_dp_fd_a_wr_en  ),
    .fd_a_rd_en               (gen_ctl_dp_fd_a_rd_en  ),
    .fd_a_loaded              (gen_ctl_dp_fd_a_loaded ),
    .fd_a_full                (gen_ctl_dp_fd_a_full   ),
    
    .fd_a_wr_data             (wr_data_a_mem          ),
    
    .fd_b_wr_en               (gen_ctl_dp_fd_b_wr_en  ),
    .fd_b_rd_en               (gen_ctl_dp_fd_b_rd_en  ),
    .fd_b_loaded              (gen_ctl_dp_fd_b_loaded ),
    .fd_b_full                (gen_ctl_dp_fd_b_full   ),
    
    .fd_b_wr_data             (wr_data_b_mem          ),
    
    .drain_interconnect_output(grid_out               )
  );

  // ---------------------------------------------------------------------------
endmodule
