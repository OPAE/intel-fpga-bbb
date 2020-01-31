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
// Count cycles of "count_clk", with all other ports in the "clk" domain.
//
module clock_counter
  #(
    parameter COUNTER_WIDTH = 16
    )
   (
    input  logic clk,
    input  logic count_clk,
    input  logic sync_reset,
    input  logic enable,
    output logic [COUNTER_WIDTH-1:0] count
    );

    // Convenient names that will be used to declare timing constraints for clock crossing
    (* preserve *) logic [COUNTER_WIDTH-1:0] cntclksync_count;
    (* preserve *) logic cntclksync_reset;
    (* preserve *) logic cntclksync_enable;

    logic [COUNTER_WIDTH-1:0] counter_value;

    always_ff @(posedge count_clk)
    begin
        cntclksync_count <= counter_value;
    end

    always_ff @(posedge clk)
    begin
        count <= cntclksync_count;
    end

    (* preserve *) logic reset_T1;
    (* preserve *) logic enable_T1;

    always_ff @(posedge count_clk)
    begin
        cntclksync_reset <= sync_reset;
        cntclksync_enable <= enable;

        reset_T1 <= cntclksync_reset;
        enable_T1 <= cntclksync_enable;
    end

    counter_multicycle#(.NUM_BITS(COUNTER_WIDTH)) counter
       (
        .clk(count_clk),
        .reset(reset_T1),
        .incr_by(COUNTER_WIDTH'(enable_T1)),
        .value(counter_value)
        );

endmodule
