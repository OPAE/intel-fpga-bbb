//
// Copyright (c) 2022, Intel Corporation
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

`include "ofs_plat_if.vh"

//
// Streaming data engine. This could be a module that manipulates the data
// stream in some way that is useful to the algorithm. It sits here in
// the data path as an example of connecting the blocks.
//
// Data arrives in request order.
//

module data_stream_engine
   (
    ofs_plat_axi_stream_if.to_source data_stream_in,
    ofs_plat_axi_stream_if.to_sink   data_stream_out
    );

    wire clk = data_stream_in.clk;
    wire reset_n = data_stream_in.reset_n;

    //
    // Invert the payload as a proxy for doing something useful. Both the
    // incoming and outgoing streams have standard ready/enable signals.
    // This function may have any latency as ready/enable are honored.
    //

    assign data_stream_in.tready = data_stream_out.tready;
    assign data_stream_out.tvalid = data_stream_in.tvalid;
    always_comb
    begin
        data_stream_out.t = data_stream_in.t;
        data_stream_out.t.data = ~data_stream_in.t.data;
    end

endmodule // data_stream_engine
