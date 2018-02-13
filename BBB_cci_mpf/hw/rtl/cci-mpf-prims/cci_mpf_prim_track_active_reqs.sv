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

//
// Count the number of active CCI requests (in lines).
//

`include "cci_mpf_if.vh"


module cci_mpf_prim_track_active_reqs
  #(
    parameter MAX_ACTIVE_LINES = 512,
    parameter MAX_ACTIVE_WRFENCES = 32
    )
   (
    input  logic clk,

    cci_mpf_if.monitor cci_bus,

    output logic c0NotEmpty,
    output logic c1NotEmpty,
    output logic [$clog2(MAX_ACTIVE_LINES) : 0] c0ActiveLines,
    output logic [$clog2(MAX_ACTIVE_LINES) : 0] c1ActiveLines,
    output logic [$clog2(MAX_ACTIVE_WRFENCES)-1 : 0] c1ActiveWrFences
    );

    logic reset;
    assign reset = cci_bus.reset;


    // Leave an extra bit since the counter is at the edge before the
    // initial buffer that limits request counts to MAX_ACTIVE_LINES.
    // The count can thus be higher than MAX_ACTIVE_LINES here.
    typedef logic [$clog2(MAX_ACTIVE_LINES) : 0] t_active_cnt;
    typedef logic [$clog2(MAX_ACTIVE_WRFENCES)-1 : 0] t_active_wrfence_cnt;


    // Increment/decrement count updates for current cycle.  Some counts
    // must be large enough to hold multi-line counts.
    logic [2:0] c0_active_incr;
    logic c0_active_decr;
    logic c1_active_incr;
    logic [2:0] c1_active_decr;

    always_comb
    begin
        if (cci_mpf_c0TxIsReadReq(cci_bus.c0Tx))
        begin
            c0_active_incr = 3'b1 + 3'(cci_bus.c0Tx.hdr.base.cl_len);
        end
        else
        begin
            c0_active_incr = 3'b0;
        end
        c0_active_decr = cci_c0Rx_isReadRsp(cci_bus.c0Rx);

        c1_active_incr = cci_mpf_c1TxIsWriteReq(cci_bus.c1Tx);
        if (cci_c1Rx_isWriteRsp(cci_bus.c1Rx))
        begin
            if (cci_bus.c1Rx.hdr.format)
            begin
                // Packed response for multiple lines
                c1_active_decr = 3'b1 + 3'(cci_bus.c1Rx.hdr.cl_num);
            end
            else
            begin
                c1_active_decr = 3'b1;
            end
        end
        else
        begin
            c1_active_decr = 3'b0;
        end
    end

    //
    // Counter updates are broken down into multiple cycles for timing.  This
    // gives up a bit of accuracy for timing.
    //

    // Stage 1 -- register the change for this cycle
    logic [3:0] c0_active_delta;
    logic [3:0] c1_active_delta;

    always_ff @(posedge clk)
    begin
        c0_active_delta <= 4'(c0_active_incr) - 4'(c0_active_decr);
        c1_active_delta <= 4'(c1_active_incr) - 4'(c1_active_decr);
    end

    // Stage 2 -- counter updates
    always_ff @(posedge clk)
    begin
        c0ActiveLines <= c0ActiveLines + t_active_cnt'(signed'(c0_active_delta));
        c1ActiveLines <= c1ActiveLines + t_active_cnt'(signed'(c1_active_delta));

        if (reset)
        begin
            c0ActiveLines <= t_active_cnt'(0);
            c1ActiveLines <= t_active_cnt'(0);
        end
    end


    // Track write fence activity
    always_ff @(posedge clk)
    begin
        if (cci_mpf_c1TxIsWriteFenceReq(cci_bus.c1Tx) &&
            ! cci_c1Rx_isWriteFenceRsp(cci_bus.c1Rx))
        begin
            // New fence request
            c1ActiveWrFences <= c1ActiveWrFences + t_active_wrfence_cnt'(1);
        end
        else if (! cci_mpf_c1TxIsWriteFenceReq(cci_bus.c1Tx) &&
                 cci_c1Rx_isWriteFenceRsp(cci_bus.c1Rx))
        begin
            // Response
            c1ActiveWrFences <= c1ActiveWrFences - t_active_wrfence_cnt'(1);
        end

        if (reset)
        begin
            c1ActiveWrFences <= t_active_wrfence_cnt'(0);
        end
    end


    // Not empty must be conservative.  Claim not empty due to recent requests
    // in addition to non-zero counter values.
    logic [1:0] c0_recent_req;
    logic [1:0] c1_recent_req;

    assign c0_recent_req[0] = cci_mpf_c0TxIsReadReq(cci_bus.c0Tx);
    assign c1_recent_req[0] = cci_mpf_c1TxIsWriteReq(cci_bus.c1Tx) ||
                              cci_mpf_c1TxIsWriteFenceReq(cci_bus.c1Tx);

    // Track requests through the counter update pipeline cycles
    always_ff @(posedge clk)
    begin
        c0_recent_req[1] <= c0_recent_req[0];
        c1_recent_req[1] <= c1_recent_req[0];
    end

    always_ff @(posedge clk)
    begin
        c0NotEmpty <= (|(c0ActiveLines)) | (|(c0_recent_req));
        c1NotEmpty <= (|(c1ActiveLines)) | (|(c1ActiveWrFences)) | (|(c1_recent_req));

        if (reset)
        begin
            c0NotEmpty <= 1'b0;
            c1NotEmpty <= 1'b0;
        end
    end

endmodule // cci_mpf_prim_count_requests
