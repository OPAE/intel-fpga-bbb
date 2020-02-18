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
// Interface of a single VTP translation port. The VTP service typically
// provides a vector of these ports.
//
// The port allows enough state to flow through that all requests can flow
// through it, even if no translation is required. This typically makes
// it easier to structure ports that have fences or ports where some
// addresses require translation and some don't.
//

`include "mpf_vtp.vh"

interface mpf_vtp_port_if;

    logic reqEn;
    t_mpf_vtp_lookup_req req;
    // Is the incoming request a virtual address? If not, no translation is
    // performed and the original address is returned in the response.
    logic reqAddrIsVirtual;
    // Is the request ordered (e.g. a write fence)? If so, the channel logic
    // will wait for all earlier requests to drain from the VTP pipelines.
    // It is illegal to set both reqAddrIsVirtual and reqIsOrdered.
    logic reqIsOrdered;
    logic almostFullToAFU;

    // Responses are present when rspValid is set.
    logic rspValid;
    t_mpf_vtp_lookup_rsp rsp;
    logic almostFullFromFIU;

    modport to_master
       (
        input  reqEn,
        input  req,
        input  reqAddrIsVirtual,
        input  reqIsOrdered,
        output almostFullToAFU,

        output rspValid,
        output rsp,
        input  almostFullFromFIU
        );

    modport to_slave
       (
        output reqEn,
        output req,
        output reqAddrIsVirtual,
        output reqIsOrdered,
        input  almostFullToAFU,

        input  rspValid,
        input  rsp,
        output almostFullFromFIU
        );

endinterface // mpf_vtp_port_if
