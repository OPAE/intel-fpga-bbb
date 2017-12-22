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

module gemm_ctl_gen #(
   DATA_WIDTH       = 16,
   FRAC_WIDTH       = 13,
   VECTOR_LENGTH    = 16,
   PE_LATENCY       = 1 ,
   ENA_PIPELINE     = 1 ,
   NUM_ROWS         = 10,
   NUM_COLS         = 16,
   A_INTERLEAVING   = 32,
   B_INTERLEAVING   = 32,
   INTERLEAVE_DEPTH = 16
) (
   input  wire                 clk                             ,
   input  wire                 rst                             ,
   input  wire                 ena                             ,
   input  wire                 wr_en_a_mem                     ,
   input  wire                 wr_en_b_mem                     ,
   input  wire                 write_interface_rdy             ,
   output reg                  sc_ena                          ,
   output reg                  di_ena                          ,
   output reg                  acc_fin                         ,
   output reg                  acc_res                         ,
   output reg                  acc_stop                        ,
   input  wire                 drain_valid [0:NUM_COLS-1]      ,
   output wire                 drain_rdy [0:NUM_COLS-1]        ,
   input  wire  [        31:0] workload_num                    ,
   input  wire  [        31:0] parts_c                         ,
   input  wire  [        31:0] a_lead_interleave               ,
   input  wire  [        31:0] b_lead_interleave               ,
   input  wire  [        31:0] feeder_interleave               ,
   input  wire                 fd_a_loaded                     ,
   input  wire                 fd_a_full                       ,
   output wire                 fd_a_wr_en                      ,
   output reg                  fd_a_rd_en                      ,
   input  wire                 fd_b_loaded                     ,
   input  wire                 fd_b_full                       ,
   output wire                 fd_b_wr_en                      ,
   output reg                  fd_b_rd_en                      ,
   output wire  [NUM_COLS-1:0] grid_out_valid                  ,
   output wire                 fda_full                        ,
   output wire                 fdb_full                        ,
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
   output reg   [        31:0] stall_count
);
   // ---------------------------------------------------------------------------

   `ifdef PACK // Enable the Packer
      localparam PACKER = 4;
   `else
      localparam PACKER = 1;
   `endif

   localparam CL_WIDTH      = 512                                  ;
   localparam ROW_WIDTH     = $clog2(NUM_ROWS)                     ;
   localparam SECTION_WIDTH = $clog2(A_INTERLEAVING*B_INTERLEAVING);

   // This is a delay introduced for pipelining the read for each of the feeders, it is currently hard-coded to 4.
   localparam FEEDERS_RD_DELAY = 4;

   // ---------------------------------------------------------------------------


   // These four signals control the various functions of the grid.
   // c_pe_ena controls when to advance to shift registers and the compute
   // c_pe_acc_res controls when we send rd_reqs to the cache fifo.
   // c_pe_acc_fin controls when to stop accumulating and start writing the results in the drain fifo.
   // c_pe_acc_stop is a fail safe that will disable all reads and writes to the cache fifo...
   logic c_pe_ena;
   logic c_pe_acc_fin;
   logic c_pe_acc_res;
   logic c_pe_acc_stop; // NO USED

   // If a_loaded and b_loaded:
   //  * We have a full buffer ready to be computed.
   //  * Read for the Feeders
   //  * ++ the s_counter
   //  * Send the ena signal
   logic data_valid;
   logic rd_feeders;

   logic [10:0] s_counter;
   logic [31:0] d_counter;

   logic stall    ;
   logic drain_in_progress;

   logic [31:0] num_rows_drained;
   logic                valid_compute   ;
   logic [NUM_COLS-1:0] grid_out_valid_q;

   logic [SECTION_WIDTH:0] section_size_neg1  ;
   logic [SECTION_WIDTH:0] section_size_q;

   logic [ROW_WIDTH + SECTION_WIDTH:0] section_x_rows  ;
   logic [ROW_WIDTH + SECTION_WIDTH:0] section_x_rows_q;
   logic [ROW_WIDTH + SECTION_WIDTH:0] rows_to_drain_neg1;

   logic [31:0] feeder_interleave_q     ;
   logic [31:0] feeder_interleave_q_neg1;
   logic [31:0] workload_num_q          ;
   logic [31:0] dot_length_q          ;
   logic [31:0] dot_length_neg1          ;
   logic [31:0] dot_length_neg2          ;

   // Section Size Calculation
   always_ff @(posedge clk) begin
      section_x_rows           <= section_x_rows_q / PACKER;
      rows_to_drain_neg1       <= section_x_rows - 1;
      section_size_neg1        <= section_size_q - 1;
      dot_length_neg1          <= dot_length_q - 1;
      dot_length_neg2          <= dot_length_q - 2;
      feeder_interleave_q_neg1 <= feeder_interleave_q - 1;
   end

   // Pipeline Multipliers
   mBit_nMult #(
      .DATA_WIDTH(SECTION_WIDTH),
      .LATENCY   (3            )
   ) SECTION_SIZE_M (
      .clk(clk              ),
      .rst(rst              ),
      .ena(1'b1             ),
      .a  (a_lead_interleave),
      .b  (b_lead_interleave),
      .m  (section_size_q   )
   );

   mBit_nMult #(
      .DATA_WIDTH(ROW_WIDTH + SECTION_WIDTH),
      .LATENCY   (3                        )
   ) SECTION_SIZE_X_ROWS_M (
      .clk(clk           ),
      .rst(rst           ),
      .ena(1'b1          ),
      .a  (section_size_q),
      .b  (NUM_ROWS      ),
      .m  (section_x_rows_q)
   );

   mBit_nMult #(
      .DATA_WIDTH(32),
      .LATENCY   (3 )
   ) DOT_LENGTH_M (
      .clk(clk                ),
      .rst(rst                ),
      .ena(1'b1               ),
      .a  (feeder_interleave_q),
      .b  (workload_num_q     ),
      .m  (dot_length_q     )
   );

   nBit_mLength_shiftRegister #(32,7) FEEDER_INTERLEAVE_QQ (clk,rst,1'b1,feeder_interleave,feeder_interleave_q);
   nBit_mLength_shiftRegister #(32,7) WORKLOAD_NUM_QQ (clk,rst,1'b1,workload_num,workload_num_q);

   // ---------------------------------------------------------------------------

   // ---------------------------------
   // Performance and Debug Connections
   // ---------------------------------
   `ifdef PERF_DBG_PERFORMANCE
      assign i_ctl_gen_read_pe_stall_a_loaded = fd_a_loaded;
      assign i_ctl_gen_read_pe_stall_b_loaded = fd_b_loaded;
      assign i_ctl_gen_write_pe_stall         = stall;
      assign i_ctl_gen_pe_compute             = sc_ena;
   `endif
   `ifdef PERF_DBG_DEBUG
      assign i_ctl_gen_pe_sections  = s_counter;
      assign i_ctl_gen_pe_blocks    = d_counter;
      assign i_ctl_gen_pe_completed = num_rows_drained;
   `endif

   // ----------------------
   // Feeder Control Signals
   // ----------------------
   assign fd_a_wr_en = wr_en_a_mem; //& ~fd_a_full;
   assign fd_b_wr_en = wr_en_b_mem; //& ~fd_b_full;

   assign fda_full = fd_a_full;
   assign fdb_full = fd_b_full;

   // This controls the feeders...
   // There is data valid and ready for compute when the feeders and loaded
   assign data_valid = fd_a_loaded && fd_b_loaded;

   // These are the read enable to the feeders
   assign fd_a_rd_en = rd_feeders;
   assign fd_b_rd_en = rd_feeders;

   // This is the increment for section_counter
   assign valid_compute = rd_feeders;

   // When the go signal has been given (ena), there is valid data in the feeders, and when there is no stall condition
   nBit_mLength_shiftRegister #(1, ENA_PIPELINE) RD_FEEDER_EN (clk ,rst, 1'b1, ena && data_valid && ~stall, rd_feeders);


   // FEEDER_RD_DELAY
   // Align:
   //   * pe_acc_fin
   //   * pe_ena (sc_ena)
   //   * pe_acc_res
   //   * pe_acc_stop
   assign c_pe_ena = valid_compute;
   nBit_mLength_shiftRegister #(1, FEEDERS_RD_DELAY) PE_ENA      (clk, rst, 1'b1, c_pe_ena, sc_ena); 
   nBit_mLength_shiftRegister #(1, FEEDERS_RD_DELAY) PE_ACC_RES  (clk, rst, 1'b1, c_pe_acc_res, acc_res); 
   nBit_mLength_shiftRegister #(1, FEEDERS_RD_DELAY) PE_ACC_FIN  (clk, rst, 1'b1, c_pe_acc_fin, acc_fin); 
   nBit_mLength_shiftRegister #(1, FEEDERS_RD_DELAY) PE_ACC_STOP (clk, rst, 1'b1, c_pe_acc_stop, acc_stop); 

   // ---------------------------------------------------------------------------

   // ----------------------
   // Drain Data Out Control
   // ----------------------
   assign grid_out_valid = &grid_out_valid_q && drain_in_progress;

   genvar            j;
   generate
      for( j=0; j<NUM_COLS; j=j+1 ) begin
         nBit_mLength_shiftRegister #(1,(NUM_COLS-j+1)*PE_LATENCY) DELAY (
            .clk     (clk                ),
            .rst     (rst                ),
            .ena     (1'b1               ),
            .data_in (drain_valid[j]     ),
            .data_out(grid_out_valid_q[j])
         );
      end
   endgenerate


   genvar i;
   generate
      for( i=0; i<NUM_COLS; i=i+1 ) begin
         nBit_mLength_shiftRegister #(1,(i)*PE_LATENCY) DELAY_RDY (
            .clk     (clk                ),
            .rst     (rst                ),
            .ena     (1'b1               ),
            .data_in (write_interface_rdy),
            .data_out(drain_rdy[i]       )
         );
      end
   endgenerate

   // DI_ENA Timing Optimisation
   nBit_mLength_shiftRegister #(1,8) DI_ENA_Q (clk,rst,1'b1,ena,di_ena);

   // ---------------------------------------------------------------------------

   // -----------
   // GEN CONTROL
   // -----------
   always @(posedge clk) begin : GEN_CTL
      // -----------------------
      // Compute Counter Control
      // -----------------------
      // If there is valid compute increment the section counter
      if(valid_compute) begin
         // Here we have completed the entire common dimension, we want to flag that there is now data to be drained.
         if ((s_counter == section_size_neg1) && (d_counter == dot_length_neg1)) begin
            c_pe_acc_fin <= 1'b0; // Write to pe drain
            c_pe_acc_res <= 1'b0; // Read from pe cache
            s_counter <= 0;
            d_counter <= 0;
         // If we are at the second last dot product we want to start putting the results into the drain fifo.
         end else if ((s_counter == section_size_neg1) && (d_counter == dot_length_neg2)) begin
            // Flag Begin write to drain...
            c_pe_acc_fin <= 1'b1;
            c_pe_acc_res <= 1'b1;
            drain_in_progress <= 1'b1;
            s_counter <= 0;
            d_counter <= d_counter + 1;
         // If we are at the end of the first section then we need to start accumulating from the cache for the subsequent sections
         end else if ((s_counter == section_size_neg1) && (d_counter == 0)) begin
            // Flag that we will now read from the cache
            c_pe_acc_fin <= 1'b0;
            c_pe_acc_res <= 1'b1;
            s_counter <= 0;
            d_counter <= d_counter + 1;
         // If we are at the end of the section, increment the dot product counter
         end else if (s_counter == section_size_neg1) begin
            s_counter <= 0;
            d_counter <= d_counter + 1;
         end else begin
            s_counter <= s_counter + 1;
         end
      end
    
      // ---------------------
      // Drain Counter Control
      // ---------------------
      if (grid_out_valid) begin
         if (num_rows_drained == (rows_to_drain_neg1)) begin
            num_rows_drained <= 0;
            drain_in_progress <= 1'b0;
         end else begin
            num_rows_drained <= num_rows_drained + 1;
         end
      end

      // -----------
      // Stall Logic
      // -----------
      if (stall) begin
         stall_count <= stall_count + 1;
      end

      if((d_counter == dot_length_neg2) && drain_in_progress) begin
         stall <= 1'b1;
      end else begin
         stall <= 1'b0;
      end

      if(rst) begin
         stall <= 1'b0;
         stall_count <= 0;
         num_rows_drained <= 0;
         drain_in_progress <= 1'b0;

         s_counter <= 0;
         d_counter <= 0;

         c_pe_acc_fin <= 1'b0;
         c_pe_acc_res <= 1'b0;
         c_pe_acc_stop <= 1'b0;
      end
   end // block : GEN_CTL

endmodule
