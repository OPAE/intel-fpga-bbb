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
// Module Name :	  ccip_std_afu
// Project :        ccip afu top (work in progress)
// Description :    This module instantiates CCI-P compliant AFU

// ***************************************************************************
import ccip_if_pkg::*;
module ccip_intf_regs # (parameter NUM_PIPE_STAGES=0)
(
  // CCI-P Clocks and Resets
  input           logic             pClk,                 // 400MHz - CCI-P clock domain. Primary interface clock

  // Interface structures
  // Upstream
  input           logic [1:0]       pck_up_pwrState,   // CCI-P AFU Power State
  input           logic             pck_up_error,      // CCI-P Protocol Error Detected
  input           t_if_ccip_Rx      pck_up_sRx,        // CCI-P Rx Port
  output          t_if_ccip_Tx      pck_up_sTx,   // CCI-P Tx Port

  // Downstream
  output          logic [1:0]       pck_dn_pwrState,    // CCI-P AFU Power State
  output          logic             pck_dn_error,       // CCI-P Protocol Error Detected
  output          t_if_ccip_Rx      pck_dn_sRx,  // CCI-P Rx Port
  input           t_if_ccip_Tx      pck_dn_sTx      // CCI-P Tx Port
);

logic [1:0]       pck_dn_pwrState_Tn   [NUM_PIPE_STAGES+1];
logic             pck_dn_error_Tn      [NUM_PIPE_STAGES+1];
t_if_ccip_Rx      pck_dn_sRx_Tn        [NUM_PIPE_STAGES+1];
t_if_ccip_Tx      pck_up_sTx_Tn        [NUM_PIPE_STAGES+1];

always_comb
begin
	if (0==NUM_PIPE_STAGES)
	begin
		pck_dn_pwrState       = pck_up_pwrState;
		pck_dn_error          = pck_up_error;
		pck_dn_sRx            = pck_up_sRx;
		pck_up_sTx            = pck_dn_sTx;
	end
	else
	begin
		pck_dn_pwrState       = pck_dn_pwrState_Tn[NUM_PIPE_STAGES];
		pck_dn_error          = pck_dn_error_Tn   [NUM_PIPE_STAGES];
		pck_dn_sRx            = pck_dn_sRx_Tn [NUM_PIPE_STAGES];
		pck_up_sTx            = pck_up_sTx_Tn [NUM_PIPE_STAGES];
	end
end

generate if (NUM_PIPE_STAGES>0)
    always_ff @ (posedge pClk)
    begin
        for(int i=1; i<=(NUM_PIPE_STAGES); i=i+1)
        begin
		if (1==i)
		begin	
			pck_dn_pwrState_Tn[i] <= pck_up_pwrState;
            pck_dn_error_Tn[i]    <= pck_up_error;
            pck_dn_sRx_Tn[i]      <= pck_up_sRx;
            pck_up_sTx_Tn[i]      <= pck_dn_sTx;
        end
		else		
		begin
			pck_dn_pwrState_Tn[i] <= pck_dn_pwrState_Tn[i-1];
            pck_dn_error_Tn[i]    <= pck_dn_error_Tn[i-1];
            pck_dn_sRx_Tn[i]      <= pck_dn_sRx_Tn[i-1];
            pck_up_sTx_Tn[i]      <= pck_up_sTx_Tn[i-1];
        end
		end
    end
endgenerate

endmodule
