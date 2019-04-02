// ***************************************************************************
// Copyright (c) 2013-2016, Intel Corporation
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
`default_nettype none
import ccip_if_pkg::*;
module ccip_std_afu(
  // CCI-P Clocks and Resets
  pClk,                      // 400MHz - CCI-P clock domain. Primary interface clock
  pClkDiv2,                  // 200MHz - CCI-P clock domain.
  pClkDiv4,                  // 100MHz - CCI-P clock domain.
  uClk_usr,                  // User clock domain.  **
  uClk_usrDiv2,              // User clock domain. 
  pck_cp2af_softReset,       // CCI-P ACTIVE HIGH Soft Reset
  pck_cp2af_pwrState,        // CCI-P AFU Power State
  pck_cp2af_error,           // CCI-P Protocol Error Detected

  // Interface structures
  pck_cp2af_sRx,             // CCI-P Rx Port
  pck_af2cp_sTx              // CCI-P Tx Port
);
  input           wire             pClk;                     // 400MHz - CCI-P clock domain. Primary interface clock
  input           wire             pClkDiv2;                 // 200MHz - CCI-P clock domain.
  input           wire             pClkDiv4;                 // 100MHz - CCI-P clock domain.
  input           wire             uClk_usr;                 // User clock domain.
  input           wire             uClk_usrDiv2;             // User clock domain.
  input           wire             pck_cp2af_softReset;      // CCI-P ACTIVE HIGH Soft Reset
  input           wire [1:0]       pck_cp2af_pwrState;       // CCI-P AFU Power State
  input           wire             pck_cp2af_error;          // CCI-P Protocol Error Detected

  // Interface structures
  input           t_if_ccip_Rx     pck_cp2af_sRx;           // CCI-P Rx Port
  output          t_if_ccip_Tx     pck_af2cp_sTx;           // CCI-P Tx Port

    localparam NUM_SUB_AFUS =4 ;
    localparam NUM_PIPE_STAGES =2 ;
    
// =============================================================
// Register SR <--> PR signals at interface before consuming it
//  CCI-P MUX registers Output; so register Inputs to CCIP-MUX 
// =============================================================
    logic        pck_cp2af_softReset_T1;
    t_if_ccip_Rx pck_cp2af_sRx_T1;

    always@(posedge pClk)
    begin
        pck_cp2af_sRx_T1           <= pck_cp2af_sRx;
        pck_cp2af_softReset_T1     <= pck_cp2af_softReset;
    end
   
// =============================================================
// CCI-P MUX Instantiation    
// =============================================================
    t_if_ccip_Rx    pck_afu_RxPort        [NUM_SUB_AFUS-1:0];
    t_if_ccip_Tx    pck_afu_TxPort        [NUM_SUB_AFUS-1:0];
    logic           ccip_mux2pe_reset     [NUM_SUB_AFUS-1:0];
    
    ccip_mux #(NUM_SUB_AFUS, NUM_PIPE_STAGES)
             ccip_mux_U0 (
                        .pClk( pClk ),
                        .pClkDiv2(pClkDiv2),
                        
                        .SoftReset( pck_cp2af_softReset_T1 ) ,  // upstream reset
                        .up_Error(),
                        .up_PwrState(),
                        .up_RxPort( pck_cp2af_sRx_T1 ),         // upstream Rx response port
                        .up_TxPort( pck_af2cp_sTx ),            // upstream Tx request port
            
                        .afu_SoftReset(ccip_mux2pe_reset),      // downstream reset
                        .afu_PwrState(),
                        .afu_Error(),
                        .afu_RxPort(pck_afu_RxPort) ,           // downstream Rx response AFU
                        .afu_TxPort(pck_afu_TxPort)             // downstream Tx request  AFU
                         );

// =============================================================
// PE Instantiation    
// =============================================================
generate    
genvar n;
for(n=0;n<NUM_SUB_AFUS;n++)
begin: gen_nlb

     nlb_lpbk nlb_lpbk(
        .Clk_400             ( pClk ) ,
        .SoftReset           ( ccip_mux2pe_reset[n] ) ,

        .cp2af_sRxPort       ( pck_afu_RxPort[n] ) ,
        .af2cp_sTxPort       ( pck_afu_TxPort[n] ) 
    );
end
endgenerate

endmodule
