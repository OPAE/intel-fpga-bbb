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
// Translate CCI-P requests from virtual addresses using VTP.
//

`include "ofs_plat_if.vh"
`include "cci_mpf_if.vh"

module mpf_vtp_translate_ofs_ccip
  #(
    // In normal mode, when FAIL_ON_ERROR is non-zero, all translations must
    // be successful. Failures will block the pipeline to aid in debugging.
    // When FAIL_ON_ERROR is 0, the logic controlling host_mem_if must handle
    // the translation failure. When no translation is found, the channel's
    // error bit is set.
    parameter FAIL_ON_ERROR = 1
    )
   (
    // FIU interface -- IOVA or physical addresses
    ofs_plat_host_ccip_if.to_fiu host_mem_if,
    // AFU interface -- virtual addresses
    ofs_plat_host_ccip_if.to_afu host_mem_va_if,

    // Translation error signal. When error is raised, the valid bit is false
    // in the host_mem_if channel but the remaining data matches the original
    // request.
    output  logic error_c0,
    output  logic error_c1,

    // One port for c0 (reads), the other for c1 (writes)
    mpf_vtp_port_if.to_slave vtp_ports[2]
    );

    import mpf_vtp_pkg::*;

    logic clk;
    assign clk = host_mem_if.clk;
    logic reset_n;
    assign reset_n = host_mem_if.reset_n;


    // Meta-data for translations (tells VTP what to do and returns result)
    t_mpf_vtp_port_wrapper_req vtp_c0_req, vtp_c1_req;
    logic vtp_c0_req_almostFull;
    t_mpf_vtp_port_wrapper_rsp vtp_c0_rsp, vtp_c1_rsp;
    logic vtp_c1_req_almostFull;


    assign host_mem_va_if.clk = host_mem_if.clk;
    assign host_mem_va_if.reset_n = host_mem_if.reset_n;
    assign host_mem_va_if.error = host_mem_if.error;
    assign host_mem_va_if.instance_number = host_mem_if.instance_number;
    always_comb
    begin
        host_mem_va_if.sRx = host_mem_if.sRx;
        host_mem_va_if.sRx.c0TxAlmFull = vtp_c0_req_almostFull;
        host_mem_va_if.sRx.c1TxAlmFull = vtp_c1_req_almostFull;
    end

    always_comb
    begin
        vtp_c0_req = '0;
        vtp_c0_req.addr = host_mem_va_if.sTx.c0.hdr.address;
        // All reads have virtual addresses in this AFU
        vtp_c0_req.addrIsVirtual =
            ofs_plat_ccip_if_funcs_pkg::ccip_c0Tx_isReadReq_noCheckValid(host_mem_va_if.sTx.c0);
        vtp_c0_req.isSpeculative = (FAIL_ON_ERROR == 0);
    end

    // Translate from virtual addresses for reads (c0)
    t_if_ccip_c0_Tx c0_host;

    mpf_vtp_translate_ofs_ccip_c0 c0
       (
        .clk,
        .reset(!reset_n),

        .c0_host,
        .c0_host_almostFull(host_mem_if.sRx.c0TxAlmFull),
        .c0_va(host_mem_va_if.sTx.c0),

        .vtp_req(vtp_c0_req),
        .vtp_req_almostFull(vtp_c0_req_almostFull),
        .vtp_rsp(vtp_c0_rsp),
        .vtp_port(vtp_ports[0])
        );

    always_ff @(posedge clk)
    begin
        host_mem_if.sTx.c0 <= c0_host;

        error_c0 <= vtp_c0_rsp.error;
        if (vtp_c0_rsp.error && ! vtp_c0_rsp.isSpeculative)
        begin
            host_mem_if.sTx.c0.valid <= 1'b0;
        end
    end


    // Meta-data for translation requests (tells VTP what to do)
    always_comb
    begin
        vtp_c1_req = '0;
        vtp_c1_req.addr = host_mem_va_if.sTx.c1.hdr.address;
        // All writes have virtual addresses in this AFU
        vtp_c1_req.addrIsVirtual =
            ofs_plat_ccip_if_funcs_pkg::ccip_c1Tx_isWriteReq_noCheckValid(host_mem_va_if.sTx.c1);
        vtp_c1_req.isSpeculative = (FAIL_ON_ERROR == 0);
    end

    // Translate from virtual addresses for writes (c1)
    t_if_ccip_c1_Tx c1_host;

    mpf_vtp_translate_ofs_ccip_c1 c1
       (
        .clk,
        .reset(!reset_n),

        .c1_host,
        .c1_host_almostFull(host_mem_if.sRx.c1TxAlmFull),
        .c1_va(host_mem_va_if.sTx.c1),

        .vtp_req(vtp_c1_req),
        .vtp_req_almostFull(vtp_c1_req_almostFull),
        .vtp_rsp(vtp_c1_rsp),
        .vtp_port(vtp_ports[1])
        );

    always_ff @(posedge clk)
    begin
        host_mem_if.sTx.c1 <= c1_host;

        error_c1 <= vtp_c1_rsp.error;
        if (vtp_c1_rsp.error && ! vtp_c1_rsp.isSpeculative)
        begin
            host_mem_if.sTx.c1.valid <= 1'b0;
        end
    end


    assign host_mem_if.sTx.c2 = host_mem_va_if.sTx.c2;

endmodule // mpf_vtp_translate_ofs_ccip
