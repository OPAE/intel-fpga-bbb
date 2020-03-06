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
// Split an MPF interface into separate host memory and MMIO interfaces.
//

`include "platform_if.vh"
`include "cci_mpf_if.vh"

module mpf_if_split_mmio
   (
    input  logic clk,
    cci_mpf_if.to_fiu to_fiu,
    cci_mpf_if.to_afu host_mem,
    cci_mpf_if.to_afu mmio
    );

    assign host_mem.reset = to_fiu.reset;
    assign mmio.reset = to_fiu.reset;

    // Merge request channels
    assign to_fiu.c0Tx = host_mem.c0Tx;
    assign to_fiu.c1Tx = host_mem.c1Tx;
    assign to_fiu.c2Tx = mmio.c2Tx;

    // Split responses by type
    always_comb
    begin
        host_mem.c0Rx = to_fiu.c0Rx;
        host_mem.c0Rx.mmioRdValid = 1'b0;
        host_mem.c0Rx.mmioWrValid = 1'b0;
        host_mem.c1Rx = to_fiu.c1Rx;

        mmio.c0Rx = to_fiu.c0Rx;
        mmio.c0Rx.rspValid = 1'b0;
        mmio.c1Rx = 'x;
        mmio.c1Rx.rspValid = 1'b0;
    end

    assign host_mem.c0TxAlmFull = to_fiu.c0TxAlmFull;
    assign host_mem.c1TxAlmFull = to_fiu.c1TxAlmFull;
    assign mmio.c0TxAlmFull = 1'b1;
    assign mmio.c1TxAlmFull = 1'b1;

endmodule // mpf_if_split_mmio
