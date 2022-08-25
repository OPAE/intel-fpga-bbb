//
// Copyright (c) 2019, Intel Corporation
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

//
// Break counter into a two-cycle operation. The output is delayed one cycle.
// At most half the counter's size can be added to it in one cycle.
//
module counter_multicycle
  #(
    parameter NUM_BITS = 64
    )
   (
    input  logic clk,
    input  logic reset_n,
    input  logic [NUM_BITS-1 : 0] incr_by,
    output logic [NUM_BITS-1 : 0] value
    );

    localparam HALF_BITS = NUM_BITS / 2;

    logic [HALF_BITS - 1 : 0] low_half;
    logic carry;

    always_ff @(posedge clk)
    begin
        // First stage: add incr_by to low half and note a carry
        { carry, low_half } <= low_half + HALF_BITS'(incr_by);

        // Second stage: pass on the low half and add the carry to the upper half
        value[HALF_BITS-1 : 0] <= low_half;
        value[NUM_BITS-1 : HALF_BITS] <= value[NUM_BITS-1 : HALF_BITS] + carry;

        if (!reset_n)
        begin
            value <= 0;
            low_half <= 0;
        end
    end

    // synthesis translate_off
    always_ff @(posedge clk)
    begin
        if (reset_n && |(incr_by[NUM_BITS-1 : HALF_BITS]))
        begin
            $fatal(2, "** ERROR ** %m: The upper half of incr_by is ignored (0x%h)!", incr_by);
        end
    end
    // synthesis translate_on

endmodule // counter_multicycle
