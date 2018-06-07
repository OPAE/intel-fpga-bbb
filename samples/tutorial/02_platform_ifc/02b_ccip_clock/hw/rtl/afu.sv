// ***************************************************************************
// Copyright (c) 2013-2017, Intel Corporation All Rights Reserved.
// The source code contained or described herein and all  documents related to
// the  source  code  ("Material")  are  owned by  Intel  Corporation  or  its
// suppliers  or  licensors.    Title  to  the  Material  remains  with  Intel
// Corporation or  its suppliers  and licensors.  The Material  contains trade
// secrets and  proprietary  and  confidential  information  of  Intel or  its
// suppliers and licensors.  The Material is protected  by worldwide copyright
// and trade secret laws and treaty provisions. No part of the Material may be
// copied,    reproduced,    modified,    published,     uploaded,     posted,
// transmitted,  distributed,  or  disclosed  in any way without Intel's prior
// express written permission.
// ***************************************************************************
//
// Tie counters to CCI-P clocks in order to compare their frequencies.
// The frequency of pClk is exported via an MMIO CSR, allowing software
// to compute the actual frequencies of all clocks.
//

`include "platform_if.vh"
`include "afu_json_info.vh"

module afu
   (
    // Clock/reset pair for CCI-P transactions.  These are configurable in the
    // AFU's JSON file and set up by the OPAE Platform Interface Manager.
    input  logic        clk,
    input  logic        reset,

    // Standard CCI-P clocks
    input  logic        pClk,                 // Primary CCI-P interface clock.
    input  logic        pClkDiv2,             // Aligned, pClk divided by 2.
    input  logic        pClkDiv4,             // Aligned, pClk divided by 4.
    input  logic        uClk_usr,             // User clock domain. Refer to clock programming guide.
    input  logic        uClk_usrDiv2,         // Aligned, user clock divided by 2.

    // CCI-P structures
    input  t_if_ccip_Rx cp2af_sRx,        // CCI-P Rx Port
    output t_if_ccip_Tx af2cp_sTx         // CCI-P Tx Port
    );

    // AFU UUID from the AFU JSON (stored in the generated afu_json_info.vh)
    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    logic [63:0] reset_counter = 0;
    logic [63:0] enable_counter = 0;

    localparam N_COUNTER_BITS = 40;

    logic [N_COUNTER_BITS-1:0] counter_max = 0;
    logic [N_COUNTER_BITS-1:0] counter_pclk_value;
    logic [N_COUNTER_BITS-1:0] counter_pclk_div2_value;
    logic [N_COUNTER_BITS-1:0] counter_pclk_div4_value;
    logic [N_COUNTER_BITS-1:0] counter_clkusr_value;
    logic [N_COUNTER_BITS-1:0] counter_clkusr_div2_value;
    logic [N_COUNTER_BITS-1:0] counter_clk_value;

    logic max_value_reached;
    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_pclk_inst (
        .clk(clk),
        .count_clk(pClk),
        .count(counter_pclk_value),
        .max_value(counter_max),
        .max_value_reached(max_value_reached),
        .sync_reset(reset | reset_counter[0]),
        .enable(enable_counter[0])
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_pclk_div2_inst (
        .clk(clk),
        .count_clk(pClkDiv2),
        .count(counter_pclk_div2_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset(reset | reset_counter[0]),
        .enable(enable_counter[0] & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_pclk_div4_inst (
        .clk(clk),
        .count_clk(pClkDiv4),
        .count(counter_pclk_div4_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset(reset | reset_counter[0]),
        .enable(enable_counter[0] & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_clkusr_inst (
        .clk(clk),
        .count_clk(uClk_usr),
        .count(counter_clkusr_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset(reset | reset_counter[0]),
        .enable(enable_counter[0] & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_clkusr_div2_inst (
        .clk(clk),
        .count_clk(uClk_usrDiv2),
        .count(counter_clkusr_div2_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset(reset | reset_counter[0]),
        .enable(enable_counter[0] & ~max_value_reached)
    );

    clock_counter#(.COUNTER_WIDTH(N_COUNTER_BITS)) counter_clk_inst (
        .clk(clk),
        .count_clk(clk),
        .count(counter_clk_value),
        .max_value('0),
        .max_value_reached(),
        .sync_reset(reset | reset_counter[0]),
        .enable(enable_counter[0] & ~max_value_reached)
    );

    // cast c0 header into ReqMmioHdr
    t_ccip_c0_ReqMmioHdr mmioHdr;
    assign mmioHdr = t_ccip_c0_ReqMmioHdr'(cp2af_sRx.c0.hdr);

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            af2cp_sTx.c1.hdr        <= '0;
            af2cp_sTx.c1.valid      <= '0;
            af2cp_sTx.c1.data       <= '0;
            af2cp_sTx.c0.hdr        <= '0;
            af2cp_sTx.c0.valid      <= '0;
            af2cp_sTx.c2.hdr        <= '0;
            af2cp_sTx.c2.data       <= '0;
            af2cp_sTx.c2.mmioRdValid <= '0;
            reset_counter  <= 64'b1;
            enable_counter <= '0;
            counter_max    <= '0;
        end
        else
        begin
            af2cp_sTx.c2.mmioRdValid <= 0;

            // set the registers on MMIO write request
            // these are user-defined AFU registers at offset 0x40 and 0x41
            if (cp2af_sRx.c0.mmioWrValid)
            begin
                case (mmioHdr.address)
                    16'h0022: reset_counter <= cp2af_sRx.c0.data[63:0];
                    16'h0024: enable_counter <= cp2af_sRx.c0.data[63:0];
                    16'h0026: counter_max <= cp2af_sRx.c0.data[N_COUNTER_BITS-1:0];
                endcase
            end

            // serve MMIO read requests
            if (cp2af_sRx.c0.mmioRdValid)
            begin
                af2cp_sTx.c2.hdr.tid <= mmioHdr.tid; // copy TID

                case (mmioHdr.address)
                    // AFU header
                    16'h0000: af2cp_sTx.c2.data <=
                                   {
                                    4'b0001, // Feature type = AFU
                                    8'b0,    // reserved
                                    4'b0,    // afu minor revision = 0
                                    7'b0,    // reserved
                                    1'b1,    // end of DFH list = 1
                                    24'b0,   // next DFH offset = 0
                                    4'b0,    // afu major revision = 0
                                    12'b0    // feature ID = 0
                                    };
                    16'h0002: af2cp_sTx.c2.data <= afu_id[63:0]; // afu id low
                    16'h0004: af2cp_sTx.c2.data <= afu_id[127:64]; // afu id hi
                    16'h0006: af2cp_sTx.c2.data <= 64'h0; // reserved
                    16'h0008: af2cp_sTx.c2.data <= 64'h0; // reserved
                    16'h0020: af2cp_sTx.c2.data <= 64'(max_value_reached); // status
                    16'h0022: af2cp_sTx.c2.data <= reset_counter;
                    16'h0024: af2cp_sTx.c2.data <= enable_counter;
                    16'h0026: af2cp_sTx.c2.data <= 64'(counter_max);
                    16'h0028: af2cp_sTx.c2.data <= 64'(counter_pclk_value);
                    16'h002a: af2cp_sTx.c2.data <= 64'(counter_pclk_div2_value);
                    16'h002c: af2cp_sTx.c2.data <= 64'(counter_pclk_div4_value);
                    16'h002e: af2cp_sTx.c2.data <= 64'(counter_clkusr_value);
                    16'h0030: af2cp_sTx.c2.data <= 64'(counter_clkusr_div2_value);
                    16'h0032: af2cp_sTx.c2.data <= 64'(counter_clk_value);
                    16'h0034: af2cp_sTx.c2.data <= 64'(ccip_cfg_pkg::PCLK_FREQ);
                    default:  af2cp_sTx.c2.data <= 64'h0;
                endcase

                af2cp_sTx.c2.mmioRdValid <= 1; // post response
            end
        end
    end
endmodule


//
// Clock crossing shim for the counters.
//
module clock_counter
  #(
    parameter COUNTER_WIDTH = 16
    )
   (
    input  logic clk,

    input  logic count_clk,
    output logic [COUNTER_WIDTH-1:0] count,
    input  logic [COUNTER_WIDTH-1:0] max_value,
    output logic max_value_reached,
    input  logic sync_reset,
    input  logic enable
    );

    // Convenient names that will be used to declare timing constraints for clock crossing
    (* preserve *) logic [COUNTER_WIDTH-1:0] cntsync_count;
    (* preserve *) logic [COUNTER_WIDTH-1:0] cntsync_max_value;
    (* preserve *) logic cntsync_max_value_reached;
    (* preserve *) logic cntsync_reset;
    (* preserve *) logic cntsync_enable;

    logic [COUNTER_WIDTH-1:0] count_impl_out;
    logic count_impl_max_value_reached;

    always_ff @(posedge count_clk)
    begin
        cntsync_count <= count_impl_out;
        cntsync_max_value_reached <= count_impl_max_value_reached;
    end

    always_ff @(posedge clk)
    begin
        count <= cntsync_count;
        max_value_reached <= cntsync_max_value_reached;
    end

    (* preserve *) logic reset_T1;
    (* preserve *) logic enable_T1;

    always_ff @(posedge count_clk)
    begin
        cntsync_max_value <= max_value;
        cntsync_reset <= sync_reset;
        cntsync_enable <= enable;

        reset_T1 <= cntsync_reset;
        enable_T1 <= cntsync_enable;
    end

    // Instantiate the real counter.
    clock_counter_impl
      #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
        )
      counter
       (
        .count_clk(count_clk),
        .count(count_impl_out),
        .max_value(cntsync_max_value),
        .max_value_reached(count_impl_max_value_reached),
        .sync_reset(reset_T1),
        .enable(enable_T1)
        );
endmodule


module clock_counter_impl
  #(
    parameter COUNTER_WIDTH = 16
    )
   (
    input  logic count_clk,
    output logic [COUNTER_WIDTH-1:0] count,
    input  logic [COUNTER_WIDTH-1:0] max_value,
    output logic max_value_reached,
    input  logic sync_reset,
    input  logic enable
    );

    logic sync_enable;
    logic max_value_is_set;

    always_ff @(posedge count_clk)
    begin
        if (sync_reset)
        begin
            count <= 1'b0;
            max_value_reached <= 1'b0;
        end
        else
        begin
            max_value_reached <= max_value_reached ||
                                 (max_value_is_set && (count == max_value));

            if (sync_enable & ~max_value_reached)
            begin
                count <= count + 1;
            end
        end

        sync_enable <= enable;
        max_value_is_set <= (|(max_value));
    end
endmodule
