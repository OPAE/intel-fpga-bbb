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

module pe_control #(
  DATA_WIDTH = 16,
  VECTOR_LENGTH = 16,
  MULT_LATENCY = 4,
  INPUT_DELAY = 1,
  TREE_DELAY = 1,
  OUT_DELAY = 1,
  RES_DELAY = 1
)
(
  clk,
  rst,

  // PE Control
  ena,
  acc_fin,
  acc_res,
  acc_stop,

  // Dot Product Control    
  pe_dot_ena,

  // Feedback FIFO Control    
  pe_feed_wrreq,
  pe_feed_rdreq,
  pe_feed_empty,
  pe_feed_usedw,
  pe_feed_full,
  pe_feed_almfull,

  // Drain FIFO Control    
  pe_drain_wrreq,
  pe_drain_rdreq,
  pe_drain_empty,
  pe_drain_usedw,
  pe_drain_full,
  pe_drain_almfull,

  // Drain Control
  pe_acc_fin,
  pe_drain_neig,

  // Systolic Drain Signals
  drain_neig_valid,
  drain_neig_rdy,
  drain_valid,
  drain_rdy
);

  // --------------------------------------------------------------------------

  input wire clk;
  input wire rst;

  // ------------------
  // PE Central Control
  // ------------------    
  input wire ena;
  input wire acc_fin;
  input wire acc_res;
  input wire acc_stop;

  // -------------------
  // Dot Product Control
  // -------------------
  output wire pe_dot_ena;

  // ---------------------
  // Feedback FIFO Control
  // ---------------------
  input wire pe_feed_empty;
  input wire pe_feed_full;
  input wire pe_feed_almfull;
  input wire [9:0] pe_feed_usedw;
  output wire pe_feed_wrreq;
  output wire pe_feed_rdreq;

  // -----------------
  // Drain FIFO Control
  // ------------------
  input wire pe_drain_empty;
  input wire pe_drain_full;
  input wire pe_drain_almfull;
  input wire [9:0] pe_drain_usedw;
  output wire pe_drain_wrreq;
  output reg pe_drain_rdreq;

  // -------------
  // Drain Control
  // -------------
  output wire pe_acc_fin;
  output wire pe_drain_neig;

  // ----------------------
  // Systolic Drain Signals
  // ----------------------
  input  logic drain_neig_valid;   // From Above
  input  logic drain_neig_rdy;     // From Below
  output logic  drain_valid;        // To Below
  output logic  drain_rdy;          // To Above

  // --------------------------------------------------------------------------

  logic prev_acc_fin;
  logic drain_rdreq;
  logic keep_alive;
  logic acc_fin_q;
  logic ena_q;
  logic [$clog2(DOT_DELAY)-1:0] ka_counter;

  // +1 is from pe_acc_reg delay in pe_datapath.
  localparam DOT_DELAY = MULT_LATENCY + INPUT_DELAY + TREE_DELAY*3 + OUT_DELAY + RES_DELAY + 1;

  // ----------------------
  // Accumulate Finish Delay
  // ----------------------
  // This delay aligns the finished signal with the output of the dsp dot chain
  nBit_mLength_shiftRegister #(1, DOT_DELAY) ACC_FIN_Q (clk, rst, 1'b1, acc_fin, acc_fin_q);
  assign pe_acc_fin = acc_fin_q;

  // --------------------------------
  // Dot Product Valid Shift Register
  // --------------------------------
  // Here we are simply delaying ena by the number of pipeline stages in the
  // dot product module to create the valid signal.
  nBit_mLength_shiftRegister #(1, DOT_DELAY) DOT_VALID_Q (clk, rst, 1'b1, ena, ena_q);
  
  // ---------------------
  // Feedback FIFO Control
  // ---------------------
  // When the module is enabled we want to write into the fifo when
  // it is not full and when the output of the dot product is valid
  // We want to read for the fifo after we have processed the
  // first set of vector.
  assign pe_feed_wrreq = ~rst && ena_q && ~acc_fin_q && ~pe_feed_full;
  assign pe_feed_rdreq = ~rst && ena   && acc_res    && ~pe_feed_empty;

  // -------------------
  // Dot Product Control
  // -------------------
  // The dot product module is enabled when there is valid data input.
  assign pe_dot_ena = 1'b1;

  always_ff @(posedge clk) begin
    prev_acc_fin <= acc_fin;

    if (!acc_fin && prev_acc_fin) begin
      keep_alive <= 1'b1;
    end

    if (ka_counter == (DOT_DELAY-2)) begin
      keep_alive <= 1'b0;
      ka_counter <= 0;
    end else if (keep_alive) begin
      ka_counter <= ka_counter + 1;
    end

    if (rst) begin
      prev_acc_fin <= 1'b0;
      keep_alive <= 1'b0;
      ka_counter <= 0;
    end
  end

  // ----------------------
  // Systolic Drain Control
  // ----------------------
  always @(posedge clk) begin
    if(rst) begin
      drain_rdreq   <= 0;
      drain_rdy <= 0;
    end else begin
      // We want to perform a read request when the the previous drain in ready for it.
      // When there is data avaiable and the PE is ready. Perform a rd request
      drain_rdreq   <= drain_neig_rdy;

      // The PE is ready to accept a new input when:
      // - The drain fifo is not full
      // - The accumlated results aren't going into the drain fifo.
      drain_rdy <= ~pe_drain_almfull && ~(prev_acc_fin || keep_alive);

    end
  end
  assign pe_drain_rdreq = drain_rdreq && ~pe_drain_empty;
  assign drain_valid = pe_drain_rdreq;

  // The result will be valid when on rdreq_q
  assign pe_drain_neig = drain_neig_valid;

  // We want to perfor a wr request in two case:
  // - Case one is when we are taking in the accumlate result
  // - Case two is when we are taking in from the systolic neigbhor
  assign pe_drain_wrreq = ~pe_drain_full && ( (ena_q && acc_fin_q) || drain_neig_valid);

endmodule

