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

// This Module will take in the drain result and delay them such that an entire cache line is generated

module drain_interconnect # (
			     DATA_WIDTH = 16,
			     ACCU_WIDTH = 8,
			     FRAC_WIDTH = 13,
			     CL_WIDTH = 512,
			     PE_LATENCY = 1,
			     NUM_COLS = 16 
			     ) (
				clk,
				rst,
				ena,

				data_in,
				data_out
				);
   // ------------------------------------------------------------------

   localparam OUT_WIDTH = 32;

   // ------------------------------------------------------------------

   input wire clk;
   input wire rst;
   input wire ena;

   input wire [ACCU_WIDTH-1:0] data_in [0:NUM_COLS-1];

   output wire [CL_WIDTH-1:0]  data_out;

   // ------------------------------------------------------------------

   // ----------------------------------------
   // Truncation and Rounding Modules <-> ReLU
   // ----------------------------------------
   wire [OUT_WIDTH-1:0]        di_fxd_relu_data [0:NUM_COLS-1]; 
   
   // ----------------------------------------
   // ReLU <-> Delay Matrix
   // ----------------------------------------
   wire [OUT_WIDTH-1:0]        fxd_relu_dm_data [0:NUM_COLS-1]; 

   // ----------------------------
   // Delay Matrix <-> Data Output
   // ----------------------------
   wire [ACCU_WIDTH-1:0]       di_dm_out_data [0:NUM_COLS-1];

   genvar 		       i;

   // --------------
   // Output Connect
   // --------------
   generate
      for ( i=0; i<16; i=i+1 ) begin : OUTPUT_CONNECT
	 if( i<NUM_COLS ) begin
            assign data_out[(i+1)*(32) - 1:i*(32)] = 32'h00000000 | di_dm_out_data[i];
	 end else begin
            assign data_out[(i+1)*(32) - 1:i*(32)] = 32'h00000000;
	 end
      end
   endgenerate

   // ------------------------------------------------------------------

   // --------------------------
   // Reset Timing Optimisations
   // --------------------------
   wire rst_q[0:NUM_COLS-1];
   generate
      for ( i=0; i<NUM_COLS; i=i+1 ) begin : DRAIN_RST_Q
	 nBit_mLength_shiftRegister # ( 1, 1 ) RST_Q (clk, 1'b0, 1'b1, rst, rst_q[i]);
      end
   endgenerate

   // ------------------------------------------------------------------

   // -------------------------------------------
   // Fixed Point Truncation and Rounding Modules
   // -------------------------------------------
   generate
      for ( i=0; i<NUM_COLS; i=i+1 ) begin : FXD_DRAIN
`ifdef DO_FXD // Perform the Rounding and Truncation
	 fxd_rnd_trunc # ( OUT_WIDTH, FRAC_WIDTH ) FXD_MOD
	      (
	       .clk        (clk),
	       .ena        (ena),
	       .in_data    (data_in[i]),
	       .out_data   (di_fxd_relu_data[i])
	       );
`else // By default just pass through the results
	 assign di_fxd_relu_data[i] = data_in[i];
`endif
      end
   endgenerate
   
   // ----
   // ReLU
   // ----
   generate
      for ( i=0; i<NUM_COLS; i=i+1 ) begin : RELU_DRAIN
`ifdef DO_RELU // Perform the ReLU
	 relu # ( OUT_WIDTH ) RELU_MOD
	      (
	       .clk        (clk),
	       .rst        (rst),
	       .in_data    (di_fxd_relu_data[i]),
	       .out_data   (fxd_relu_dm_data[i])
	       );
`else // By default just pass through the results
	 assign fxd_relu_dm_data[i] = di_fxd_relu_data[i];
`endif
      end
   endgenerate
   
   // ------------
   // Delay Matrix
   // ------------
   generate
      for ( i=0; i<NUM_COLS; i=i+1 ) begin : DELAY_MATRIX
	 nBit_mLength_shiftRegister # ( ACCU_WIDTH, (NUM_COLS - i+1)*PE_LATENCY) DELAY
	      (
               .clk        (clk),
               .rst        (rst_q[i]),
               .ena        (ena),
               .data_in    (fxd_relu_dm_data[i]),
               .data_out   (di_dm_out_data[i])
	       );
      end
   endgenerate

endmodule

