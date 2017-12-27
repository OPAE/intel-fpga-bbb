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

module gemm_dp_gen # (
			  DATA_WIDTH = 8,
			  ACCU_WIDTH = 8,
			  FRAC_WIDTH = 5,
			  VECTOR_LENGTH = 32,
			  PE_LATENCY = 1,
			  ENA_PIPELINE = 1,
			  NUM_ROWS = 1,
			  NUM_COLS = 1,
			  A_INTERLEAVING = 32,
           B_INTERLEAVING = 32,
			  INTERLEAVE_DEPTH = 16,
           NUM_BUFFERS = 2
			  ) (
			     clk,

			     // Standard Control
			     rst,
			     ena,

			     // Accumulator Cache Control
			     acc_fin,
			     acc_res,
			     acc_stop,

			     // Drain Control
			     drain_rdy,
			     drain_valid,

			     // Feeder A Control
			     fd_a_wr_en,
			     fd_a_rd_en,
			     fd_a_loaded,
			     fd_a_full,

			     // Feeder A Data
			     fd_a_wr_data,

			     // Feeder B Control
			     fd_b_wr_en,
			     fd_b_rd_en,
			     fd_b_loaded,
			     fd_b_full,

			     // Feeder B Data
			     fd_b_wr_data,

			     // Drain Interconnect Control
			     di_ena,

			     // Interleaving Factor
			     a_lead_interleave,
           b_lead_interleave,
           feeder_interleave,
           feeder_interleave_rnd,

			     // Drain Output
			     drain_interconnect_output
			     );
   
   // ---------------------------------------------------------------------------

   localparam VECTOR_WIDTH = DATA_WIDTH*VECTOR_LENGTH;
   localparam OUT_WIDTH = 32;
   localparam CL_WIDTH = 512;

   // ---------------------------------------------------------------------------

   // ----------------
   // Standard Control
   // ----------------
   input wire clk;
   input wire rst;
   input wire ena;

   // -------------------------
   // Accumulator Cache Control
   // -------------------------
   input wire acc_fin;
   input wire acc_res;
   input wire acc_stop;

   // -------------
   // Drain Control
   // -------------
   input wire drain_rdy    [0:NUM_COLS-1];
   output wire drain_valid    [0:NUM_COLS-1];

   // ----------------
   // Feeder A Control
   // ----------------
   input wire  fd_a_wr_en;
   input wire  fd_a_rd_en;
   output wire fd_a_loaded;
   output wire fd_a_full;

   // -------------
   // Feeder A Data
   // -------------
   input wire [CL_WIDTH-1:0] fd_a_wr_data;

   // ----------------
   // Feeder B Control
   // ----------------
   input wire 		     fd_b_wr_en;
   input wire 		     fd_b_rd_en;
   output wire 		     fd_b_loaded;
   output wire 		     fd_b_full;

   // -------------
   // Feeder B Data
   // -------------
   input wire [CL_WIDTH-1:0] fd_b_wr_data;

   // --------------------------
   // Drain Interconnect Control
   // --------------------------
   input wire 		     di_ena; 

   // -------------------
   // Interleaving Factor
   // -------------------
   input wire [31:0] 	     a_lead_interleave; 
   input wire [31:0]       b_lead_interleave; 
   input wire [31:0]       feeder_interleave; 
   input wire [31:0]       feeder_interleave_rnd; 

   // -------------------------
   // Drain Interconnect Output
   // -------------------------
   output wire [CL_WIDTH-1:0] drain_interconnect_output;

   // ---------------------------------------------------------------------------

   // Reset Timing Optimisation
   wire 		      rst_q;
   nBit_mLength_shiftRegister # (1, 4, 4) DP_RST_Q (clk, 1'b0, 1'b1, rst, rst_q); 
   
   logic [31:0] 	      a_lead_interleave_q;
   logic [31:0]         b_lead_interleave_q;
   logic [31:0]         feeder_interleave_q;
   logic [31:0]         feeder_interleave_rnd_q;

   logic [31:0]         feeder_interleave_q_a;
   logic [31:0]         feeder_interleave_rnd_q_a;
   logic [31:0]         feeder_interleave_q_b;
   logic [31:0]         feeder_interleave_rnd_q_b;

   nBit_mLength_shiftRegister # (32, 4) A_INTERLEAVE_QQ (clk, rst, 1'b1, a_lead_interleave, a_lead_interleave_q);
   nBit_mLength_shiftRegister # (32, 4) B_INTERLEAVE_QQ (clk, rst, 1'b1, b_lead_interleave, b_lead_interleave_q);
   nBit_mLength_shiftRegister # (32, 4) F_INTERLEAVE_QQ (clk, rst, 1'b1, feeder_interleave, feeder_interleave_q);
   nBit_mLength_shiftRegister # (32, 4) F_INTERLEAVE_RND_QQ (clk, rst, 1'b1, feeder_interleave_rnd, feeder_interleave_rnd_q);

   always_ff @(posedge clk) begin
      feeder_interleave_q_a <= feeder_interleave_q;
      feeder_interleave_rnd_q_a <= feeder_interleave_rnd_q;
      feeder_interleave_q_b <= feeder_interleave_q;
      feeder_interleave_rnd_q_b <= feeder_interleave_rnd_q;
   end

   // ---------------------------------------------------------------------------

   // -------------------
   // PE Grid Connections
   // -------------------
   wire [VECTOR_WIDTH-1:0]    grid_feeder_a [0:NUM_ROWS-1];
   wire [VECTOR_WIDTH-1:0]    grid_feeder_b [0:NUM_COLS-1]; 

   wire [VECTOR_WIDTH-1:0]    a_in [0:NUM_ROWS-1];
   wire [VECTOR_WIDTH-1:0]    b_in [0:NUM_COLS-1];

   wire 		      ena_in [0:NUM_ROWS-1];
   wire 		      rst_in [0:NUM_ROWS-1];
   wire 		      acc_res_in [0:NUM_ROWS-1];
   wire 		      acc_fin_in [0:NUM_ROWS-1];
   wire 		      acc_stop_in [0:NUM_ROWS-1];

   wire [ACCU_WIDTH-1:0]      grid_output [0:NUM_COLS-1]; 

   genvar 		      i;

   // ---------------------------------------------------------------------------

   // ---------
   // Feeders A
   // ---------
   localparam IS_A = 1;
   feeders # ( 
	       .DATA_WIDTH       (DATA_WIDTH),
	       .VECTOR_LENGTH    (VECTOR_LENGTH), 
	       .IS_A             (IS_A),
	       .NUM_FEEDERS      (NUM_ROWS),
	       .A_INTERLEAVING   (A_INTERLEAVING),
          .B_INTERLEAVING   (B_INTERLEAVING),
	       .INTERLEAVE_DEPTH (INTERLEAVE_DEPTH), 
	       .ENA_PIPELINE     (ENA_PIPELINE),
          .NUM_BUFFERS      (NUM_BUFFERS)
	       ) FDA (
		      .clk        (clk),
		      .rst        (rst_q),
		      .wr_en      (fd_a_wr_en),
		      .a_lead_interleave  (a_lead_interleave_q),
          .b_lead_interleave  (b_lead_interleave_q),
          .feeder_interleave  (feeder_interleave_q_a),
          .feeder_interleave_rnd  (feeder_interleave_rnd_q_a),
		      .wr_data    (fd_a_wr_data),
		      .rd_en      (fd_a_rd_en),
		      .rd_data    (grid_feeder_a),
		      .loaded     (fd_a_loaded),
		      .full       (fd_a_full)
		      );

   // Align the Feeder Input for the PE_LATENCY
   generate
      for ( i=0; i<NUM_ROWS; i=i+1 ) begin : FDA_DELAY
	 nBit_mLength_shiftRegister #(VECTOR_WIDTH, i*PE_LATENCY - i ) fda_d
	      ( clk, rst_q, fd_a_rd_en, grid_feeder_a[i], a_in[i]);
      end
   endgenerate 


   // ---------
   // Feeders B
   // ---------
   feeders # (
	      .DATA_WIDTH       (DATA_WIDTH),
	      .VECTOR_LENGTH    (VECTOR_LENGTH), 
	      .IS_A             (0),
	      .NUM_FEEDERS      (NUM_COLS),
         .A_INTERLEAVING   (A_INTERLEAVING),
         .B_INTERLEAVING   (B_INTERLEAVING),
	      .INTERLEAVE_DEPTH (INTERLEAVE_DEPTH), 
	      .ENA_PIPELINE     (ENA_PIPELINE),
         .NUM_BUFFERS      (NUM_BUFFERS)
	      ) FDB (
		     .clk        (clk),
		     .rst        (rst_q),
		     .wr_en      (fd_b_wr_en),
          .a_lead_interleave  (a_lead_interleave_q),
          .b_lead_interleave  (b_lead_interleave_q),
          .feeder_interleave  (feeder_interleave_q_b),
          .feeder_interleave_rnd  (feeder_interleave_rnd_q_b),
		     .wr_data    (fd_b_wr_data),
		     .rd_en      (fd_b_rd_en),
		     .rd_data    (grid_feeder_b),
		     .loaded     (fd_b_loaded),
		     .full       (fd_b_full)
		     );

   // Align the Feeder Input for the PE_LATENCY
   generate
      for ( i=0; i<NUM_COLS; i=i+1 ) begin : FDB_DELAY
	 nBit_mLength_shiftRegister #(VECTOR_WIDTH, (i - 1)*PE_LATENCY - i ) fdb_d
	      ( clk, rst_q, fd_b_rd_en, grid_feeder_b[i], b_in[i]);
      end
   endgenerate 

   // -------------------------------
   // ENA, ACC_FIN/RES Alignment
   // -------------------------------
   generate
      for ( i=0; i<NUM_ROWS; i=i+1 ) begin : CTL_DELAY
	 nBit_mLength_shiftRegister #( 1, (i)*PE_LATENCY) ctl_ena 
	      ( clk, rst_q, 1'b1, ena, ena_in[i]);
	 nBit_mLength_shiftRegister #( 1, (i)*PE_LATENCY) ctl_acc_fin 
	   ( clk, rst_q, 1'b1, acc_fin, acc_fin_in[i]);
	 nBit_mLength_shiftRegister #( 1, (i)*PE_LATENCY) ctl_acc_res
	   ( clk, rst_q, 1'b1, acc_res, acc_res_in[i]);
	 nBit_mLength_shiftRegister #( 1, (i)*PE_LATENCY) ctl_acc_stop
	   ( clk, rst_q, 1'b1, acc_stop, acc_stop_in[i]);
      end
   endgenerate
   // -------
   // PE Grid
   // -------
   gemm_grid_gen # (
			.DATA_WIDTH     (DATA_WIDTH), 
			.ACCU_WIDTH     (ACCU_WIDTH),
			.VECTOR_LENGTH  (VECTOR_LENGTH), 
			.NUM_ROWS       (NUM_ROWS),
			.NUM_COLS       (NUM_COLS),
			.PE_LATENCY     (PE_LATENCY)
			) INST_PE_GRID (
				   .clk            (clk),
				   .rst            (rst_q),
				   .ena            (ena_in),
				   .acc_fin        (acc_fin_in),
				   .acc_res        (acc_res_in),
				   .acc_stop       (acc_stop_in),

				   .drain_rdy      (drain_rdy),
				   .drain_valid    (drain_valid),

				   .a_in_mem       (a_in),
				   .b_in_mem       (b_in),

				   .grid_out       (grid_output)
				   );

   // ------------------
   // Drain Interconnect
   // ------------------
   drain_interconnect # (
			 DATA_WIDTH,
			 ACCU_WIDTH,
			 FRAC_WIDTH,
			 CL_WIDTH,
			 PE_LATENCY,
			 NUM_COLS 
			 ) DRAIN_INTERCONNECT (
					       .clk        (clk),
					       .rst        (rst_q),
					       .ena        (di_ena),
					       .data_in    (grid_output),
					       .data_out   (drain_interconnect_output)
					       );

endmodule

