//
// Copyright (c) 2018, Intel Corporation
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

//
// Semaphore: test whether a value is set in a set. The implemenation here uses
// a CAM, so the number of live entries must be relatively small.
//
// Slots in the CAM are allocated round-robin. Code that uses this module
// must make N_ENTRIES large enough that an entry is cleared before the
// round-robin pointer reaches the entry again. This works well for tasks
// such as tracking values in a FIFO.
//

module cci_mpf_prim_semaphore_cam
  #(
    parameter N_ENTRIES = 0,
    parameter N_VALUE_BITS = 0
    )
   (
    input  logic clk,
    input  logic reset,
    output logic rdy,

    input  logic set_en,
    input  logic [N_VALUE_BITS-1 : 0] set_value,
    input  logic clear_en,
    input  logic [N_VALUE_BITS-1 : 0] clear_value,

    // Test whether a value is present.
    input  logic [N_VALUE_BITS-1 : 0] test_value,
    // Response for the current test_value, this cycle.
    output logic is_set_T0,
    // Response delayed one cycle for timing
    output logic is_set_T1
    );

    typedef logic [$clog2(N_ENTRIES)-1 : 0] t_bucket_idx;
    typedef logic [N_VALUE_BITS-1 : 0] t_value;

    assign rdy = 1'b1;

    logic bucket_valid[0 : N_ENTRIES-1];
    t_value bucket_value[0 : N_ENTRIES-1];

    t_bucket_idx next_idx;

    //
    // Test for a value
    //
    logic [N_ENTRIES-1 : 0] bucket_match, bucket_match_q;

    genvar b;
    generate
        for (b = 0; b < N_ENTRIES; b = b + 1)
        begin : match
            assign bucket_match[b] = bucket_valid[b] && (bucket_value[b] == test_value);

            always_ff @(posedge clk)
            begin
                bucket_match_q[b] <= bucket_match[b];
            end
        end
    endgenerate

    assign is_set_T0 = (|(bucket_match));
    assign is_set_T1 = (|(bucket_match_q));

    //
    // Update buckets
    //
    generate
        for (b = 0; b < N_ENTRIES; b = b + 1)
        begin : upd
            always_ff @(posedge clk)
            begin
                if (clear_en && (bucket_value[b] == clear_value))
                begin
                    bucket_valid[b] <= 1'b0;
                end

                // Buckets are allocated round robin
                if (set_en && (next_idx == t_bucket_idx'(b)))
                begin
                    bucket_valid[b] <= 1'b1;
                    bucket_value[b] <= set_value;
                end

                if (reset)
                begin
                    bucket_valid[b] <= 1'b0;
                end
            end
        end
    endgenerate

    // Use buckets round-robin. The client is expected never to have more than
    // N_ENTRIES in flight and these entries must be retired in order.
    // There is an assertion at the bottom of the module that checks this
    // in simulation.
    always_ff @(posedge clk)
    begin
        if (set_en)
        begin
            next_idx <= (next_idx == t_bucket_idx'(N_ENTRIES-1) ?
                         t_bucket_idx'(0) :
                         next_idx + t_bucket_idx'(1));
        end

        if (reset)
        begin
            next_idx <= t_bucket_idx'(0);
        end
    end
    
    always_ff @(negedge clk)
    begin
        if (reset)
        begin
            // Nothing
        end
        else if (set_en)
        begin
            assert (! bucket_valid[next_idx]) else
                $fatal(2, "cci_mpf_prim_semaphore_cam: Setting entry before previous instance was cleared!");
        end
    end

endmodule // cci_mpf_prim_semaphore_cam
