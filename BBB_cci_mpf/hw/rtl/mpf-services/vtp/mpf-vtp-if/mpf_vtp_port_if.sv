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
// Interface of a single VTP translation port. The VTP services typically
// provides a vector of these ports.
//

`include "mpf_vtp.vh"

interface mpf_vtp_port_if
  #(
    parameter N_CTX_BITS = 1024
    );

    logic almostFullToAFU;
    // A single TX channel.
    logic cTxValid;
    logic [N_CTX_BITS-1 : 0] cTx;
    logic cTxAddrIsVirtual;
    // Is the request a speculative translation?
    logic cTxReqIsSpeculative;
    // Is the request ordered (e.g. a write fence)? If so, the channel logic
    // will wait for all earlier requests to drain from the VTP pipelines.
    // It is illegal to set both cTxAddrIsVirtual and cTxReqIsOrdered.
    logic cTxReqIsOrdered;

    // Outbound TX channel. Requests are present when cTxValid_out is set.
    logic cTxValid_out;
    // Unchanged from the value passed to cTx above.
    logic [N_CTX_BITS-1 : 0] cTx_out;
    // Failed translation. This error may be raised only if cTxReqIsSpeculative
    // was set.
    logic cTxError_out;
    // A translated physical address if cTxAddr is virtual.
    t_tlb_4kb_pa_page_idx cTxPhysAddr_out;
    logic cTxAddrIsBigPage_out;
    logic almostFullFromFIU;

    modport to_master
       (
        output almostFullToAFU,
        input  cTxValid,
        input  cTx,
        input  cTxAddrIsVirtual,
        input  cTxReqIsSpeculative,
        input  cTxReqIsOrdered,

        output cTxValid_out,
        output cTx_out,
        output cTxError_out,
        output cTxPhysAddr_out,
        output cTxAddrIsBigPage_out,
        input  almostFullFromFIU
        );

    modport to_slave
       (
        input  almostFullToAFU,
        output cTxValid,
        output cTx,
        output cTxAddrIsVirtual,
        output cTxReqIsSpeculative,
        output cTxReqIsOrdered,

        input  cTxValid_out,
        input  cTx_out,
        input  cTxError_out,
        input  cTxPhysAddr_out,
        input  cTxAddrIsBigPage_out,
        output almostFullFromFIU
        );

endinterface // mpf_vtp_port_if
