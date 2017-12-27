//
// Copyright (c) 2016, Intel Corporation
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
// The requestor accepts the address index from the arbiter, appends that to the source/destination base address and 
// sends out the request to the CCI module. It arbitrates between the read and the write requests, peforms the flow control,
// implements all the CSRs for source address, destination address, status address, wrthru enable, start and stop the test.
//
//
//
`default_nettype none
import ccip_if_pkg::*;
module requestor #(parameter PEND_THRESH=1, ADDR_LMT=20, TXHDR_WIDTH=61, RXHDR_WIDTH=18, DATA_WIDTH=512)
  (

   //      ---------------------------global signals-------------------------------------------------
   clk,        // in    std_logic;  -- Core clock
   rst,      // in    std_logic;  -- Use SPARINGLY only for control. ACTIVE HIGH
   //      ---------------------------CCI IF signals between CCI and requestor  ---------------------
   af2cp_sTxPort,
   cp2af_sRxPort,

   csr_cfg,
   csr_ctl,
   csr_dsm_base,
  
   csr_src_address_a,
   csr_src_address_b,
   csr_dst_address_c,

   ab2re_WrAddr,
   ab2re_WrTID,
   ab2re_WrDin,
   ab2re_WrFence,
   ab2re_WrEn,
   re2ab_WrSent,
   re2ab_WrAlmFull,
   re2ab_WrRspValid,
   re2ab_WrRsp,
   re2ab_WrRspFormat,
   re2ab_WrRspCLnum,

   ab2re_RdAddr,
   ab2re_RdTID,
   ab2re_RdEn,
   re2ab_RdSent,
   re2ab_RdRspValid,
   re2ab_UMsgValid,
   re2ab_RdRsp,
   re2ab_RdData,
   re2ab_RdRspFormat,
   re2ab_RdRspCLnum,

   ab2re_WrSop,
   ab2re_WrLen,
   ab2re_RdSop,
   ab2re_RdLen,

   re2xy_go,
   ab2re_ab_workspace_sel,
   ab2re_stall_count,
   ab2re_TestCmp,
   ab2re_ErrorInfo,
   ab2re_ErrorValid,


   re2xy_multiCL_len
   );
  //--------------------------------------------------------------------------------------------------------------
  // Standard Input Signals
  input  logic            clk; 
  input  logic 		  rst;

  // Input from the ccip_green_interface_reg
  output t_if_ccip_Tx     af2cp_sTxPort;
  input  t_if_ccip_Rx     cp2af_sRxPort;
  
  // AFU CSR Control
  input t_ccip_mmioData  csr_ctl;

  // AFU CSR Configuration
  input t_ccip_mmioData  csr_cfg;
 
  // AFU CSR Address
  input t_ccip_mmioData  csr_dsm_base;
  input t_ccip_mmioData  csr_src_address_a;
  input t_ccip_mmioData  csr_src_address_b;
  input t_ccip_mmioData  csr_dst_address_c;
 
  // Write path to the Core
  input logic [ADDR_LMT-1:0] ab2re_WrAddr;
  input t_ccip_mdata         ab2re_WrTID;
  input t_ccip_clData        ab2re_WrDin;
  input logic 		     ab2re_WrFence;
  input logic 		     ab2re_WrEn;
  output logic 		     re2ab_WrSent; 
  output logic 		     re2ab_WrAlmFull;
  output logic 		     re2ab_WrRspValid;
  output t_ccip_mdata        re2ab_WrRsp;
  output logic 		     re2ab_WrRspFormat;
  output logic [1:0] 	     re2ab_WrRspCLnum;

  input logic          ab2re_WrSop;
  input logic [0:1]         ab2re_WrLen;
  input logic          ab2re_RdSop;
  input logic [0:1]         ab2re_RdLen;
 
  // Read path to the Core
  input logic [ADDR_LMT-1:0] ab2re_RdAddr;
  input t_ccip_mdata         ab2re_RdTID;
  input logic 		     ab2re_RdEn;
  output logic 		     re2ab_RdSent;
  output logic 		     re2ab_RdRspValid;
  output logic 		     re2ab_UMsgValid;
  output t_ccip_mdata        re2ab_RdRsp;
  output t_ccip_clData       re2ab_RdData;
  output logic 		     re2ab_RdRspFormat;
  output logic [1:0] 	     re2ab_RdRspCLnum;
  
  // Control to and from the Core
  (* maxfan=1 *)output    logic re2xy_go;
  input  logic 		     ab2re_ab_workspace_sel;
  input  logic [31:0] 	     ab2re_stall_count;
  input  logic 		     ab2re_TestCmp;
  input  logic [255:0] 	     ab2re_ErrorInfo;
  input  logic 		     ab2re_ErrorValid;
  

  output logic [1:0] 	     re2xy_multiCL_len;
  
  //----------------------------------------------------------------------------------------------------------------------
  //----------------------------------------------------------------------------------
  // Device Status Memory (DSM) Address Map ***** DO NOT MODIFY *****
  // This is a shared memory region where AFU writes and SW reads from. It is used for sharing status.
  // Physical address = value at CSR_AFU_DSM_BASE + Byte offset
  //----------------------------------------------------------------------------------
  //                                     Byte Offset                 Attribute    Width   Comments
  localparam      DSM_STATUS           = 32'h40;                  // RO           512b    test status and error info
  
  //----------------------------------------------------------------------------------------------------------------------

  reg 			     RdHdr_valid;
  reg 			     WrHdr_valid_T1, WrHdr_valid_T2, WrHdr_valid_T3;
  reg [31:0] 		     wrfifo_addr;
  t_ccip_clData           wrfifo_data;
  reg 			     txFifo_RdAck;
  wire 			    txFifo_Dout_v;
  
  t_if_ccip_Rx            cp2af_sRxPort_T1;
  
  reg 			     status_write;
  
  (* dont_merge, maxfan=256 *) reg dsm_status_wren;
  
  integer 		     i;
  reg [1:0] 		     cr_multiCL_len;   
  reg [41:0] 		     ds_stat_address;                        // 040h - test status is written to this address
  
 
  // -----------------------
  // Write FIFO Data Storage
  // -----------------------
  t_ccip_clData              txFifo_WrDin;
  (* maxfan=512 *) wire      txFifo_Full;
  wire 			     txFifo_AlmFull;
  wire 			     txFifo_WrEn     = (ab2re_WrEn| ab2re_WrFence) && ~txFifo_Full;
  wire [15:0] 		     txFifo_WrTID;
  wire [ADDR_LMT-1:0] 	     txFifo_WrAddr;
  wire 			     txFifo_WrFence;
  wire 			     txFifo_WrSop;
  wire [1:0] 		     txFifo_WrLen;
  
  
  t_ccip_clData           WrData_dsm;

  
  reg [14:0] 		     dsm_number;

  // ----------------------------
  // Addres Computation Registers
  // ----------------------------
  logic [41:0] 		     RdAddr;      
  logic 		     RdHdr_valid_q;
  logic [1:0] 		     ab2re_RdLen_q;
  logic 		     ab2re_RdEn_q;
  logic          ab2re_RdSop_q;
  logic [15:0] 		     ab2re_RdTID_q;
  logic [41:0] 		     WrAddr;      
  
  logic [15:0] 		     txFifo_WrTID_q;
  logic 		     txFifo_WrFence_q;
  logic 		     txFifo_WrSop_q;
  logic [1:0] 		     txFifo_WrLen_q;
  logic 		     txFifo_cxEn_q;
  logic [2:0] 		     txFifo_cxQword_q;
  t_ccip_clData  txFifo_WrDin_q;

  logic 		     WrFence_sent;

  // -------
  // Control
  // -------
  logic 		     test_go;        
  logic 		     test_stop;
  logic 		     test_cmplt;

  // -------------
  // Configuration
  // -------------
  logic [3:0] 			     cr_wrthru;
  logic [3:0]			     cr_rdsel;
  logic [3:0] 			     cr_chsel;
  logic  			     cr_wrthru_en;
  
  t_ccip_c1_req           wrreq_type;  
  t_ccip_c0_req           rdreq_type;
  t_ccip_vc               channel_type;
  
  // -------
  // Address
  // -------
  t_ccip_mmioData         cr_dsm_base;                            // a00h, a04h - DSM base address
  t_ccip_mmioData         cr_src_address_a;                         // a20h - source buffer address
  t_ccip_mmioData         cr_src_address_b;                         // a20h - source buffer address
  t_ccip_mmioData         cr_dst_address_c;                         // a24h - destn buffer address

  always_comb begin

    // -------
    // To Core
    // -------
    re2ab_WrAlmFull  = txFifo_AlmFull;
    re2ab_WrSent     = !txFifo_Full;
    re2ab_UMsgValid  = cp2af_sRxPort_T1.c0.rspValid && cp2af_sRxPort_T1.c0.hdr.resp_type==eRSP_UMSG;
    re2ab_WrRspValid = cp2af_sRxPort_T1.c1.rspValid && cp2af_sRxPort_T1.c1.hdr.resp_type==eRSP_WRLINE;;
    re2ab_WrRsp      = cp2af_sRxPort_T1.c1.hdr.mdata[15:0];
    re2ab_WrRspFormat= cp2af_sRxPort_T1.c1.hdr.format;
    re2ab_WrRspCLnum = (cp2af_sRxPort_T1.c1.hdr.format == 1'b0) ? 0 : cp2af_sRxPort_T1.c1.hdr.cl_num[1:0];
    
    re2ab_RdRspValid = cp2af_sRxPort_T1.c0.rspValid && (cp2af_sRxPort_T1.c0.hdr.resp_type==eRSP_RDLINE);
    re2ab_RdRsp      = cp2af_sRxPort_T1.c0.hdr.mdata[15:0];
    re2ab_RdRspCLnum = cp2af_sRxPort_T1.c0.hdr.cl_num[1:0]; 
    re2ab_RdData     = cp2af_sRxPort_T1.c0.data;
    
    RdHdr_valid = re2xy_go
                  && !status_write
                  && !cp2af_sRxPort.c0TxAlmFull    
                  && ab2re_RdEn;
    
    re2ab_RdSent= RdHdr_valid;
    
    txFifo_RdAck = re2xy_go && !cp2af_sRxPort.c1TxAlmFull && txFifo_Dout_v;
    wrreq_type   = txFifo_WrFence_q ? eREQ_WRFENCE
		    : cr_wrthru_en  ? eREQ_WRLINE_M
		    : eREQ_WRLINE_I;
    
    cr_multiCL_len        = 2'b0;          
  end
  
  always_ff @(posedge clk) begin    
   
    // Control & Configuration
    re2xy_multiCL_len    <= cr_multiCL_len;
    ds_stat_address  <= dsm_offset2addr(DSM_STATUS,cr_dsm_base);
    
    // Control
    test_go    <= csr_ctl[0] & ~csr_ctl[1];
    test_stop  <= ~csr_ctl[0] & csr_ctl[1]; 
    test_cmplt <= csr_ctl[2];        
    
    // Configure -- Update Case statements
    cr_wrthru <= csr_cfg[0+:4];
    cr_rdsel  <= csr_cfg[8+:4];
    cr_chsel  <= csr_cfg[16+:4]; 
   
    // Address
    cr_dsm_base      <= csr_dsm_base;
    cr_src_address_a <= csr_src_address_a;
    cr_src_address_b <= csr_src_address_b;
    cr_dst_address_c <= csr_dst_address_c;

    // Read Type Select
    unique case(cr_rdsel)
      4'h0:     rdreq_type <= eREQ_RDLINE_I;
      default:  rdreq_type <= eREQ_RDLINE_S;
    endcase
    
    // Write Type Select
    cr_wrthru_en <= cr_wrthru[0];
    
    // Channel Type Select
    channel_type <= t_ccip_vc'(cr_chsel[1:0]);

    // Write Header Valid when:
    // -- T1 = Read data form the fifo
    // -- T2 = The AFU is processing data
    WrHdr_valid_T1 <= txFifo_RdAck;
    WrHdr_valid_T2 <= WrHdr_valid_T1 & re2xy_go;
    WrHdr_valid_T3 <= WrHdr_valid_T2;

    // --------------------------------------------------------------------------------------------------------------------------

    // ------------
    // ADDR COMPUTE
    // ------------
    // RdAddr computation takes one cycle :- Delay Rd valid generation from req to upstream by 1 clk
    RdAddr               <= ab2re_ab_workspace_sel ? cr_src_address_b + ab2re_RdAddr : cr_src_address_a + ab2re_RdAddr;
    ab2re_RdLen_q        <= ab2re_RdLen;
    ab2re_RdTID_q        <= ab2re_RdTID;
    ab2re_RdEn_q         <= ab2re_RdEn;
    RdHdr_valid_q        <= RdHdr_valid;
    
    // WrAddr computation takes one cycle :- Delay Wr valid popped from FIFO by 1 cycle before fwd'ing to upstream
    WrAddr               <= cr_dst_address_c + txFifo_WrAddr;
    txFifo_WrLen_q       <= txFifo_WrLen;
    txFifo_WrSop_q       <= txFifo_WrSop;
    txFifo_WrFence_q     <= txFifo_WrFence;
    txFifo_WrDin_q       <= txFifo_WrDin; 
    txFifo_WrTID_q       <= txFifo_WrTID;  

    // --------------------------------------------------------------------------------------------------------------------------
    
    
    if( test_go )                                             
      re2xy_go <= 1'b1;
    
    if( status_write )
      re2xy_go <= 1'b0;

    dsm_status_wren <= ab2re_TestCmp | test_stop;
    
    if (test_stop == 0)
      test_stop <= test_cmplt & ((!(|txFifo_WrLen_q) & WrHdr_valid_T3));
    
    WrData_dsm <={ ab2re_ErrorInfo,                             // [511:256] upper half cache line
		   24'h00_0000,                                 // [255:224] test end overhead in # clks
		   24'h00_0000,                                 // [223:192] test start overhead in # clks
		   0,                                  // [191:160] Total number of Writes sent / Total Num CX sent
		   0,                                   // [159:128] Total number of Reads sent
		   24'h00_0000,0, 0,   // [127:64]  number of clks
		   0,                                 // [63:32]   errors detected            
		   ab2re_stall_count[15:0],                     // [31:16]   stall count
		   dsm_number,                                  // [15:1]    unique id for each dsm status write
		   1'h1                                         // [0]       test completion flag
		   };
    
    
    //Tx Path
    //--------------------------------------------------------------------------
    af2cp_sTxPort.c1.hdr        <= 0;
    af2cp_sTxPort.c1.valid      <= 0;
    af2cp_sTxPort.c0.hdr        <= 0;
    af2cp_sTxPort.c0.valid      <= 0;
    
    af2cp_sTxPort.c1.data <= dsm_status_wren ? WrData_dsm : txFifo_WrDin_q; 
    
    // Channel 1
    if ( re2xy_go ) begin
      if( dsm_status_wren & !cp2af_sRxPort_T1.c1TxAlmFull & !WrFence_sent ) begin
	if( WrFence_sent == 0 )  begin
	  af2cp_sTxPort.c1.valid         <= 1'b1;
	end
	WrFence_sent                       <= 1'b1;
	af2cp_sTxPort.c1.hdr.vc_sel        <= channel_type;
	af2cp_sTxPort.c1.hdr.req_type      <= eREQ_WRFENCE;        
	af2cp_sTxPort.c1.hdr.address[41:0] <= '0;
	af2cp_sTxPort.c1.hdr.mdata[15:0]   <= '0;
	af2cp_sTxPort.c1.hdr.sop           <= 1'b0;                 
	af2cp_sTxPort.c1.hdr.cl_len        <= eCL_LEN_1;
      end
      
      if( !cp2af_sRxPort_T1.c1TxAlmFull & WrFence_sent ) begin
	if( status_write == 0 ) begin
	  dsm_number                     <= dsm_number + 1'b1;
	  af2cp_sTxPort.c1.valid         <= 1'b1;
	end
	status_write                       <= 1'b1;
	af2cp_sTxPort.c1.hdr.vc_sel        <= channel_type;
	af2cp_sTxPort.c1.hdr.req_type      <= eREQ_WRLINE_I;
	af2cp_sTxPort.c1.hdr.address[41:0] <= ds_stat_address;
	af2cp_sTxPort.c1.hdr.mdata[15:0]   <= 16'hffff;
	af2cp_sTxPort.c1.hdr.sop           <= 1'b1;                 // DSM Write is single CL write
	af2cp_sTxPort.c1.hdr.cl_len        <= eCL_LEN_1;
      end
      else if( WrHdr_valid_T3 & !test_stop ) begin
	af2cp_sTxPort.c1.hdr.vc_sel        <= channel_type;
	af2cp_sTxPort.c1.hdr.req_type      <= wrreq_type;
	af2cp_sTxPort.c1.hdr.address[41:0] <= WrAddr;
	af2cp_sTxPort.c1.hdr.mdata[15:0]   <= txFifo_WrTID_q;
	af2cp_sTxPort.c1.hdr.sop           <= txFifo_WrSop_q;
	af2cp_sTxPort.c1.hdr.cl_len        <= t_ccip_clLen'(txFifo_WrLen_q);
	af2cp_sTxPort.c1.valid             <= 1'b1;
      end
    end // re2xy_go
    
    // Channel 0
    if( re2xy_go && RdHdr_valid_q ) begin
      af2cp_sTxPort.c0.hdr.vc_sel        <= channel_type;
      af2cp_sTxPort.c0.hdr.req_type      <= rdreq_type;
      af2cp_sTxPort.c0.hdr.address[41:0] <= RdAddr;
      af2cp_sTxPort.c0.hdr.mdata[15:0]   <= ab2re_RdTID_q;
      af2cp_sTxPort.c0.valid             <= 1'b1;
      af2cp_sTxPort.c0.hdr.cl_len        <= t_ccip_clLen'(ab2re_RdLen_q);
    end
    
    //--------------------------------------------------------------------------
    // Rx Response Path
    //--------------------------------------------------------------------------
    cp2af_sRxPort_T1       <= cp2af_sRxPort;
    
    // Reset
    if(rst) begin
      // Control
      test_go    <= '0;
      test_stop  <= '0;
      test_cmplt <= '0;

      // Configure
      cr_wrthru_en <= '0;
      cr_rdsel     <= '0;
      cr_chsel     <= '0; 
      
      // Address
      cr_dsm_base      <= '0;
      cr_src_address_a <= '0;
      cr_src_address_b <= '0;
      cr_dst_address_c <= '0;
      
      re2xy_go                <= 0;
      status_write            <= 0;
      dsm_status_wren         <= 0;     
      dsm_number              <= 0;     
      WrFence_sent            <= 0;  
      
      WrHdr_valid_T1 <= 0;
      WrHdr_valid_T2 <= 0;
      WrHdr_valid_T3 <= 0;
    end
  end
  
  //----------------------------------------------------------------------------------------------------------------------------------------------
  //                                                              Instances
  //----------------------------------------------------------------------------------------------------------------------------------------------
  // Tx Write request fifo. Some tests may have writes dependent on reads, i.e. a read response will generate a write request
  // If the CCI-S write channel is stalled, then the write requests will be queued up in this Tx fifo.
  
  // NOTE: RAM inside the FIFO is currently sized to handle 556 bits (din/dout) and 512 deep 
  // Regenerate the RAM with additional bits if you increase the width/depth of this FIFO
  
  // FIFO Bitmap - 556 bits wide and 512 bits deep
  
  // [551:550]   - ab2re_WrLen
  // [549]       - ab2re_WrSop
  // [548]       - ab2re_WrFence
  // [547:36]    - ab2re_WrDin
  // [35:16]     - ab2re_WrAddr
  // [15:0]      - ab2re_WrTID
  wire [3+1+2+1+1+512+ADDR_LMT+15:0]txFifo_Din= { ab2re_WrLen,
						  ab2re_WrSop,
						  ab2re_WrFence,
						  ab2re_WrDin,
						  ab2re_WrAddr, 
						  ab2re_WrTID
						  };
  wire [3+1+2+1+1+512+ADDR_LMT+15:0] txFifo_Dout;
  assign                  txFifo_WrLen    = txFifo_Dout[2+1+1+DATA_WIDTH+ADDR_LMT+16-1: 1+1+1+DATA_WIDTH+ADDR_LMT+16-1];
  assign                  txFifo_WrSop    = txFifo_Dout[1+1+DATA_WIDTH+ADDR_LMT+16-1];
  assign                  txFifo_WrFence  = txFifo_Dout[1+DATA_WIDTH+ADDR_LMT+16-1];
  assign                  txFifo_WrDin    = txFifo_Dout[ADDR_LMT+16+:DATA_WIDTH];
  assign                  txFifo_WrAddr   = txFifo_Dout[16+:ADDR_LMT];
  assign                  txFifo_WrTID    = txFifo_Dout[15:0];
  
  wire [9-1:0] 			     txFifo_count;                
  nlb_C1Tx_fifo #(.DATA_WIDTH  (3+1+2+1+1+DATA_WIDTH+ADDR_LMT+16),
		  .CTL_WIDTH   (0),
		  .DEPTH_BASE2 (9),         
		  .GRAM_MODE   (3),
		  .FULL_THRESH (2**9-8)     
		  )nlb_writeTx_fifo
    (                                          //--------------------- Input  ------------------
					       .Resetb            (~rst),
					       .Clk               (clk),    
					       .fifo_din          (txFifo_Din),          
					       .fifo_ctlin        (),
					       .fifo_wen          (txFifo_WrEn),      
					       .fifo_rdack        (txFifo_RdAck),
					       //--------------------- Output  ------------------
					       .T2_fifo_dout      (txFifo_Dout),        
					       .T0_fifo_ctlout    (),
					       .T0_fifo_dout_v    (txFifo_Dout_v),
					       .T0_fifo_empty     (),
					       .T0_fifo_full      (txFifo_Full),
					       .T0_fifo_count     (txFifo_count),
					       .T0_fifo_almFull   (txFifo_AlmFull),
					       .T0_fifo_underflow (),
					       .T0_fifo_overflow  ()
					       ); 
  
  // Function: Returns physical address for a DSM register
  function automatic [41:0] dsm_offset2addr;
    input [9:0] 		     offset_b;
    input [63:0] 		     base_b;
    begin
      dsm_offset2addr = base_b[47:6] + offset_b[9:6];
    end
  endfunction
  
  //----------------------------------------------------------------
  // For signal tap
  //----------------------------------------------------------------
  /*

   (* noprune *) reg [3:0]                 DEBUG_nlb_error;
   (* noprune *) reg [31:0]                DEBUG_Num_Reads;
   (* noprune *) reg [31:0]                DEBUG_Num_Writes;
   (* noprune *) reg                       DEBUG_inact_timeout;
   (* noprune *) reg [9:0]                 DEBUG_C0TxHdrID;
   (* noprune *) reg [31:0]                DEBUG_C0TxHdrAddr;
   (* noprune *) reg [9:0]                 DEBUG_C1TxHdrID;
   (* noprune *) reg [31:0]                DEBUG_C1TxHdrAddr;
   (* noprune *) reg [16:0]                DEBUG_C1TxData;
   (* noprune *) reg [9:0]                 DEBUG_C0RxHdrID;
   (* noprune *) reg [8:0]                 DEBUG_C0RxData;
   (* noprune *) reg [9:0]                 DEBUG_C1RxHdrID;
   (* noprune *) reg                       DEBUG_C0TxValid;
   (* noprune *) reg                       DEBUG_C0RxValid;
   (* noprune *) reg                       DEBUG_C1TxValid;
   (* noprune *) reg                       DEBUG_C1RxValid;
   (* noprune *) reg                       DEBUG_txFifo_Dout_v;
   (* noprune *) reg                       DEBUG_txFifo_RdAck;
   (* noprune *) reg                       DEBUG_txFifo_WrEn;
   (* noprune *) reg                       DEBUG_txFifo_Full;
   (* noprune *) reg [4:0]                 DEBUG_txFifo_Din, DEBUG_txFifo_Dout;
   (* noprune *) reg [15:0]                DEBUG_txFifo_WrCount, DEBUG_txFifo_RdCount;
   (* noprune *) reg [9-1:0]               DEBUG_txFifo_count;                            // TODO: was PEND_THRESH (7)


   always @(posedge Clk_400)
   begin
   DEBUG_nlb_error[3:0]    <= ErrorVector[3:0];
   DEBUG_Num_Reads         <= Num_Reads;
   DEBUG_Num_Writes        <= Num_Writes;
   DEBUG_inact_timeout     <= inact_timeout;
   DEBUG_C0TxHdrID         <= af2cp_sTxPort.c0.hdr.mdata[9:0];
   DEBUG_C0TxHdrAddr       <= af2cp_sTxPort.c0.hdr.address[31:0];
   DEBUG_C1TxHdrID         <= af2cp_sTxPort.c1.hdr.mdata[9:0];
   DEBUG_C1TxHdrAddr       <= af2cp_sTxPort.c1.hdr.address[31:0];
   DEBUG_C1TxData          <= af2cp_sTxPort.c1.data[16:0];
   DEBUG_C0RxHdrID         <= cp2af_sRxPort.c0.hdr.mdata[9:0];
   DEBUG_C0RxData          <= cp2af_sRxPort.c0.data[8:0];
   DEBUG_C1RxHdrID         <= cp2af_sRxPort.c1.hdr.mdata[9:0];
   DEBUG_C0TxValid         <= af2cp_sTxPort.c0.valid;
   DEBUG_C1TxValid         <= af2cp_sTxPort.c1.valid;
   DEBUG_C0RxValid         <= cp2af_sRxPort.c0.rspValid;
   DEBUG_C1RxValid         <= cp2af_sRxPort.c1.rspValid;

   DEBUG_txFifo_Dout_v     <= txFifo_Dout_v;
   DEBUG_txFifo_RdAck      <= txFifo_RdAck;
   DEBUG_txFifo_WrEn       <= txFifo_WrEn;
   DEBUG_txFifo_Full       <= txFifo_Full;
   DEBUG_txFifo_Din        <= txFifo_Din[4:0];
   DEBUG_txFifo_Dout       <= txFifo_Dout[4:0];
   DEBUG_txFifo_count      <= txFifo_count;
   if(txFifo_WrEn)
   DEBUG_txFifo_WrCount <= DEBUG_txFifo_WrCount+1'b1;
   if(txFifo_RdAck)
   DEBUG_txFifo_RdCount <= DEBUG_txFifo_RdCount+1'b1;

   if(!test_Reset_n)
   begin
   DEBUG_txFifo_WrCount<= 0;
   DEBUG_txFifo_RdCount<= 0;
            end
        end
   */

endmodule
