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

// The important parameter here is PE_LATENCY. This will determine
// the delay frontier that will propagate throughout grid. Below is 
// a small diagram
/*
*
*                  b_conn[0][0] b_conn[0][1] b_conn[0][2]            b_conn[0][C]
*                       |            |            |                       |
*                       |            |            |                       |
*                       |            |            |                       |
*                     -----        -----        -----                   -----
*                    |     |      |     |      |     |                 |     |
* a_conn [0][0]------| PE0 |------| PE1 |------| PE2 |------ ... ------| PE  |
*                    |     |      |     |      |     |                 |     |
*                     -----        -----        -----                   -----
*                       |            |            |                       |
*                       |            |            |                       |
*                       |            |            |                       |
*                     -----        -----        -----                   -----
*                    |     |      |     |      |     |                 |     |
* a_conn [1][0]------| PE1 |------| PE2 |------| PE3 |------ ... ------| PE  |
*                    |     |      |     |      |     |                 |     |
*                     -----        -----        -----                   -----
*                       |            |            |                       |
*                       |            |            |                       |
*                       |            |            |                       |
*                     -----        -----        -----                   -----
*                    |     |      |     |      |     |                 |     |
* a_conn [2][0]------| PE2 |------| PE3 |------| PE4 |------ ... ------| PE  |
*                    |     |      |     |      |     |                 |     |
*                     -----        -----        -----                   -----
*                       |            |            |                       |
*                       |            |            |                       |
*                       |            |            |                       |
*                       .            .            .                       .
*                       .            .            .                       .
*                       .            .            .                       .
*                       |            |            |                       |
*                       |            |            |                       |
*                       |            |            |                       |
*                     -----        -----        -----                   -----
*                    |     |      |     |      |     |                 |     |
* a_conn [N][0]------| PE  |------| PE  |------| PE  |------ ... ------| PE  |
*                    |     |      |     |      |     |                 |     |
*                     -----        -----        -----                   -----
*/

module gemm_grid_gen #(   
  DATA_WIDTH = 8,
  ACCU_WIDTH = 8,
  VECTOR_LENGTH = 32,
  NUM_ROWS = 10,
  NUM_COLS = 16,
  PE_LATENCY = 1
) (
  clk,
  rst,
  ena,
  acc_fin,
  acc_res,
  acc_stop,

  drain_rdy,
  drain_valid,

  a_in_mem,
  b_in_mem,
  grid_out
);

  // -----------------------------------------------------------

  localparam OUT_WIDTH = 32;

  // -----------------------------------------------------------

  input wire clk;
  input wire rst;
  input wire ena [0:NUM_ROWS-1];
  input wire acc_fin [0:NUM_ROWS-1];
  input wire acc_res [0:NUM_ROWS-1];
  input wire acc_stop [0:NUM_ROWS-1];

  input wire drain_rdy [0:NUM_COLS-1];
  output wire drain_valid [0:NUM_COLS-1];

  input wire [DATA_WIDTH*VECTOR_LENGTH-1:0] a_in_mem [0:NUM_ROWS-1];
  input wire [DATA_WIDTH*VECTOR_LENGTH-1:0] b_in_mem [0:NUM_COLS-1];

  output wire [ACCU_WIDTH-1:0] grid_out [0:NUM_COLS-1];

  // -----------------------------------------------------------

  // -----------------------------------------------
  // These are the interconnect wire between the PEs 
  // -----------------------------------------------

  wire rst_conn      [0:NUM_ROWS-1][0:NUM_COLS];
  wire ena_conn      [0:NUM_ROWS-1][0:NUM_COLS];
  wire acc_fin_conn  [0:NUM_ROWS-1][0:NUM_COLS];
  wire acc_res_conn  [0:NUM_ROWS-1][0:NUM_COLS];
  wire acc_stop_conn  [0:NUM_ROWS-1][0:NUM_COLS];

  wire drain_rdy_conn    [0:NUM_ROWS][0:NUM_COLS-1];
  wire drain_valid_conn  [0:NUM_ROWS][0:NUM_COLS-1];

  wire [DATA_WIDTH*VECTOR_LENGTH-1:0] a_conn [0:NUM_ROWS-1][0:NUM_COLS];
  wire [DATA_WIDTH*VECTOR_LENGTH-1:0] b_conn [0:NUM_ROWS][0:NUM_COLS-1];   

  wire [ACCU_WIDTH-1:0] res_conn [0:NUM_ROWS+1][0:NUM_COLS-1];

  // Generate Variables for grid and connection generation
  genvar i, j;

  // -----------------------------------------------------------

  // Reset Timing Optimisation
  wire rst_q [0:NUM_ROWS-1];
  generate
    for ( i=0; i<NUM_ROWS; i=i+1 ) begin : GRID_RST_Q
      nBit_mLength_shiftRegister # (1, 2) RST_Q (clk, 1'b0, 1'b1, rst, rst_q[i]);
    end
  endgenerate

  // -----------------------------------------------------------

  // -----------------
  // Input Connections
  // -----------------
  // Here we connect the first layers of interconnect with the inputs
  // rst, ena and acc's are only feed accros the rows
  generate
    for ( i=0; i<NUM_ROWS; i=i+1 ) begin : CTL_SIGNAL
      assign rst_conn[i][0]   = rst_q[i];
      assign ena_conn[i][0]   = ena[i];
      assign acc_fin_conn[i][0] = acc_fin[i];
      assign acc_res_conn[i][0] = acc_res[i];
      assign acc_stop_conn[i][0] = acc_stop[i];
    end
  endgenerate

  // Connect up a_in_mem
  generate
    for ( i=0; i<NUM_ROWS; i=i+1 ) begin : A_INPUT
      assign a_conn[i][0] = a_in_mem[i];
    end
  endgenerate

  // Connect up b_in_mem
  generate
    for ( i=0; i<NUM_COLS; i=i+1 ) begin : B_INPUT
      assign b_conn[0][i] = b_in_mem[i];
    end
  endgenerate

  // Drain interconnect
  // The bottom PEs are connected to the drain buffer internconnect
  // The top PEs never take input through the drain output
  generate
    for ( i=0; i<NUM_COLS; i=i+1 ) begin : DRAIN_SIGNAL
      // TThis drain_rdy connects to the drain interconnect
      assign drain_rdy_conn[NUM_ROWS][i] = drain_rdy[i];

      // This is never valid
      assign drain_valid_conn[0][i] = 1'b0;

      assign drain_valid[i] = drain_valid_conn[NUM_ROWS][i];
    end
  endgenerate

  // Connect up grid output
  generate
    for ( i=0; i<NUM_COLS; i=i+1 ) begin : OUT_COL
      assign grid_out[i] = res_conn[NUM_ROWS][i];
    end
  endgenerate

  // -----------------------------------------------------------

  // ---------------
  // Grid Generation
  // ---------------
  generate
    for ( i=0; i<NUM_ROWS; i=i+1 ) begin : PE_ROW
      for ( j=0; j<NUM_COLS; j=j+1 ) begin : PE_COL
        pe # (
          .DATA_WIDTH     (DATA_WIDTH), 
          .ACCU_WIDTH     (ACCU_WIDTH),
          .VECTOR_LENGTH  (VECTOR_LENGTH), 
          .PE_LATENCY     (PE_LATENCY), 
          .ROW_NUM        (i)
        ) PE (
          .clk                (clk),

          // Control Input
          .rst_in             (rst_conn[i][j]),
          .ena_in             (ena_conn[i][j]),
          .acc_fin_in         (acc_fin_conn[i][j]),
          .acc_res_in         (acc_res_conn[i][j]),
          .acc_stop_in        (acc_stop_conn[i][j]),

          // Data Input
          .a_in               (a_conn[i][j]),
          .b_in               (b_conn[i][j]),
          .drain_res_in       (res_conn[i][j]),

          // Propagate Control over COLS
          .rst_out            (rst_conn[i][j+1]),
          .ena_out            (ena_conn[i][j+1]),
          .acc_fin_out        (acc_fin_conn[i][j+1]),
          .acc_res_out        (acc_res_conn[i][j+1]),
          .acc_stop_out       (acc_stop_conn[i][j+1]),

          // Propagate A over COLS 
          .a_out              (a_conn[i][j+1]),

          // Propagate B over ROWS
          .b_out              (b_conn[i+1][j]),

          // Propagate DRAIN Control over ROWS
          .drain_neig_rdy     (drain_rdy_conn[i+1][j]),
          .drain_rdy          (drain_rdy_conn[i][j]),

          .drain_neig_valid   (drain_valid_conn[i][j]),
          .drain_valid        (drain_valid_conn[i+1][j]),

          // Propagate DRAIN over ROWS
          .drain_res_out      (res_conn[i+1][j])
        );
      end
    end
  endgenerate
endmodule
