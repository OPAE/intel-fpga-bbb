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

module nBit_mLength_shiftRegister #(
  DATA_WIDTH = 16,
  DELAY_LENGTH = 1,
  MAX_FANOUT = 256
) (
  clk,
  rst,
  ena,
  data_in,
  data_out
);
  // -------------------------------------------------------------------

  input   wire                        clk;
  input   wire                        rst;
  input   wire                        ena;
  input   wire    [DATA_WIDTH-1:0]    data_in;

  output  wire    [DATA_WIDTH-1:0]    data_out;

  // -------------------------------------------------------------------

  wire [DATA_WIDTH-1:0] shift_mem [0:DELAY_LENGTH+1];

  // -------------------------------------------------------------------

  generate
    if(DELAY_LENGTH <= 0) begin
      assign data_out = data_in;
    end else begin
      assign data_out     = shift_mem[DELAY_LENGTH];
      assign shift_mem[0] = data_in;
    end
  endgenerate

  // -------------------------------------------------------------------

  genvar i;
  generate
    for (i=0; i<DELAY_LENGTH; i=i+1) begin
      shiftReg # ( DATA_WIDTH, MAX_FANOUT ) PIPELINE_REG (
        .clk        (clk),
        .rst        (rst),
        .ena        (ena),
        .in_data    (shift_mem[i]),
        .out_data   (shift_mem[i+1])
      );
    end
  endgenerate


endmodule	

