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
// Map the MPF interface back to an OFS platform CCI-P interface for AFUs
// that connect to the OFS CCI-P interface. This is a mapping toward the
// AFU. For connecting an FIU to MPF use ofs_plat_ccip_if_to_mpf().
//

`include "platform_if.vh"
`include "cci_mpf_if.vh"

`ifdef OFS_PLAT_PARAM_HOST_CHAN_NUM_PORTS

module mpf_if_to_ofs_plat_ccip
  #(
    parameter INSTANCE_NUMBER = 0
    )
   (
    input  logic clk,
    input  logic error,

    cci_mpf_if.to_fiu mpf_ccip,
    ofs_plat_host_ccip_if.to_afu ofs_ccip,

    // c0/c1 MPF extension headers to incorporate along with incoming c0/c1
    // requests from ofs_ccip.
    input  t_cci_mpf_ReqMemHdrExt c0Tx_ext,
    input  t_cci_mpf_ReqMemHdrExt c1Tx_ext,
    input  t_cci_mpf_c1_PartialWriteHdr c1Tx_pwrite
    );

    assign ofs_ccip.clk = clk;
    assign ofs_ccip.reset_n = !mpf_ccip.reset;

    assign ofs_ccip.error = error;
    assign ofs_ccip.instance_number = INSTANCE_NUMBER;

    // Requests
    always_comb
    begin
        mpf_ccip.c0Tx = cci_mpf_cvtC0TxFromBase(ofs_ccip.sTx.c0);
        mpf_ccip.c0Tx.hdr.ext = c0Tx_ext;

        mpf_ccip.c1Tx = cci_mpf_cvtC1TxFromBase(ofs_ccip.sTx.c1);
        mpf_ccip.c1Tx.hdr.ext = c1Tx_ext;
        mpf_ccip.c1Tx.hdr.pwrite = c1Tx_pwrite;

        mpf_ccip.c2Tx = ofs_ccip.sTx.c2;
    end

    // Responses
    always_comb
    begin
        ofs_ccip.sRx.c0 = mpf_ccip.c0Rx;
        ofs_ccip.sRx.c1 = mpf_ccip.c1Rx;

        ofs_ccip.sRx.c0TxAlmFull = mpf_ccip.c0TxAlmFull;
        ofs_ccip.sRx.c1TxAlmFull = mpf_ccip.c1TxAlmFull;
    end

endmodule // ofs_plat_ccip_if_to_mpf

`endif // OFS_PLAT_PARAM_HOST_CHAN_NUM_PORTS
