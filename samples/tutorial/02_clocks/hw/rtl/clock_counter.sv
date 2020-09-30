//
// Copyright (c) 2020, Intel Corporation
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
// Count a clock's cycles, with the counter exported in a separate domain.
//

module clock_counter
  #(
    parameter COUNTER_WIDTH = 16
    )
   (
    input  logic clk,

    input  logic count_clk,
    output logic [COUNTER_WIDTH-1:0] count,
    input  logic [COUNTER_WIDTH-1:0] max_value,
    output logic max_value_reached,
    input  logic sync_reset_n,
    input  logic enable
    );

    // Convenient names that will be used to declare timing constraints for clock crossing
    (* preserve *) logic [COUNTER_WIDTH-1:0] cntsync_count;
    (* preserve *) logic [COUNTER_WIDTH-1:0] cntsync_max_value;
    (* preserve *) logic cntsync_max_value_reached;
    (* preserve *) logic cntsync_reset_n;
    (* preserve *) logic cntsync_enable;

    logic [COUNTER_WIDTH-1:0] count_impl_out;
    logic count_impl_max_value_reached;

    always_ff @(posedge count_clk)
    begin
        cntsync_count <= count_impl_out;
        cntsync_max_value_reached <= count_impl_max_value_reached;
    end

    always_ff @(posedge clk)
    begin
        count <= cntsync_count;
        max_value_reached <= cntsync_max_value_reached;
    end

    (* preserve *) logic reset_n_T1;
    (* preserve *) logic enable_T1;

    always_ff @(posedge count_clk)
    begin
        cntsync_max_value <= max_value;
        cntsync_reset_n <= sync_reset_n;
        cntsync_enable <= enable;

        reset_n_T1 <= cntsync_reset_n;
        enable_T1 <= cntsync_enable;
    end

    // Instantiate the real counter.
    clock_counter_impl
      #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
        )
      counter
       (
        .count_clk(count_clk),
        .count(count_impl_out),
        .max_value(cntsync_max_value),
        .max_value_reached(count_impl_max_value_reached),
        .sync_reset_n(reset_n_T1),
        .enable(enable_T1)
        );
endmodule


module clock_counter_impl
  #(
    parameter COUNTER_WIDTH = 16
    )
   (
    input  logic count_clk,
    output logic [COUNTER_WIDTH-1:0] count,
    input  logic [COUNTER_WIDTH-1:0] max_value,
    output logic max_value_reached,
    input  logic sync_reset_n,
    input  logic enable
    );

    logic sync_enable;
    logic max_value_is_set;

    always_ff @(posedge count_clk)
    begin
        if (!sync_reset_n)
        begin
            count <= 1'b0;
            max_value_reached <= 1'b0;
        end
        else
        begin
            max_value_reached <= max_value_reached ||
                                 (max_value_is_set && (count == max_value));

            if (sync_enable & ~max_value_reached)
            begin
                count <= count + 1;
            end
        end

        sync_enable <= enable;
        max_value_is_set <= (|(max_value));
    end
endmodule
