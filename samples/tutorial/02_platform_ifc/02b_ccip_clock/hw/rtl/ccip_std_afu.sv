// ***************************************************************************
// Copyright (c) 2013-2018, Intel Corporation
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// * Neither the name of Intel Corporation nor the names of its contributors
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
// Module Name :    ccip_std_afu
// Project :        ccip afu top
// Description :    This module instantiates CCI-P compliant AFU

// ***************************************************************************

`include "platform_if.vh"

module ccip_std_afu
   (
    // CCI-P Clocks and Resets
    input  logic        pClk,                 // Primary CCI-P interface clock.
    input  logic        pClkDiv2,             // Aligned, pClk divided by 2.
    input  logic        pClkDiv4,             // Aligned, pClk divided by 4.
    input  logic        uClk_usr,             // User clock domain. Refer to clock programming guide.
    input  logic        uClk_usrDiv2,         // Aligned, user clock divided by 2.
    input  logic        pck_cp2af_softReset,  // CCI-P ACTIVE HIGH Soft Reset

    input  logic [1:0]  pck_cp2af_pwrState,   // CCI-P AFU Power State
    input  logic        pck_cp2af_error,      // CCI-P Protocol Error Detected

    // CCI-P structures
    input  t_if_ccip_Rx pck_cp2af_sRx,        // CCI-P Rx Port
    output t_if_ccip_Tx pck_af2cp_sTx         // CCI-P Tx Port
    );


    // ====================================================================
    // Pick the proper clk and reset, as chosen by the AFU's JSON file
    // ====================================================================

    // The platform may transform the CCI-P clock from pClk to a clock
    // chosen in the AFU's JSON file.
    logic clk;
    assign clk = `PLATFORM_PARAM_CCI_P_CLOCK;

    logic reset;
    assign reset = `PLATFORM_PARAM_CCI_P_RESET;


    // =============================================================
    // Register SR <--> PR signals at interface before consuming it
    // =============================================================

    (* noprune *) logic [1:0]  cp2af_pwrState_T1;
    (* noprune *) logic        cp2af_error_T1;

    // NOTE: All inputs and outputs in PR region (AFU) must be registered
    // Registering Inputs to AFU
    logic        reset_T1;
    t_if_ccip_Rx cp2af_sRx_T1;

    always_ff @(posedge clk)
    begin
        cp2af_sRx_T1 <= pck_cp2af_sRx;
        reset_T1 <= reset;
    end

    afu afu
       (
        .clk(clk),
        .reset(reset_T1),

        .pClk(pClk),
        .pClkDiv2(pClkDiv2),
        .pClkDiv4(pClkDiv4),
        .uClk_usr(uClk_usr),
        .uClk_usrDiv2(uClk_usrDiv2),

        .cp2af_sRx(cp2af_sRx_T1),
        .af2cp_sTx(pck_af2cp_sTx)
        );
endmodule
