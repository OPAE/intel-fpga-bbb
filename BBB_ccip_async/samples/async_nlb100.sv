import ccip_if_pkg::*;

module ccip_std_afu
(
  // CCI-P Clocks and Resets
  input           logic             pClk,       
  input           logic             pClkDiv2,   
  input           logic             pClkDiv4,   
  input           logic             uClk_usr,   
  input           logic             uClk_usrDiv2,
  input           logic             pck_cp2af_softReset,
  input           logic [1:0]       pck_cp2af_pwrState, 
  input           logic             pck_cp2af_error,    
  // Interface structures
  input           t_if_ccip_Rx      pck_cp2af_sRx,      
  output          t_if_ccip_Tx      pck_af2cp_sTx       
);

   logic 	  reset_pass;   
   logic 	  afu_clk;   

   t_if_ccip_Tx nlb_tx;
   t_if_ccip_Rx nlb_rx;
   
   assign afu_clk = pClkDiv4 ;
   
   ccip_async_shim ccip_async_shim (
				    .bb_softreset    (pck_cp2af_softReset),
				    .bb_clk          (pClk),
				    .bb_tx           (pck_af2cp_sTx),
				    .bb_rx           (pck_cp2af_sRx),
				    .afu_softreset   (reset_pass),
				    .afu_clk         (afu_clk),
				    .afu_tx          (nlb_tx),
				    .afu_rx          (nlb_rx)
				    );
   

   nlb_lpbk nlb_lpbk (
		      .Clk_400             ( afu_clk ) ,
		      .SoftReset           ( reset_pass ) ,
		      .cp2af_sRxPort       ( nlb_rx ) ,
		      .af2cp_sTxPort       ( nlb_tx ) 
		      );

endmodule // ccip_std_afu
