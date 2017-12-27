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

module fxd_rnd_trunc #( DATA_WIDTH = 16, FRAC_WIDTH = 13 )
(
  clk,
  ena,
  in_data,
  out_data
);

  // ----------------------------------------------------------------------------

  localparam DATA_WIDTH2 = DATA_WIDTH*2;

  // ----------------------------------------------------------------------------

  input clk;
  input ena;    

  input signed   [DATA_WIDTH2-1:0]   in_data;
  output signed  [DATA_WIDTH-1:0]    out_data;

  // ----------------------------------------------------------------------------

  wire [DATA_WIDTH2-1:0] round_res; 

  // ----------------------------------------------------------------------------

  // -----------
  // No Rounding
  // -----------
  //assign round_res = in_data;

  // -------------------------------------
  // Rounding Mode 0 - Round up to Nearest
  // -------------------------------------
  //rounding_m0 #( DATA_WIDTH2, FRAC_WIDTH ) r0 (in_data, round_res);

  // -------------------------------------
  // Rounding Mode 1 - Stochastic Rounding
  // -------------------------------------
  rounding_m1 #( DATA_WIDTH2, FRAC_WIDTH ) r1 (clk, ena, in_data, round_res); 

  // ------------------------------------
  // Truncation Mode 0 - Optimal Hardware
  // ------------------------------------
  truncation_m0 #( DATA_WIDTH, FRAC_WIDTH ) t0 (round_res, out_data);

endmodule

// --------------------------
// Truncation - Mode 0
// Optimal Hardware Resources
// --------------------------
module truncation_m0 #( DATA_WIDTH = 16, FRAC_WIDTH = 13 )
(
  trunc_in,
  trunc_out
);

  // ----------------------------------------------------------------------------

  localparam DATA_WIDTH2 = DATA_WIDTH*2;
  localparam IL   = DATA_WIDTH - FRAC_WIDTH;
  localparam MSB  = DATA_WIDTH2-1;
  localparam MSB_REMOVE = MSB-1 - IL+1;

  localparam MAX_POS = {1'b0, {(DATA_WIDTH-1){1'b1}}};
  localparam MAX_NEG = {1'b1, {(DATA_WIDTH-1){1'b0}}};

  // ----------------------------------------------------------------------------

  input signed [DATA_WIDTH2-1:0] trunc_in;
  output signed [DATA_WIDTH-1:0] trunc_out;

  // ----------------------------------------------------------------------------

  wire [DATA_WIDTH-1:0] sat_val;
  wire [DATA_WIDTH-1:0] trunc_res;
  wire sgn;
  wire sat; 

  // ----------------------------------------------------------------------------

  // Calculate the basic truncation result
  assign trunc_res = trunc_in[DATA_WIDTH2-1 - (DATA_WIDTH-FRAC_WIDTH) :FRAC_WIDTH];

  // Extract the sign bit
  assign sgn = trunc_in[MSB];

  // Determine the saturation value
  assign sat_val = sgn ? MAX_NEG : MAX_POS;

  // Determine if the truncation removes any information in the MSB
  // For NEG, if any zeros have been removed than information has been lost
  // For POS, if any ones have been removed thand information has been lost
  assign sat = sgn ? ~&trunc_in[MSB-1:MSB_REMOVE] : |trunc_in[MSB-1:MSB_REMOVE]; 

  // Finally, if we need to either return the sat value or the trunc value.
  assign trunc_out = sat ? sat_val : trunc_res;

endmodule

// -------------------
// Rounding - Mode 0 
// Round Up to Nearest
// -------------------
module rounding_m0 #( DATA_WIDTH = 16, FRAC_WIDTH = 13 )
(
  temp_in,
  temp_out
);
  input   signed [DATA_WIDTH-1:0] temp_in;
  output  signed [DATA_WIDTH-1:0] temp_out;

  // ------------------------------------------------------------

  localparam RND_UP  = {1'b1, {(FRAC_WIDTH-1){1'b0}}};

  adder_ov_un # ( DATA_WIDTH ) add0 (temp_in, RND_UP, temp_out);

endmodule

// -------------------
// Rounding - Mode 1 
// Stochastic Rounding
// -------------------
module rounding_m1 #( DATA_WIDTH = 16, FRAC_WIDTH = 13 )
(
  clk,
  ena,
  temp_in,
  temp_out
);
  input clk;
  input ena;

  input   signed [DATA_WIDTH-1:0] temp_in;
  output  signed [DATA_WIDTH-1:0] temp_out;

  // ------------------------------------------------------------

  wire [FRAC_WIDTH-1:0] new_rand;

  // ------------------------------------------------------------

  lfsr # ( FRAC_WIDTH ) lfsr0 (clk, ena, new_rand); 

  adder_ov_un # ( DATA_WIDTH ) add0 (temp_in, new_rand, temp_out);

endmodule

// -------------------------------------------
// Adder with Overflow and Underflow detection
// -------------------------------------------
module adder_ov_un # ( DATA_WIDTH = 16 )
(
  a,
  b,
  c
);

  // ------------------------------------------------------------

  localparam MSB = DATA_WIDTH-1;
  localparam MAX_POS = {1'b0, {(DATA_WIDTH-1){1'b1}}};
  localparam MAX_NEG = {1'b1, {(DATA_WIDTH-1){1'b0}}};

  // ------------------------------------------------------------

  input   signed [DATA_WIDTH-1:0] a;
  input   signed [DATA_WIDTH-1:0] b;
  output  signed [DATA_WIDTH-1:0] c;

  // ------------------------------------------------------------

  logic [DATA_WIDTH-1:0] result;
  logic [DATA_WIDTH-1:0] f_result; 
  logic extra;

  // ------------------------------------------------------------

  assign c = f_result;

  // ------------------------------------------------------------

  always @(*) begin
    {extra, result} = {a[MSB] , a} + {b[MSB], b};
    case ({extra, result[MSB]})
      2'b01    : f_result = MAX_POS; // OVERFLOW
      2'b10    : f_result = MAX_NEG; // UNDERFLOW
      default  : f_result = result;
    endcase
  end

endmodule

// ------------------
// Static 16 bit LFSR
// ------------------
module lfsr # ( DATA_WIDTH = 16 )
(
  clk,
  ena,
  out
);

  // ------------------------------------------------------------
  // Standard 4 Tap LFSR
  // Currently setup in the Fibonacci configuration.

  localparam TAP_0 = 15;
  localparam TAP_1 = 13;
  localparam TAP_2 = 12;
  localparam TAP_3 = 10;

  // ------------------------------------------------------------

  input clk;
  input ena;

  output [DATA_WIDTH-1:0] out;

  // ------------------------------------------------------------

  reg [15:0] lfsr_mem = 16'b10011001010001010;
  logic tap_1_res;
  logic tap_2_res;
  logic tap_3_res;

  // ------------------------------------------------------------

  assign tap_1_res = lfsr_mem[TAP_0] ^ lfsr_mem[TAP_1];
  assign tap_2_res = tap_1_res ^ lfsr_mem[TAP_2];
  assign tap_3_res = tap_2_res ^ lfsr_mem[TAP_3];

  assign out = lfsr_mem[DATA_WIDTH-1:0];

  // ------------------------------------------------------------

  always @(posedge clk) begin
    integer i;
    if (ena) begin
      for (i=0; i<14; i++) begin
        lfsr_mem[i+1] <= lfsr_mem[i];
      end
      lfsr_mem[0] <= tap_3_res;
    end
  end

endmodule
