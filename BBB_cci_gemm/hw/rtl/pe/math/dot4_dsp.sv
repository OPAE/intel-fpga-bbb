//
// Copyright (c) 2017, Intel Corporation
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

module dot4_dsp # (
           DATA_WIDTH = 8
           ) (
              clk,
              rst,
              ena,

              a1_in,
              a2_in,
              a3_in,
              a4_in,

              b1_in,
              b2_in,
              b3_in,
              b4_in,

              res_out
              );

   // -----------------------------------------------------

   input   wire                        clk;
   input   wire                        rst;
   input   wire                        ena;

   input   wire [DATA_WIDTH-1:0]       a1_in;
   input   wire [DATA_WIDTH-1:0]       a2_in;
   input   wire [DATA_WIDTH-1:0]       a3_in;
   input   wire [DATA_WIDTH-1:0]       a4_in;

   input   wire [DATA_WIDTH-1:0]       b1_in;
   input   wire [DATA_WIDTH-1:0]       b2_in;
   input   wire [DATA_WIDTH-1:0]       b3_in;
   input   wire [DATA_WIDTH-1:0]       b4_in;

   output  wire [DATA_WIDTH*2-1+2:0]   res_out;

   // -----------------------------------------------------

   wire [63:0]                      chain;
   wire [33:0]                      dot_out;
   wire [DATA_WIDTH-1:0]            a1_w;
   wire [DATA_WIDTH-1:0]            a2_w;
   wire [DATA_WIDTH-1:0]            a3_w;
   wire [DATA_WIDTH-1:0]            a4_w;
   wire [DATA_WIDTH-1:0]            b1_w;
   wire [DATA_WIDTH-1:0]            b2_w;
   wire [DATA_WIDTH-1:0]            b3_w;
   wire [DATA_WIDTH-1:0]            b4_w;

   nBit_mLength_shiftRegister # (DATA_WIDTH, 0) A1 (clk, rst, ena, a1_in, a1_w); 
   nBit_mLength_shiftRegister # (DATA_WIDTH, 1) A2 (clk, rst, ena, a2_in, a2_w); 
   nBit_mLength_shiftRegister # (DATA_WIDTH, 2) A3 (clk, rst, ena, a3_in, a3_w); 
   nBit_mLength_shiftRegister # (DATA_WIDTH, 3) A4 (clk, rst, ena, a4_in, a4_w); 

   nBit_mLength_shiftRegister # (DATA_WIDTH, 0) B1 (clk, rst, ena, b1_in, b1_w); 
   nBit_mLength_shiftRegister # (DATA_WIDTH, 1) B2 (clk, rst, ena, b2_in, b2_w); 
   nBit_mLength_shiftRegister # (DATA_WIDTH, 2) B3 (clk, rst, ena, b3_in, b3_w); 
   nBit_mLength_shiftRegister # (DATA_WIDTH, 3) B4 (clk, rst, ena, b4_in, b4_w); 

   // ----------------------------------------------------------------
   assign res_out = $signed(dot_out[DATA_WIDTH*2-1+2:0]); // SIGN extend

   // -----------------------------------------------------

   // --------------------------------------
   // Pack DSP clk, rst and ena
   // --------------------------------------

   wire [2:0]                    dsp_clk = {1'b0, 1'b0, clk};
   wire [1:0]                    dsp_rst = {rst, rst};
   wire [2:0]                    dsp_ena = {1'b0, 1'b0, ena};

   // ----------------------------------------------------------------

   dot2_int16_systolic_chainout u0 (
                                    .clk        (dsp_clk),
                                    .aclr       (dsp_rst),
                                    .ena        (dsp_ena),
                                    .ax         ({{16-(DATA_WIDTH){a1_w[DATA_WIDTH-1]}},a1_w}),
                                    .ay         ({{16-(DATA_WIDTH){b1_w[DATA_WIDTH-1]}},b1_w}),
                                    .bx         ({{16-(DATA_WIDTH){a2_w[DATA_WIDTH-1]}},a2_w}),
                                    .by         ({{16-(DATA_WIDTH){b2_w[DATA_WIDTH-1]}},b2_w}),
                                    .chainout   (chain),
                                    .resulta    (),
                                    .accumulate ('0),
                                    .loadconst  ('0),
                                    .negate     ('0),
                                    .sub        ('0)
                                    );

   dot2_16_systolic_chainin u1 (
                                .clk        (dsp_clk),
                                .aclr       (dsp_rst),
                                .ena        (dsp_ena),
                                .ax         ({{16-(DATA_WIDTH){a3_w[DATA_WIDTH-1]}},a3_w}),
                                .ay         ({{16-(DATA_WIDTH){b3_w[DATA_WIDTH-1]}},b3_w}),
                                .bx         ({{16-(DATA_WIDTH){a4_w[DATA_WIDTH-1]}},a4_w}),
                                .by         ({{16-(DATA_WIDTH){b4_w[DATA_WIDTH-1]}},b4_w}),
                                .chainin    (chain),
                                .resulta    (dot_out),
                                .accumulate ('0),
                                .loadconst  ('0),
                                .negate     ('0),
                                .sub        ('0)
                                );

endmodule
