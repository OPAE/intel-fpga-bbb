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
// Map OFS platform CCI-P interface the MPF interface.
//

`include "platform_if.vh"
`include "cci_mpf_if.vh"

`ifdef OFS_PLAT_PARAM_HOST_CHAN_NUM_PORTS

module ofs_plat_ccip_if_to_mpf
  #(
    parameter REGISTER_INPUTS = 1,
    parameter REGISTER_OUTPUTS = 1,
    // Number of stages to add when registering inputs or outputs
    parameter N_REG_STAGES = 1
    )
   (
    ofs_plat_host_ccip_if.to_fiu ofs_ccip,
    cci_mpf_if.to_afu mpf_ccip
    );

    logic clk;
    assign clk = ofs_ccip.clk;
    logic reset;
    assign reset = ofs_ccip.reset;

    assign mpf_ccip.reset = ofs_ccip.reset;

    genvar s;
    generate
        if (REGISTER_OUTPUTS)
        begin : reg_out
            (* preserve *) t_if_ccip_Tx reg_af2cp_sTx[N_REG_STAGES];

            // Tx to register stages
            always_ff @(posedge clk)
            begin
                reg_af2cp_sTx[0].c0 <= cci_mpf_cvtC0TxToBase(mpf_ccip.c0Tx);
                reg_af2cp_sTx[0].c1 <= cci_mpf_cvtC1TxToBase(mpf_ccip.c1Tx);
                reg_af2cp_sTx[0].c2 <= mpf_ccip.c2Tx;
            end

            // Intermediate stages
            for (s = 0; s < N_REG_STAGES - 1; s = s + 1)
            begin
                always_ff @(posedge clk)
                begin
                    reg_af2cp_sTx[s+1] <= reg_af2cp_sTx[s];
                end
            end

            always_comb
            begin
                ofs_ccip.sTx = reg_af2cp_sTx[N_REG_STAGES - 1];
            end
        end
        else
        begin : wire_out
            always_comb
            begin
                ofs_ccip.sTx.c0 = cci_mpf_cvtC0TxToBase(mpf_ccip.c0Tx);
                ofs_ccip.sTx.c1 = cci_mpf_cvtC1TxToBase(mpf_ccip.c1Tx);
                ofs_ccip.sTx.c2 = mpf_ccip.c2Tx;
            end
        end
    endgenerate

    //
    // Buffer incoming read responses for timing
    //
    generate
        if (REGISTER_INPUTS)
        begin : reg_in
            (* preserve *) t_if_ccip_Rx reg_cp2af_sRx[N_REG_STAGES];

            always_ff @(posedge clk)
            begin
                reg_cp2af_sRx[N_REG_STAGES - 1] <= ofs_ccip.sRx;
            end

            // Intermediate stages
            for (s = N_REG_STAGES - 1; s > 0; s = s - 1)
            begin
                always_ff @(posedge clk)
                begin
                    reg_cp2af_sRx[s-1] <= reg_cp2af_sRx[s];
                end
            end

            always_comb
            begin
                mpf_ccip.c0Rx = reg_cp2af_sRx[0].c0;
                mpf_ccip.c1Rx = reg_cp2af_sRx[0].c1;

                mpf_ccip.c0TxAlmFull = reg_cp2af_sRx[0].c0TxAlmFull;
                mpf_ccip.c1TxAlmFull = reg_cp2af_sRx[0].c1TxAlmFull;
            end
        end
        else
        begin : wire_in
            always_comb
            begin
                mpf_ccip.c0Rx = ofs_ccip.sRx.c0;
                mpf_ccip.c1Rx = ofs_ccip.sRx.c1;

                mpf_ccip.c0TxAlmFull = ofs_ccip.sRx.c0TxAlmFull;
                mpf_ccip.c1TxAlmFull = ofs_ccip.sRx.c1TxAlmFull;
            end
        end
    endgenerate

endmodule // ofs_plat_ccip_if_to_mpf

`endif // OFS_PLAT_PARAM_HOST_CHAN_NUM_PORTS
