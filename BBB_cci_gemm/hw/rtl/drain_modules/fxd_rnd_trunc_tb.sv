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

module fxd_rnd_trunc_tb ();
    
    parameter DATA_WIDTH = 4;
    parameter FRACTIONAL_LENGTH = 2;

    reg clk;
    reg ena;

    reg signed [DATA_WIDTH*2-1:0] in_data;
    reg signed [DATA_WIDTH-1:0] out_data;


    // fxd_truncation DUT
    fxd_rnd_trunc #(DATA_WIDTH, FRACTIONAL_LENGTH) u0 (
        .clk        (clk),
        .ena        (ena),
        .in_data    (in_data),
        .out_data   (out_data)
    );
        
    always
        #5 clk = ~clk;


    initial
    begin
        $display($time, " << Simulation Starting >> ");
        clk = 1'b1;
        ena = 1'b1;
        @(negedge clk);
        in_data     = 8'b00010011;
        @(negedge clk);
        in_data     = 8'b11100101;
        @(negedge clk);
        in_data     = 8'b00000000;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        in_data     = 8'b10000000;
        @(negedge clk);
        $display($time, " << Simulation Finished >> ");
        $finish;
    end

    initial
    begin
        $monitor($time, "\t  in_data:\t%b\n \
                         out_data:\t%b\n", 
                         in_data, 
                         out_data);
    end

endmodule
