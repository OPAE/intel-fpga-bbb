// ***************************************************************************
// Copyright (c) 2013-2017, Intel Corporation
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
// ***************************************************************************

`include "fpga_defines.vh"

//
// platform_if.vh defines many required components, including both top-level
// SystemVerilog interfaces and the platform/AFU configuration parameters
// required to match the interfaces offered by the platform to the needs
// of the AFU.
//
// Most preprocessor variables used in this file come from this.
//
`include "platform_if.vh"

`ifdef INCLUDE_ETHERNET
import hssi_eth_pkg::*;
`endif 
parameter CCIP_TXPORT_WIDTH = $bits(t_if_ccip_Tx);  // TODO: Move this to ccip_if_pkg
parameter CCIP_RXPORT_WIDTH = $bits(t_if_ccip_Rx);  // TODO: Move this to ccip_if_pkg

module green_bs
(
    // CCI-P Interface
    input   logic                         Clk_400,             // Core clock. CCI interface is synchronous to this clock.
    input   logic                         Clk_200,             // Core clock. CCI interface is synchronous to this clock.
    input   logic                         Clk_100,             // Core clock. CCI interface is synchronous to this clock.
    input   logic                         uClk_usr,             
    input   logic                         uClk_usrDiv2,         
    input   logic                         SoftReset,           // CCI interface reset. The Accelerator IP must use this Reset. ACTIVE HIGH
    input   logic [1:0]                   pck_cp2af_pwrState,
    input   logic                         pck_cp2af_error,
    output  logic [CCIP_TXPORT_WIDTH-1:0] bus_ccip_Tx,         // CCI-P TX port
    input   logic [CCIP_RXPORT_WIDTH-1:0] bus_ccip_Rx,         // CCI-P RX port
   
`ifdef INCLUDE_DDR4
    input  logic                          DDR4a_USERCLK,
    input  logic                          DDR4a_waitrequest,
    input  logic [511:0]                  DDR4a_readdata,
    input  logic                          DDR4a_readdatavalid,
    output logic [6:0]                    DDR4a_burstcount,
    output logic [511:0]                  DDR4a_writedata,
    output logic [26:0]                   DDR4a_address,
    output logic                          DDR4a_write,
    output logic                          DDR4a_read,
    output logic [63:0]                   DDR4a_byteenable,
    input  logic                          DDR4b_USERCLK,
    input  logic                          DDR4b_waitrequest,
    input  logic [511:0]                  DDR4b_readdata,
    input  logic                          DDR4b_readdatavalid,
    output logic [6:0]                    DDR4b_burstcount,
    output logic [511:0]                  DDR4b_writedata,
    output logic [26:0]                   DDR4b_address,
    output logic                          DDR4b_write,
    output logic                          DDR4b_read,
    output logic [63:0]                   DDR4b_byteenable,
`endif

`ifdef INCLUDE_ETHERNET
    hssi_if.afu              hssi,
`endif // INCLUDE_ETHERNET
`ifdef INCLUDE_GPIO
     output  [4:0] g2b_GPIO_a         ,// GPIO port A
     output  [4:0] g2b_GPIO_b         ,// GPIO port B
     output        g2b_I2C0_scl       ,// I2C0 clock
     output        g2b_I2C0_sda       ,// I2C0 data
     output        g2b_I2C0_rstn      ,// I2C0 rstn
     output        g2b_I2C1_scl       ,// I2C1 clock
     output        g2b_I2C1_sda       ,// I2C1 data
     output        g2b_I2C1_rstn      ,// I2C1 rstn

     input   [4:0] b2g_GPIO_a         ,// GPIO port A
     input   [4:0] b2g_GPIO_b         ,// GPIO port B
     input         b2g_I2C0_scl       ,// I2C0 clock
     input         b2g_I2C0_sda       ,// I2C0 data
     input         b2g_I2C0_rstn      ,// I2C0 rstn
     input         b2g_I2C1_scl       ,// I2C1 clock
     input         b2g_I2C1_sda       ,// I2C1 data
     input         b2g_I2C1_rstn      ,// I2C1 rstn

     output  [4:0] oen_GPIO_a         ,// GPIO port A
     output  [4:0] oen_GPIO_b         ,// GPIO port B
     output        oen_I2C0_scl       ,// I2C0 clock
     output        oen_I2C0_sda       ,// I2C0 data
     output        oen_I2C0_rstn      ,// I2C0 rstn
     output        oen_I2C1_scl       ,// I2C1 clock
     output        oen_I2C1_sda       ,// I2C1 data
     output        oen_I2C1_rstn,      // I2C1 rstn
`endif
   // JTAG Interface for PR region debug
   input   logic            sr2pr_tms,
   input   logic            sr2pr_tdi,             
   output  logic            pr2sr_tdo,             
   input   logic            sr2pr_tck,
   input   logic            sr2pr_tckena
);


// ===========================================
// CCI-P type conversion
// ===========================================

   logic pck_cp2af_softReset;
   t_if_ccip_Tx pck_af2cp_sTx;
   t_if_ccip_Rx pck_cp2af_sRx;

   assign pck_cp2af_softReset = SoftReset;
   assign bus_ccip_Tx = pck_af2cp_sTx;
   assign pck_cp2af_sRx = bus_ccip_Rx;


// ===========================================
// AFU - Remote Debug JTAG IP instantiation
// ===========================================

`ifdef SIM_MODE
   assign pr2sr_tdo = 0;
`else
  `ifdef INCLUDE_REMOTE_STP
    wire loopback;
    sld_virtual_jtag 
    inst_sld_virtual_jtag (
          .tdi (loopback), 
          .tdo (loopback)
    );
    
    // Q17.0 modified SCJIO
    // with tck_ena   
    altera_sld_host_endpoint#(
        .NEGEDGE_TDO_LATCH(0),
        .USE_TCK_ENA(1)
    ) scjio
    (
        .tck         (sr2pr_tck),         //  jtag.tck
        .tck_ena     (sr2pr_tckena),      //      .tck_ena
        .tms         (sr2pr_tms),         //      .tms
        .tdi         (sr2pr_tdi),         //      .tdi
        .tdo         (pr2sr_tdo),         //      .tdo
                     
        .vir_tdi     (sr2pr_tdi),         //      .vir_tdi
        .select_this (1'b1)               //      .select_this
    );
      
  `else
    assign pr2sr_tdo = 0;
  `endif // INCLUDE_REMOTE_STP
`endif // SIM_MODE

// ===========================================
// CDC and MUXes for HSSI PR MGMT bus access 
// ===========================================

`ifdef ETH_E2E

wire [31:0] eth_ctrl_addr;  
wire [31:0] eth_wr_data  ;  

reg  [15:0] prmgmt_cmd_mux ;
reg  [15:0] prmgmt_addr_mux;   
reg  [31:0] prmgmt_din_mux ;   

always_comb
begin
    // RD/WR request from AFU CSR 
    if (eth_ctrl_addr[17] | eth_ctrl_addr[16])
    begin
        prmgmt_cmd_mux  = eth_ctrl_addr[31:16];
        prmgmt_addr_mux = eth_ctrl_addr[15: 0];
        prmgmt_din_mux  = eth_wr_data;
    end
    else
    begin
        prmgmt_cmd_mux  = prmgmt_cmd;
        prmgmt_addr_mux = prmgmt_addr;
        prmgmt_din_mux  = prmgmt_din;
    end
end

`endif


// ===========================================
// Tie off local memory when not used
// ===========================================

`ifndef PLATFORM_PROVIDES_LOCAL_MEMORY
    always_comb
    begin
        DDR4a_burstcount = 0;
        DDR4a_writedata = 0;
        DDR4a_address = 0;
        DDR4a_write = 0;
        DDR4a_read = 0;
        DDR4a_byteenable = 0;

        DDR4b_burstcount = 0;
        DDR4b_writedata = 0;
        DDR4b_address = 0;
        DDR4b_write = 0;
        DDR4b_read = 0;
        DDR4b_byteenable = 0;
    end
`endif


// ===========================================
// Transform local memory for better timing
// ===========================================

`ifdef PLATFORM_PROVIDES_LOCAL_MEMORY
      logic DDR4a_softReset;
      logic DDR4b_softReset;

      logic           pipeln_DDR4a_waitrequest;
      logic [511:0]   pipeln_DDR4a_readdata;
      logic           pipeln_DDR4a_readdatavalid;
      logic [6:0]     pipeln_DDR4a_burstcount;
      logic [511:0]   pipeln_DDR4a_writedata;
      logic [26:0]    pipeln_DDR4a_address;
      logic           pipeln_DDR4a_write;
      logic           pipeln_DDR4a_read;
      logic [63:0]    pipeln_DDR4a_byteenable;

      logic           pipeln_DDR4b_waitrequest;
      logic [511:0]   pipeln_DDR4b_readdata;
      logic           pipeln_DDR4b_readdatavalid;
      logic [6:0]     pipeln_DDR4b_burstcount;
      logic [511:0]   pipeln_DDR4b_writedata;
      logic [26:0]    pipeln_DDR4b_address;
      logic           pipeln_DDR4b_write;
      logic           pipeln_DDR4b_read;
      logic [63:0]    pipeln_DDR4b_byteenable;

      // Reset synchronizer
      green_bs_resync #(
               .SYNC_CHAIN_LENGTH(2),
               .WIDTH(1),                
               .INIT_VALUE(1)
      ) ddr4a_reset_sync (
               .clk(DDR4a_USERCLK),
               .reset(SoftReset),
               .d(1'b0),
               .q(DDR4a_softReset)
      );

      green_bs_resync #(
               .SYNC_CHAIN_LENGTH(2),
               .WIDTH(1),                
               .INIT_VALUE(1)
      ) ddr4b_reset_sync (
               .clk(DDR4b_USERCLK),
               .reset(SoftReset),
               .d(1'b0),
               .q(DDR4b_softReset)
      );

      ddr_avmm_bridge #(
              .DATA_WIDTH        (512),
              .SYMBOL_WIDTH      (8),
              .ADDR_WIDTH    (27),
              .BURSTCOUNT_WIDTH  (7)
      ) ddr4a_avmm_bridge (
              .clk              (DDR4a_USERCLK),
              .reset            (DDR4a_softReset),
              .s0_waitrequest   (pipeln_DDR4a_waitrequest),
              .s0_readdata      (pipeln_DDR4a_readdata),
              .s0_readdatavalid (pipeln_DDR4a_readdatavalid),
              .s0_burstcount    (pipeln_DDR4a_burstcount),
              .s0_writedata     (pipeln_DDR4a_writedata),
              .s0_address       (pipeln_DDR4a_address),
              .s0_write         (pipeln_DDR4a_write),
              .s0_read          (pipeln_DDR4a_read),
              .s0_byteenable    (pipeln_DDR4a_byteenable),
              .m0_waitrequest   (DDR4a_waitrequest),
              .m0_readdata      (DDR4a_readdata),
              .m0_readdatavalid (DDR4a_readdatavalid),
              .m0_burstcount    (DDR4a_burstcount),
              .m0_writedata     (DDR4a_writedata),
              .m0_address       (DDR4a_address),
              .m0_write         (DDR4a_write),
              .m0_read          (DDR4a_read),
              .m0_byteenable    (DDR4a_byteenable)
      );

      ddr_avmm_bridge #(
              .DATA_WIDTH        (512),
              .SYMBOL_WIDTH      (8),
              .ADDR_WIDTH    (27),
              .BURSTCOUNT_WIDTH  (7)
      ) ddr4b_avmm_bridge (
              .clk              (DDR4b_USERCLK),
              .reset            (DDR4b_softReset),
              .s0_waitrequest   (pipeln_DDR4b_waitrequest),
              .s0_readdata      (pipeln_DDR4b_readdata),
              .s0_readdatavalid (pipeln_DDR4b_readdatavalid),
              .s0_burstcount    (pipeln_DDR4b_burstcount),
              .s0_writedata     (pipeln_DDR4b_writedata),
              .s0_address       (pipeln_DDR4b_address),
              .s0_write         (pipeln_DDR4b_write),
              .s0_read          (pipeln_DDR4b_read),
              .s0_byteenable    (pipeln_DDR4b_byteenable),
              .m0_waitrequest   (DDR4b_waitrequest),
              .m0_readdata      (DDR4b_readdata),
              .m0_readdatavalid (DDR4b_readdatavalid),
              .m0_burstcount    (DDR4b_burstcount),
              .m0_writedata     (DDR4b_writedata),
              .m0_address       (DDR4b_address),
              .m0_write         (DDR4b_write),
              .m0_read          (DDR4b_read),
              .m0_byteenable    (DDR4b_byteenable)
      );
`endif


// ===========================================
// Avalon memory wires to avalon_mem_if
// ===========================================

`ifdef AFU_TOP_REQUIRES_LOCAL_MEMORY_AVALON_MM
    logic ddr4_avmm_clk[2];
    logic ddr4_avmm_reset[2];

    // Interfaces for all DDR memory banks
    avalon_mem_if#(.ENABLE_LOG(1)) ddr4[2](ddr4_avmm_clk, ddr4_avmm_reset);
    defparam ddr4[0].BANK_NUMBER = 0;
    defparam ddr4[1].BANK_NUMBER = 1;

    always_comb
    begin
        ddr4_avmm_clk[0] = DDR4a_USERCLK;
        ddr4_avmm_reset[0] = DDR4a_softReset;

        ddr4_avmm_clk[1] = DDR4b_USERCLK;
        ddr4_avmm_reset[1] = DDR4b_softReset;

        ddr4[0].waitrequest = pipeln_DDR4a_waitrequest;
        ddr4[0].readdata = pipeln_DDR4a_readdata;
        ddr4[0].readdatavalid = pipeln_DDR4a_readdatavalid;

        pipeln_DDR4a_writedata = ddr4[0].writedata;
        pipeln_DDR4a_address = ddr4[0].address;
        pipeln_DDR4a_write = ddr4[0].write;
        pipeln_DDR4a_read = ddr4[0].read;
        pipeln_DDR4a_byteenable = ddr4[0].byteenable;
        pipeln_DDR4a_burstcount = ddr4[0].burstcount;

        ddr4[1].waitrequest = pipeln_DDR4b_waitrequest;
        ddr4[1].readdata = pipeln_DDR4b_readdata;
        ddr4[1].readdatavalid = pipeln_DDR4b_readdatavalid;

        pipeln_DDR4b_writedata = ddr4[1].writedata;
        pipeln_DDR4b_address = ddr4[1].address;
        pipeln_DDR4b_write = ddr4[1].write;
        pipeln_DDR4b_read = ddr4[1].read;
        pipeln_DDR4b_byteenable = ddr4[1].byteenable;
        pipeln_DDR4b_burstcount = ddr4[1].burstcount;
    end
`endif


// ===========================================
// CCIP_STD_AFU Instantiation 
// ===========================================

`ifdef ETH_E2E
    ccip_e2e_e40_csr inst_ccip_e2e_e40_csr (
    .pClk               (Clk_400        ),  // Interface Clock 400MHz
    .pClkDiv2           (Clk_200        ),  // Interface Clock 200MHz
    .pClkDiv4           (Clk_100        ),  // Interface Clock 100MHz
    .uClk_usr           (uClk_usr       ),
    .uClk_usrDiv2       (uClk_usrDiv2   ),
    .pck_cp2af_softReset(pck_cp2af_softReset),
    .pck_cp2af_pwrState (pck_cp2af_pwrState),
    .pck_cp2af_error    (pck_cp2af_error),                   
    .pck_af2cp_sTx      (pck_af2cp_sTx  ),  // CCI-P Tx Port
    .pck_cp2af_sRx      (pck_cp2af_sRx  ),  // CCI-P Rx Port
    .eth_ctrl_addr      (eth_ctrl_addr  ),
    .eth_wr_data        (eth_wr_data    ),
    .eth_rd_data        (prmgmt_dout    )
    );
`else
   //
   // The platform database defines the name of the module instantiated by
   // green_bs().  For some platforms, the next module instantiated is
   // another shim in between green_bs() and the user AFU code.  The
   // shim may provide automated clock crossing and buffering, controlled
   // by the AFU's JSON file.  For other platforms, PLATFORM_SHIM_MODULE_NAME
   // is the AFU's top-level module name.
   //
   `PLATFORM_SHIM_MODULE_NAME
`ifdef AFU_TOP_REQUIRES_LOCAL_MEMORY_AVALON_MM
    #(
      .NUM_LOCAL_MEM_BANKS(`AFU_TOP_REQUIRES_LOCAL_MEMORY_AVALON_MM)
     )
`endif
    `PLATFORM_SHIM_MODULE_NAME
     (
      .pClk                   (Clk_400),    // 16ui link/protocol clock domain. Interface Clock
      .pClkDiv2               (Clk_200),    // 32ui link/protocol clock domain. Synchronous to interface clock
      .pClkDiv4               (Clk_100),    // 64ui link/protocol clock domain. Synchronous to interface clock
      .uClk_usr               (uClk_usr),
      .uClk_usrDiv2           (uClk_usrDiv2),  
      .pck_cp2af_softReset    (pck_cp2af_softReset),
`ifdef AFU_TOP_REQUIRES_POWER_2BIT
      .pck_cp2af_pwrState     (pck_cp2af_pwrState),
`endif
`ifdef AFU_TOP_REQUIRES_ERROR_1BIT
      .pck_cp2af_error        (pck_cp2af_error),                   
`endif

      //
      // Local memory
      //   The platform offers two interfaces to the same
      //   Avalon memory: a SystemVerilog interface and a
      //   legacy, wire-based interface.  At most one
      //   will be active in a given compilation, based
      //   on AFU platform requests.
      //
`ifdef AFU_TOP_REQUIRES_LOCAL_MEMORY_AVALON_MM
      .local_mem              (ddr4),
`endif
`ifdef AFU_TOP_REQUIRES_LOCAL_MEMORY_AVALON_MM_LEGACY_WIRES_2BANK
      .DDR4a_USERCLK          (DDR4a_USERCLK),     
      .DDR4a_waitrequest      (pipeln_DDR4a_waitrequest),
      .DDR4a_readdata         (pipeln_DDR4a_readdata),
      .DDR4a_readdatavalid    (pipeln_DDR4a_readdatavalid),
      .DDR4a_burstcount       (pipeln_DDR4a_burstcount),
      .DDR4a_writedata        (pipeln_DDR4a_writedata),
      .DDR4a_address          (pipeln_DDR4a_address),
      .DDR4a_write            (pipeln_DDR4a_write),
      .DDR4a_read             (pipeln_DDR4a_read),
      .DDR4a_byteenable       (pipeln_DDR4a_byteenable),
      .DDR4b_USERCLK          (DDR4b_USERCLK),     
      .DDR4b_waitrequest      (pipeln_DDR4b_waitrequest),
      .DDR4b_readdata         (pipeln_DDR4b_readdata),
      .DDR4b_readdatavalid    (pipeln_DDR4b_readdatavalid),
      .DDR4b_burstcount       (pipeln_DDR4b_burstcount),
      .DDR4b_writedata        (pipeln_DDR4b_writedata),
      .DDR4b_address          (pipeln_DDR4b_address),
      .DDR4b_byteenable       (pipeln_DDR4b_byteenable),
      .DDR4b_write            (pipeln_DDR4b_write),
      .DDR4b_read             (pipeln_DDR4b_read),
`endif // AFU_TOP_REQUIRES_LOCAL_MEMORY_AVALON_MM_LEGACY_WIRES_2BANK

      .pck_af2cp_sTx          (pck_af2cp_sTx),         // CCI-P Tx Port
      .pck_cp2af_sRx          (pck_cp2af_sRx)          // CCI-P Rx Port
);
`endif

// ======================================================
// Workaround: To preserve uClk_usr routing to  PR region
// ======================================================

(* noprune *) logic uClk_usr_q1, uClk_usr_q2;
(* noprune *) logic uClk_usrDiv2_q1, uClk_usrDiv2_q2;
(* noprune *) logic pClkDiv4_q1, pClkDiv4_q2;
(* noprune *) logic pClkDiv2_q1, pClkDiv2_q2;

always  @(posedge uClk_usr)
begin
  uClk_usr_q1     <= uClk_usr_q2;
  uClk_usr_q2     <= !uClk_usr_q1;
end

always  @(posedge uClk_usrDiv2)
begin
  uClk_usrDiv2_q1 <= uClk_usrDiv2_q2;
  uClk_usrDiv2_q2 <= !uClk_usrDiv2_q1;
end

always  @(posedge Clk_100)
begin
  pClkDiv4_q1     <= pClkDiv4_q2;
  pClkDiv4_q2     <= !pClkDiv4_q1;
end

always  @(posedge Clk_200)
begin
  pClkDiv2_q1     <= pClkDiv2_q2;
  pClkDiv2_q2     <= !pClkDiv2_q1;
end

////////////////////////////////////////////////////////
// Partial reconfig zone
////////////////////////////////////////////////////////
`ifdef INCLUDE_ETHERNET

    `ifdef ETH_E2E_E40
    eth_e2e_e40 prz0 (
    `else
        `ifdef HSSI_E10_CH8
        green_hssi_8x10 prz0 (
        `else
            `ifdef HSSI_E10
            green_hssi_e10 prz0 (
            `else
                `ifdef HSSI_E40
                green_hssi_e40 prz0 (
                `else
                    `ifdef HSSI_E100
                    green_hssi_e100 prz0 (
                    `else
                        `ifdef HSSI_SQ8
                            green_hssi_sq8 prz0 (
                        `else
                            `ifdef HSSI_SQ1
                                green_hssi_sq1 prz0 (
                            `else
                                green_hssi_lfsr prz0 (
                            `endif
                        `endif
                    `endif
                `endif
            `endif
        `endif
    `endif

    .hssi (hssi)
        
    `ifdef ETH_E2E
        // management port
        .prmgmt_ctrl_clk    (Clk_100         ),
        .prmgmt_cmd         (prmgmt_cmd_mux  ),
        .prmgmt_addr        (prmgmt_addr_mux ),
        .prmgmt_din         (prmgmt_din_mux  ),
        .prmgmt_dout        (prmgmt_dout     ),
        .prmgmt_freeze      (prmgmt_freeze   ),
        .prmgmt_arst        (prmgmt_arst     ),
        .prmgmt_ram_ena     (prmgmt_ram_ena  ),
        .prmgmt_fatal_err   (prmgmt_fatal_err),
        // I2C and GPIO ports
        .g2b_GPIO_a     (g2b_GPIO_a   ), 
        .g2b_GPIO_b     (g2b_GPIO_b   ), 
        .g2b_I2C0_scl   (g2b_I2C0_scl ), 
        .g2b_I2C0_sda   (g2b_I2C0_sda ), 
        .g2b_I2C0_rstn  (g2b_I2C0_rstn), 
        .g2b_I2C1_scl   (g2b_I2C1_scl ), 
        .g2b_I2C1_sda   (g2b_I2C1_sda ), 
        .g2b_I2C1_rstn  (g2b_I2C1_rstn), 
                
        .b2g_GPIO_a     (b2g_GPIO_a   ), 
        .b2g_GPIO_b     (b2g_GPIO_b   ), 
        .b2g_I2C0_scl   (b2g_I2C0_scl ), 
        .b2g_I2C0_sda   (b2g_I2C0_sda ), 
        .b2g_I2C0_rstn  (b2g_I2C0_rstn), 
        .b2g_I2C1_scl   (b2g_I2C1_scl ), 
        .b2g_I2C1_sda   (b2g_I2C1_sda ), 
        .b2g_I2C1_rstn  (b2g_I2C1_rstn), 

        .oen_GPIO_a     (oen_GPIO_a   ), 
        .oen_GPIO_b     (oen_GPIO_b   ), 
        .oen_I2C0_scl   (oen_I2C0_scl ), 
        .oen_I2C0_sda   (oen_I2C0_sda ), 
        .oen_I2C0_rstn  (oen_I2C0_rstn), 
        .oen_I2C1_scl   (oen_I2C1_scl ), 
        .oen_I2C1_sda   (oen_I2C1_sda ), 
        .oen_I2C1_rstn  (oen_I2C1_rstn)  
    //`else // ETH_E2E
    //  // management port
    //  .prmgmt_ctrl_clk    (Clk_100         ),
    //  .prmgmt_cmd         (prmgmt_cmd      ),
    //  .prmgmt_addr        (prmgmt_addr     ),
    //  .prmgmt_din         (prmgmt_din      ),
    //  .prmgmt_dout        (prmgmt_dout     ),
    //  .prmgmt_freeze      (prmgmt_freeze   ),
    //  .prmgmt_arst        (prmgmt_arst     ),
    //  .prmgmt_ram_ena     (prmgmt_ram_ena  ),
    //  .prmgmt_fatal_err   (prmgmt_fatal_err)
    `endif // ETH_E2E_E40
    );



assign g2b_GPIO_a    = 5'b0;
assign g2b_GPIO_b    = 5'b0;
assign g2b_I2C0_scl  = 1'b0;
assign g2b_I2C0_sda  = 1'b0;
assign g2b_I2C0_rstn = 1'b0;
assign g2b_I2C1_scl  = 1'b0;
assign g2b_I2C1_sda  = 1'b0;
assign g2b_I2C1_rstn = 1'b0;

assign oen_GPIO_a    = 5'b0;
assign oen_GPIO_b    = 5'b0;
assign oen_I2C0_scl  = 1'b0;
assign oen_I2C0_sda  = 1'b0;
assign oen_I2C0_rstn = 1'b0;
assign oen_I2C1_scl  = 1'b0;
assign oen_I2C1_sda  = 1'b0;
assign oen_I2C1_rstn = 1'b0;

(* noprune *) reg [4:0] b2g_GPIO_a_q;
(* noprune *) reg [4:0] b2g_GPIO_b_q;
(* noprune *) reg       b2g_I2C0_scl_q;
(* noprune *) reg       b2g_I2C0_sda_q;
(* noprune *) reg       b2g_I2C0_rstn_q;
(* noprune *) reg       b2g_I2C1_scl_q;
(* noprune *) reg       b2g_I2C1_sda_q;
(* noprune *) reg       b2g_I2C1_rstn_q;

always @(posedge Clk_100)
begin
    b2g_GPIO_a_q    <= b2g_GPIO_a    ;
    b2g_GPIO_b_q    <= b2g_GPIO_b    ;
    b2g_I2C0_scl_q  <= b2g_I2C0_scl  ;
    b2g_I2C0_sda_q  <= b2g_I2C0_sda  ;
    b2g_I2C0_rstn_q <= b2g_I2C0_rstn ;
    b2g_I2C1_scl_q  <= b2g_I2C1_scl  ;
    b2g_I2C1_sda_q  <= b2g_I2C1_sda  ;
    b2g_I2C1_rstn_q <= b2g_I2C1_rstn ;
end
`endif // INCLUDE_ETHERNET
endmodule
