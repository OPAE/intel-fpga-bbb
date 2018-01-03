// baeckler - 05-11-2016

`timescale 1 ps / 1 ps
module green_hssi_if_e10
  #(
    parameter NUM_LN = 16   // no override
   )
   (
    // native SERDES interface - multi mode
    output  [NUM_LN-1:0]   tx_analogreset,
    output  [NUM_LN-1:0]   tx_digitalreset,
    output  [NUM_LN-1:0]   rx_analogreset,
    output  [NUM_LN-1:0]   rx_digitalreset,
    input                  tx_cal_busy,
    input                  rx_cal_busy,
    output  [NUM_LN-1:0]   rx_seriallpbken,
    output  [NUM_LN-1:0]   rx_set_locktodata,
    output  [NUM_LN-1:0]   rx_set_locktoref,
    input [NUM_LN-1:0]   rx_is_lockedtoref,
    input [NUM_LN-1:0]   rx_is_lockedtodata,
    input                tx_pll_locked,

    input tx_common_clk,
    input tx_common_clk2,
    input tx_common_locked,
    input rx_common_clk,
    input rx_common_clk2,
    input rx_common_locked,

    output  [NUM_LN*128-1:0] tx_parallel_data,
    input [NUM_LN*128-1:0] rx_parallel_data,
    input [NUM_LN*20-1:0]  rx_control,
    output  [NUM_LN*18-1:0]  tx_control,
    //output  [NUM_LN-1:0]   rx_bitslip,
    output  [NUM_LN-1:0]   tx_enh_data_valid,
    input [NUM_LN-1:0]   tx_enh_fifo_full,
    input [NUM_LN-1:0]   tx_enh_fifo_pfull,
    input [NUM_LN-1:0]   tx_enh_fifo_empty,
    input [NUM_LN-1:0]   tx_enh_fifo_pempty,
    output  [NUM_LN-1:0]   rx_enh_fifo_rd_en,
    input [NUM_LN-1:0]   rx_enh_data_valid,
    input [NUM_LN-1:0]   rx_enh_fifo_full,
    input [NUM_LN-1:0]   rx_enh_fifo_pfull,
    input [NUM_LN-1:0]   rx_enh_fifo_empty,
    input [NUM_LN-1:0]   rx_enh_fifo_pempty,
    //output  [NUM_LN-1:0]   rx_enh_fifo_align_clr,
    input [NUM_LN-1:0]   rx_enh_blk_lock,
    //input [NUM_LN-1:0]  rx_enh_fifo_del,
    //input [NUM_LN-1:0]  rx_enh_fifo_insert,
    input [NUM_LN-1:0]  rx_enh_highber,
    //input [NUM_LN-1:0]  rx_pma_div_clkout,
    //input [NUM_LN-1:0]  tx_pma_div_clkout,

    output reg init_start,
    input  init_done,

    // little management port
    input prmgmt_ctrl_clk,
    input  [15:0] prmgmt_cmd,
    input  [15:0] prmgmt_addr,
    input  [31:0] prmgmt_din,
    output  [31:0] prmgmt_dout,
    input prmgmt_freeze,
    input prmgmt_arst,
    input prmgmt_ram_ena,
    output reg prmgmt_fatal_err
);

    //
    // drive the output wires into a civilized state
    //

    assign init_start = 1'b0;
    assign prmgmt_dout_r = 32'h0;
    assign prmgmt_fatal_err = 1'b0;

    genvar i;
    generate
        for (i = 0; i < NUM_LN; i = i + 1)
        begin : unused_ln
            assign tx_analogreset[i] = 1'b1;
            assign tx_digitalreset[i] = 1'b1;
            assign rx_analogreset[i] = 1'b1;
            assign rx_digitalreset[i] = 1'b1;
            assign rx_seriallpbken[i] = 1'b1;
            assign rx_set_locktodata[i] = 1'b0;
            assign rx_set_locktoref[i] = 1'b0;
            assign tx_enh_data_valid[i] = 1'b0;
            assign rx_enh_fifo_rd_en[i] = 1'b0;

            assign tx_parallel_data[(i+1)*128-1:i*128] = 128'h0;
            assign tx_control[(i+1)*18-1:i*18] = 18'h0;
        end
    endgenerate

endmodule
