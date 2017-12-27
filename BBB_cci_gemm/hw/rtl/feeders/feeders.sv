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


module feeders # (
		  DATA_WIDTH       = 16,
		  VECTOR_LENGTH    = 16,
		  IS_A             = 1,
		  NUM_FEEDERS      = 2,
		  A_INTERLEAVING   = 32,
        B_INTERLEAVING   = 32,
		  INTERLEAVE_DEPTH = 16,
		  ENA_PIPELINE     = 1,
        NUM_BUFFERS      = 2
		  ) (
		     clk,
		     rst,
		     wr_en,
		     a_lead_interleave,
           b_lead_interleave,
           feeder_interleave,
           feeder_interleave_rnd,
		     wr_data,
		     rd_en,
		     rd_data,
		     loaded,
		     full
		     );
   
   // -----------------------------------------------------------------------------
  
   localparam INTERLEAVING = IS_A ? A_INTERLEAVING : B_INTERLEAVING;

   localparam VECTOR_WIDTH = DATA_WIDTH*VECTOR_LENGTH;

   localparam DEPTH_SIZE = INTERLEAVE_DEPTH >> 1; //(VECTOR_LENGTH*INTERLEAVE_DEPTH*DATA_WIDTH) / 512; // This should pretty much always equal 8...
   localparam NUM_OF_WRITE_PER_RAM = DEPTH_SIZE*INTERLEAVING;
   localparam FEEDER_WIDTH = 5; // Support up to 32 Feeders on each side
   
   localparam INTERLEAVING_WIDTH = $clog2(INTERLEAVING);
   localparam DEPTH_SIZE_WIDTH = $clog2(DEPTH_SIZE);

   localparam A_INTERLEAVING_WIDTH = $clog2(A_INTERLEAVING);
   localparam B_INTERLEAVING_WIDTH = $clog2(B_INTERLEAVING);
 
   // Write Calculations
   localparam WRITE_WIDTH = $clog2(NUM_OF_WRITE_PER_RAM);
   
   // Read Cacluation
   localparam TOTAL_READ_CYCLES = INTERLEAVING*INTERLEAVING*INTERLEAVE_DEPTH;
   localparam RAM_TOTAL_READ = $clog2(A_INTERLEAVING*B_INTERLEAVING);
   localparam INTERLEAVE_DEPTH_WIDTH = $clog2(INTERLEAVE_DEPTH);

   // Buffer Width
   localparam BUFFER_WIDTH = $clog2(NUM_BUFFERS-1);

   // Total Memory Needed Per Feeder
   localparam MEM_PER_FEEDER = NUM_OF_WRITE_PER_RAM*NUM_BUFFERS;

   // -----------------------------------------------------------------------------
   
   input wire clk;
   input wire rst;
   input wire wr_en;
   
   input wire [A_INTERLEAVING_WIDTH:0] a_lead_interleave;
   input wire [B_INTERLEAVING_WIDTH:0] b_lead_interleave;
   input wire [INTERLEAVE_DEPTH_WIDTH:0] feeder_interleave;
   input wire [INTERLEAVE_DEPTH_WIDTH:0] feeder_interleave_rnd;
   
   input wire [511:0] wr_data;
   input wire 	      rd_en;
   
   output reg [VECTOR_WIDTH-1:0] rd_data [0:NUM_FEEDERS-1];
   output reg 			 loaded;
   output reg 			 full;
   
   // -----------------------------------------------------------------------------

   // Feeder Wires and Registers
   reg [WRITE_WIDTH-1:0] 	 wr_counter;
   reg [FEEDER_WIDTH-1:0] 	 wr_feed_counter;		
   reg [B_INTERLEAVING_WIDTH:0] 	 rd_counter_s1;
   reg [A_INTERLEAVING_WIDTH:0] 	 rd_counter_s2;
   reg [INTERLEAVE_DEPTH_WIDTH-1:0] rd_inter_counter;		
   reg [BUFFER_WIDTH:0]				    wr_shadow;
   reg [BUFFER_WIDTH:0]				    rd_shadow;

   logic     rd_shadow_rst;
   logic     rd_shadow_inc;
   logic     wr_shadow_rst;
   logic     wr_shadow_inc;
   logic     wr_completed;
   logic     rd_completed;
   logic     rd_fin;
   logic [$clog2(NUM_BUFFERS):0]  num_buffer_avail_early;
   logic [$clog2(NUM_BUFFERS):0]  num_buffer_avail;
   
   wire [WRITE_WIDTH+BUFFER_WIDTH:0]   wr_address;
   wire [$clog2(MEM_PER_FEEDER*2)-1:0] rd_address_part;
   wire [$clog2(MEM_PER_FEEDER*2)-1:0] rd_address;
   wire [FEEDER_WIDTH-1:0]             sel;
   
   // Interleaving Multipications
   logic [A_INTERLEAVING_WIDTH:0]            a_lead_interleave_neg1;
   logic [B_INTERLEAVING_WIDTH:0]           b_lead_interleave_neg1;
   logic [INTERLEAVE_DEPTH_WIDTH:0]       feeder_interleave_neg1;
   logic [DEPTH_SIZE_WIDTH + INTERLEAVING_WIDTH+1:0]    num_writes_rams;
   logic [DEPTH_SIZE_WIDTH + INTERLEAVING_WIDTH+1:0]    num_writes_rams_neg1;
   logic [INTERLEAVE_DEPTH_WIDTH + INTERLEAVING_WIDTH+BUFFER_WIDTH:0] wr_shadow_num_writes_rams;
   logic [INTERLEAVE_DEPTH_WIDTH + INTERLEAVING_WIDTH+1:0] interleaving_factor_x_interleave_depth;
   logic [INTERLEAVE_DEPTH_WIDTH + INTERLEAVING_WIDTH+BUFFER_WIDTH:0] rd_shadow_interleaving_factor_x_interleave_depth;
   logic [INTERLEAVE_DEPTH_WIDTH + INTERLEAVING_WIDTH+1:0] rd_inter_counter_x_interleaving_factor;
  
   logic [INTERLEAVING_WIDTH:0] interleaving_factor;
   logic [B_INTERLEAVING_WIDTH:0] interleaving_factor_s1;
   logic [A_INTERLEAVING_WIDTH:0] interleaving_factor_s2;

   // -----------------------------------------------------------------------------
   // Interleaving Cacluation Logic

   always_ff @(posedge clk) begin
      a_lead_interleave_neg1 <= a_lead_interleave - 1;
      b_lead_interleave_neg1 <= b_lead_interleave - 1;
      feeder_interleave_neg1 <= feeder_interleave - 1;
      num_writes_rams                        <= (feeder_interleave_rnd >> 1) * (* multstyle = "logic" *) interleaving_factor;
      num_writes_rams_neg1 <= num_writes_rams - 1;
      interleaving_factor_x_interleave_depth <= feeder_interleave * (* multstyle = "logic" *) interleaving_factor;
   end
   
   // --------
   // Counters
   // --------
   assign wr_shadow_num_writes_rams                        = wr_shadow * (* multstyle = "logic" *) num_writes_rams;
   assign rd_shadow_interleaving_factor_x_interleave_depth = rd_shadow * (* multstyle = "logic" *) interleaving_factor_x_interleave_depth;
  
   // Read Address Cacluation
   assign wr_address = wr_shadow_num_writes_rams + wr_counter;

   // Feeder Select
   assign sel = wr_feed_counter;

   // This is a little cheaky in that quartus will optimise out the mux
   // and only keep the path that I want
   assign rd_inter_counter_x_interleaving_factor = rd_inter_counter * (* multstyle = "logic" *) interleaving_factor;
   assign rd_address_part = rd_shadow_interleaving_factor_x_interleave_depth + rd_inter_counter_x_interleaving_factor;
   assign rd_address = IS_A ? rd_address_part + rd_counter_s2 : 
		              rd_address_part + rd_counter_s1; 
  

  assign interleaving_factor = IS_A ? a_lead_interleave : b_lead_interleave; 
  assign interleaving_factor_s1 = b_lead_interleave_neg1;  
  assign interleaving_factor_s2 = a_lead_interleave_neg1;
   // -----------------------------------------------------------------------------
   // ---------
   // Write FSM
   // ---------
   
   always @(posedge clk) begin : WRITE_FSM
      if (rst) begin
	 wr_counter <= 0;
	 wr_feed_counter <= 0;
	 wr_shadow <= 0;
      // Decoding this:
      // sel == (NUM_FEEDERS-1) We have moved on the the next row
      // &wr_counter[WRITE_WIDTH-1:0] we have fill up with the first block
      end else if (wr_shadow_rst) begin
    wr_shadow <= 0;
    wr_counter <= 0;
    wr_feed_counter <= 0;
      end else if (wr_shadow_inc) begin
	 wr_shadow <= wr_shadow + 1;
	 wr_counter <= 0;
	 wr_feed_counter <= 0;
      end else if (wr_en && (wr_counter == num_writes_rams_neg1)) begin	 
	 wr_feed_counter <= wr_feed_counter + 1;
	 wr_counter <= 0;
      end else if (wr_en) begin
	 wr_counter <= wr_counter + 1;
      end
   end // block: WRITE_FSM
   assign wr_shadow_inc = wr_en && (sel == (NUM_FEEDERS-1)) && (wr_counter == num_writes_rams_neg1);
   assign wr_shadow_rst = wr_shadow_inc && (wr_shadow == (NUM_BUFFERS-1));
   assign wr_completed  = wr_shadow_inc;
   
   // --------
   // Read FSM
   // --------
   
   always @(posedge clk) begin : READ_FSM_1
      if (rst) begin
	 rd_shadow <= 0;
	 rd_counter_s1 <= 0;
	 rd_counter_s2 <= 0;
	 rd_inter_counter <= 0;
      end else if (rd_shadow_rst) begin
    rd_inter_counter <= 0;
    rd_counter_s1 <= 0;
    rd_counter_s2 <= 0;
    rd_shadow <= 0;
      end else if (rd_shadow_inc) begin
	 rd_inter_counter <= 0;
	 rd_counter_s1 <= 0;
	 rd_counter_s2 <= 0;
	 rd_shadow <= rd_shadow + 1;
      end else if (rd_fin) begin
	 rd_counter_s1 <= rd_counter_s1 + 1;
      end else if (rd_en && (rd_counter_s2 == interleaving_factor_s2) && (rd_counter_s1 == interleaving_factor_s1)) begin
	 rd_counter_s1 <= 0;
	 rd_counter_s2 <= 0;
	 rd_inter_counter <= rd_inter_counter + 1;
      end else if (rd_en && (rd_counter_s1 == interleaving_factor_s1)) begin
	 rd_counter_s1 <= 0;
	 rd_counter_s2 <= rd_counter_s2 + 1;
      end else if (rd_en) begin
	 rd_counter_s1 <= rd_counter_s1 + 1;
      end
   end // block : READ_FSM_1
   assign rd_fin =  (rd_en && (rd_inter_counter == feeder_interleave_neg1) &&
                              (rd_counter_s2 == interleaving_factor_s2) &&
                              (rd_counter_s1 == (interleaving_factor_s1 - 1 - ENA_PIPELINE)));
   assign rd_shadow_inc = rd_en && (rd_counter_s1 == interleaving_factor_s1) && (rd_counter_s2 == interleaving_factor_s2) && (rd_inter_counter == feeder_interleave_neg1);
   assign rd_shadow_rst = rd_shadow_inc && (rd_shadow == (NUM_BUFFERS-1));
   assign rd_completed  = rd_shadow_inc;

   // ----------------------
   // Feeder Loaded and Full
   // ----------------------
   always_ff @(posedge clk) begin
        if(rst) begin
            num_buffer_avail_early <= 0 ;
        end else if( wr_completed && rd_fin ) begin
            num_buffer_avail_early <= num_buffer_avail_early;
        end else if( wr_completed ) begin
            num_buffer_avail_early <= num_buffer_avail_early + 1;
        end else if( rd_fin ) begin
            num_buffer_avail_early <= num_buffer_avail_early - 1;
        end

        if(rst) begin
            num_buffer_avail <= 0 ;
        end else if( wr_completed && rd_completed ) begin
            num_buffer_avail <= num_buffer_avail;
        end else if( wr_completed ) begin
            num_buffer_avail <= num_buffer_avail + 1;
        end else if( rd_completed ) begin
            num_buffer_avail <= num_buffer_avail - 1;
        end
   end

   always @(posedge clk) begin : FEEDER_LOADED
      if (rst) begin
	 loaded <= 1'b0;
      end else if ( num_buffer_avail_early > 0 ) begin
	 loaded <= 1'b1;
      end else if (rd_en) begin
	 loaded <= 1'b0;
      end
   end // block : FEEDER_LOADED
   
   always @(posedge clk) begin : FEEDER_FULL
      if (rst) begin
	 full <= 1'b0;
      end
      // This condition is met when:
      // * there have been 1 more completed reads then writes,
      // * we are working on the second buffer
      // * the first buffer is full
      else if ( (num_buffer_avail) == (NUM_BUFFERS-2) &&
                 wr_en && (sel == (NUM_FEEDERS-1)) && (wr_counter == num_writes_rams_neg1) &&
               !(rd_en && (rd_counter_s1 == interleaving_factor_s1) && (rd_counter_s2 == interleaving_factor_s2) && (rd_inter_counter == feeder_interleave_neg1))) begin
	 full <= 1'b1;
      end else if ((num_buffer_avail) < NUM_BUFFERS - 1) begin
	 full <= 1'b0;
      end
   end // block : FEEDER_FULL
   
   
   wire start_rd_en = rd_en;
   
   //------------------------------------------------------------------------------------------------------
   
   // -----------------------
   // Feeder Module Generator
   // -----------------------
   genvar i;
   
   // --------------------------
   // Reset Timing Optimisations
   // --------------------------
   wire   rst_q [NUM_FEEDERS-1:0];
   generate
      for ( i=0; i<NUM_FEEDERS; i=i+1 ) begin : FD_RST
	 nBit_mLength_shiftRegister # (1, 2) RST_Q_FD (clk, 1'b0, 1'b1, rst, rst_q[i]);
      end
   endgenerate
   
   // ---------------
   // Control Signals
   // ---------------
   reg [WRITE_WIDTH+BUFFER_WIDTH:0] input_wr_addr [NUM_FEEDERS-1:0];
   reg [FEEDER_WIDTH-1:0]           input_sel [NUM_FEEDERS-1:0];
   reg                              input_wr_en [NUM_FEEDERS-1:0];
   wire                             mem_wr_en [NUM_FEEDERS-1:0];
   
   reg                                output_rd_en [NUM_FEEDERS-1:0];
   reg                                output_rd_en_q [NUM_FEEDERS-1:0];
   reg                                output_rd_en_qq [NUM_FEEDERS-1:0];
   reg [$clog2(MEM_PER_FEEDER*2)-1:0] output_rd_addr [NUM_FEEDERS-1:0];
   
   // ------------
   // Data Signals
   // ------------
   reg [511:0] input_data [NUM_FEEDERS-1:0];
   wire [VECTOR_WIDTH-1:0] data_out_mem [NUM_FEEDERS-1:0];
   
   //-------------------------------------------------------------------------------------------------------
   
   generate
      for ( i=0; i<NUM_FEEDERS; i=i+1 ) begin : CTL_SIGS
	 // ---------------------------------
	 // Connecting up the Control Signals
	 // ---------------------------------
	 if ( i==0 ) begin
            always @(posedge clk) begin
               if (rst_q[i]) begin
		  output_rd_en[i] <= 1'b0;
		  output_rd_addr[i] <= 0;
		  input_data[i] <= 0;
		  input_wr_addr[i] <= 0;
		  input_sel[i] <= 0;
		  input_wr_en[i] <= 0;
               end else begin
		  output_rd_en[i] <= start_rd_en;
		  output_rd_addr[i] <= rd_address;
		  input_data[i] <= wr_data;
		  input_wr_addr[i] <= wr_address;
		  input_sel[i] <= sel;
		  input_wr_en[i] <= wr_en;
               end
            end 
	 end else begin
            always @(posedge clk) begin
               if (rst_q[i]) begin
		  output_rd_en[i] <= 1'b0;
		  output_rd_addr[i] <= 0;
		  input_data[i] <= 0;
		  input_wr_addr[i] <= 0;
		  input_sel[i] <= 0;
		  input_wr_en[i] <= 0;
               end else begin
		  output_rd_en[i] <= output_rd_en[i-1];
		  output_rd_addr[i] <= output_rd_addr[i-1];
		  input_data[i] <= input_data[i-1];
		  input_wr_addr[i] <= input_wr_addr[i-1];
		  input_sel[i] <= input_sel[i-1];
		  input_wr_en[i] <= input_wr_en[i-1];
               end
            end
	 end
	 
    // This is 4 cycles and is the 4 cycles that is reflected in the gemm_ctl_gen for sc_load and stall_q
	 always @(posedge clk) begin
            if (rst_q[i]) begin  
               output_rd_en_q[i]   <= 0;
               output_rd_en_qq[i]  <= 0;
            end else begin
               output_rd_en_q[i] <= output_rd_en[i];
               output_rd_en_qq[i] <= output_rd_en_q[i];
            end
            if(rst_q[i]) begin
               rd_data[i] <= 0;
            end else if (output_rd_en_qq[i]) begin
               rd_data[i] <= data_out_mem[i];
            end else begin
               rd_data[i] <= 0;
            end
	 end
	 
	 assign mem_wr_en[i] = (~rst_q[i] && input_wr_en[i] && (input_sel[i] == i)) ? 1 : 0;
	 
	 // -------------------------------
	 // Connecting up the Feeder Memory
	 // -------------------------------
	 feeder_ram_512_256 #(MEM_PER_FEEDER) FEEDER_MEMORY
	   (
            .data       (input_data[i]),
            .wraddress  (input_wr_addr[i]),
            .rdaddress  (output_rd_addr[i]),
            .wren       (mem_wr_en[i]),
            .clock      (clk),
            .rden       (output_rd_en[i]),
            .q          (data_out_mem[i])
	    );
      end // for : CTL_SIGS
      
   endgenerate
   
endmodule // feeders
