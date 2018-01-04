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

module pe_packer #(
  DATA_WIDTH = 32,
  OUT_WIDTH  = 32
) (
  input  logic                  clk          ,
  input  logic                  rst          ,
  input  logic                  ena          ,
  input  logic                  i_drain_wrreq,
  input  logic [DATA_WIDTH-1:0] pe_drain_in  ,
  output logic                  o_drain_wrreq,
  output logic [DATA_WIDTH-1:0] pe_drain_out
);

  localparam PACKING = DATA_WIDTH/OUT_WIDTH;

  logic [$clog2(PACKING):0] pack_counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      pack_counter <= 0;
    end else if (ena && i_drain_wrreq && (pack_counter == (PACKING-1))) begin
      pack_counter <= 0;
    end else if (ena && i_drain_wrreq) begin
      pack_counter <= pack_counter + 1;
    end
  end

  logic [OUT_WIDTH-1:0] trunc_out;

  trunc #(DATA_WIDTH,OUT_WIDTH) RES_TRUNC (pe_drain_in,trunc_out);

  // We are just going to hardcode this to PACKING = 4 for now...
  logic [OUT_WIDTH-1:0] lane_1, lane_2, lane_3;

  always_ff @(posedge clk) begin
    if (rst) begin
      lane_1 <= 0;
      lane_2 <= 0;
      lane_3 <= 0;
    end else if (ena && i_drain_wrreq) begin
      if (pack_counter == 0) begin
        lane_1 <= trunc_out;
      end else if (pack_counter == 1) begin
        lane_2 <= trunc_out;
      end else if (pack_counter == 2) begin
        lane_3 <= trunc_out;
      end
    end
  end

  // Assign the Output
  assign pe_drain_out  = {lane_1, lane_2, lane_3, trunc_out};
  assign o_drain_wrreq = ena && (pack_counter == (PACKING-1));

endmodule // pe_combiner