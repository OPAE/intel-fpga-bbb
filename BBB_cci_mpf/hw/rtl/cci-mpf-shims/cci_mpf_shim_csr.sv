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

`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

//
// There is a single CSR (MMIO read/write) manager in MPF, shared by all
// shims. When a shim is not present in a system it will not be found in the
// MMIO feature chain.
//

module cci_mpf_shim_csr
  #(
    // Instance ID reported in feature IDs of all device feature
    // headers instantiated under this instance of MPF.  If only a single
    // MPF instance is instantiated in the AFU then leaving the instance
    // ID at 1 is probably the right choice.
    parameter MPF_INSTANCE_ID = 1,

    // MMIO base address (byte level) allocated to MPF for feature lists
    // and CSRs.  The AFU allocating this module must build at least
    // a device feature header (DFH) for the AFU.  The chain of device
    // features in the AFU must then point to the base address here
    // as another feature in the chain.  MPF will continue the list.
    // The base address here must point to a region that is at least
    // CCI_MPF_MMIO_SIZE bytes.
    parameter DFH_MMIO_BASE_ADDR = 0,

    // Address of the next device feature header outside MPF.  MPF will
    // terminate the feature list if the next address is 0.
    parameter DFH_MMIO_NEXT_ADDR = 0,

    // Are shims enabled?
    parameter MPF_ENABLE_VTP = 0,
    parameter MPF_ENABLE_RSP_ORDER = 0,
    parameter MPF_ENABLE_VC_MAP = 0,
    parameter MPF_ENABLE_LATENCY_QOS = 0,
    parameter MPF_ENABLE_WRO = 0,
    parameter MPF_ENABLE_PWRITE = 0
    )
   (
    input  logic clk,

    // Connection toward the QA platform.  Reset comes in here.
    cci_mpf_if.to_fiu fiu,

    // Connections toward user code.
    cci_mpf_if.to_afu afu,

    // CSR connections to other shims
    cci_mpf_csrs.csr csrs,
    cci_mpf_csrs.csr_events events,
    mpf_services_gen_csr_if.to_slave vtp_csrs
    );

    assign afu.reset = fiu.reset;

    logic reset = 1'b1;
    always @(posedge clk)
    begin
        reset <= fiu.reset;
    end

    // Most connections flow straight through and are, at most, read in this shim.
    assign fiu.c0Tx = afu.c0Tx;
    assign afu.c0TxAlmFull = fiu.c0TxAlmFull;
    assign fiu.c1Tx = afu.c1Tx;
    assign afu.c1TxAlmFull = fiu.c1TxAlmFull;

    assign afu.c0Rx = fiu.c0Rx;
    assign afu.c1Rx = fiu.c1Rx;

    // MMIO address range of MPF CSRs
    parameter CCI_MPF_CSR_SIZE = CCI_MPF_MMIO_SIZE;

    localparam CCI_MPF_CSR_LAST = DFH_MMIO_BASE_ADDR + CCI_MPF_CSR_SIZE;

    //
    // Base address of each shim's CSR range.
    //
    //   *** These must be sorted by the size of the CSR region, largest
    //   *** to smallest. The MMIO address matching logic inside each
    //   *** module assumes the base address of each region is naturally
    //   *** aligned to the size of the region!
    //
    localparam CCI_MPF_VTP_CSR_BASE = 0;
    localparam CCI_MPF_VC_MAP_CSR_BASE =      CCI_MPF_VTP_CSR_BASE +
                                              CCI_MPF_VTP_CSR_SIZE;
    localparam CCI_MPF_WRO_CSR_BASE =         CCI_MPF_VC_MAP_CSR_BASE +
                                              CCI_MPF_VC_MAP_CSR_SIZE;
    localparam CCI_MPF_RSP_ORDER_CSR_BASE =   CCI_MPF_WRO_CSR_BASE +
                                              CCI_MPF_WRO_CSR_SIZE;
    localparam CCI_MPF_LATENCY_QOS_CSR_BASE = CCI_MPF_RSP_ORDER_CSR_BASE +
                                              CCI_MPF_RSP_ORDER_CSR_SIZE;
    localparam CCI_MPF_PWRITE_CSR_BASE =      CCI_MPF_LATENCY_QOS_CSR_BASE +
                                              CCI_MPF_LATENCY_QOS_CSR_SIZE;
    localparam CCI_MPF_NEXT_BASE =            CCI_MPF_PWRITE_CSR_BASE +
                                              CCI_MPF_PWRITE_CSR_SIZE;

    // Address of an MPF CSR in a 64 bit space. Drop the high bits outside
    // the MPF CSR region, since those are tested early in the pipelines
    // below.
    typedef logic [$clog2(CCI_MPF_CSR_SIZE >> 3)-1 : 0] t_mpf_mmio_addr;

    // synthesis translate_off
    initial
    begin
        // This will fire if the base computation above doesn't match CCI_MPF_CSR_SIZE.
        // One of the two parameters is probably missing a CSR group.
        assert(CCI_MPF_NEXT_BASE == CCI_MPF_CSR_SIZE) else
            $fatal(2, "** ERROR ** %m: CCI_MPF_CSR_SIZE doesn't match MPF CSR group sizes");
    end
    // synthesis translate_on

    //
    // Byte address of next block from each shim's CSR range. We work backwards
    // here, with next pointers skipping shims that aren't enabled.
    //
    localparam CCI_MPF_PWRITE_CSR_NEXT = DFH_MMIO_NEXT_ADDR;
    localparam CCI_MPF_LATENCY_QOS_CSR_NEXT =
        (MPF_ENABLE_PWRITE ? CCI_MPF_PWRITE_CSR_BASE + DFH_MMIO_BASE_ADDR : CCI_MPF_PWRITE_CSR_NEXT);
    localparam CCI_MPF_RSP_ORDER_CSR_NEXT =
        (MPF_ENABLE_LATENCY_QOS ? CCI_MPF_LATENCY_QOS_CSR_BASE + DFH_MMIO_BASE_ADDR : CCI_MPF_LATENCY_QOS_CSR_NEXT);
    localparam CCI_MPF_WRO_CSR_NEXT =
        (MPF_ENABLE_RSP_ORDER ? CCI_MPF_RSP_ORDER_CSR_BASE + DFH_MMIO_BASE_ADDR : CCI_MPF_RSP_ORDER_CSR_NEXT);
    localparam CCI_MPF_VC_MAP_CSR_NEXT =
        (MPF_ENABLE_WRO ? CCI_MPF_WRO_CSR_BASE + DFH_MMIO_BASE_ADDR : CCI_MPF_WRO_CSR_NEXT);
    localparam CCI_MPF_VTP_CSR_NEXT =
        (MPF_ENABLE_VC_MAP ? CCI_MPF_VC_MAP_CSR_BASE + DFH_MMIO_BASE_ADDR : CCI_MPF_VC_MAP_CSR_NEXT);


    // ====================================================================
    //
    //  Incoming CSR read/write request pipeline
    //
    // ====================================================================

    t_if_cci_c0_Rx c0_rx_in;

    t_if_cci_c0_Rx c0_rx[0:1];
    t_mpf_mmio_addr c0_rx_addr;

    always_ff @(posedge clk)
    begin
        // First stage -- just register
        c0_rx_in <= fiu.c0Rx;

        // Second stage splits out the MMIO address so 0 is DFH_MMIO_BASE_ADDR.
        // The address is also reduced to indexing only the MPF CSR region in
        // 64 bit chunks.
        c0_rx[0] <= c0_rx_in;
        c0_rx_addr <= 
            t_mpf_mmio_addr'((cci_csr_getAddress(c0_rx_in) -
                              t_cci_mmioAddr'(DFH_MMIO_BASE_ADDR >> 2)) >> 1);
        // If requested address is outside MPF's CSR region ignore it.
        // MMIO addresses drop the low 2 bits since the mimimum size is 32 bits.
        if ((cci_csr_getAddress(c0_rx_in) < t_cci_mmioAddr'(DFH_MMIO_BASE_ADDR >> 2)) ||
            (cci_csr_getAddress(c0_rx_in) >= t_cci_mmioAddr'(CCI_MPF_CSR_LAST >> 2)))
        begin
            c0_rx[0].mmioRdValid <= 1'b0;
            c0_rx[0].mmioWrValid <= 1'b0;
        end

        c0_rx[1] <= c0_rx[0];
    end


    // ====================================================================
    //
    //  Shim-specific handlers
    //
    // ====================================================================

    logic vtp_rd_valid;
    logic [63:0] vtp_rd_data;

    cci_mpf_shim_csr_vtp
      #(
        .MPF_ENABLE_SHIM(MPF_ENABLE_VTP),
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .MMIO_SHIM_ADDR(CCI_MPF_VTP_CSR_BASE),
        .MMIO_SHIM_SIZE(CCI_MPF_VTP_CSR_SIZE),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .MMIO_NEXT_ADDR(CCI_MPF_VTP_CSR_NEXT),
        .N_ADDR_BITS($bits(t_mpf_mmio_addr))
        )
      vtp
       (
        .clk,
        .reset,
        .mmioWrValid(c0_rx[0].mmioWrValid),
        .mmio_addr(c0_rx_addr),
        .wr_data(64'(c0_rx[0].data)),
        .rd_valid(vtp_rd_valid),
        .rd_data(vtp_rd_data),

        .gen_csr_if(vtp_csrs)
        );


    logic vc_map_rd_valid;
    logic [63:0] vc_map_rd_data;

    cci_mpf_shim_csr_vc_map
      #(
        .MPF_ENABLE_SHIM(MPF_ENABLE_VC_MAP),
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .MMIO_SHIM_ADDR(CCI_MPF_VC_MAP_CSR_BASE),
        .MMIO_SHIM_SIZE(CCI_MPF_VC_MAP_CSR_SIZE),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .MMIO_NEXT_ADDR(CCI_MPF_VC_MAP_CSR_NEXT),
        .N_ADDR_BITS($bits(t_mpf_mmio_addr))
        )
      vc_map
       (
        .clk,
        .reset,
        .mmioWrValid(c0_rx[0].mmioWrValid),
        .mmio_addr(c0_rx_addr),
        .wr_data(64'(c0_rx[0].data)),
        .rd_valid(vc_map_rd_valid),
        .rd_data(vc_map_rd_data),

        .vc_map_out_event_mapping_changed(events.vc_map_out_event_mapping_changed),
        .vc_map_history(csrs.vc_map_history),
        .vc_map_ctrl(csrs.vc_map_ctrl),
        .vc_map_ctrl_valid(csrs.vc_map_ctrl_valid)
        );


    logic wro_rd_valid;
    logic [63:0] wro_rd_data;

    cci_mpf_shim_csr_wro
      #(
        .MPF_ENABLE_SHIM(MPF_ENABLE_WRO),
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .MMIO_SHIM_ADDR(CCI_MPF_WRO_CSR_BASE),
        .MMIO_SHIM_SIZE(CCI_MPF_WRO_CSR_SIZE),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .MMIO_NEXT_ADDR(CCI_MPF_WRO_CSR_NEXT),
        .N_ADDR_BITS($bits(t_mpf_mmio_addr))
        )
      wro
       (
        .clk,
        .reset,
        .mmioWrValid(c0_rx[0].mmioWrValid),
        .mmio_addr(c0_rx_addr),
        .wr_data(64'(c0_rx[0].data)),
        .rd_valid(wro_rd_valid),
        .rd_data(wro_rd_data),

        .wro_pipe_events(events.wro_pipe_events),
        .wro_ctrl(csrs.wro_ctrl),
        .wro_ctrl_valid(csrs.wro_ctrl_valid)
        );


    logic rsp_order_rd_valid;
    logic [63:0] rsp_order_rd_data;

    cci_mpf_shim_csr_rsp_order
      #(
        .MPF_ENABLE_SHIM(MPF_ENABLE_RSP_ORDER),
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .MMIO_SHIM_ADDR(CCI_MPF_RSP_ORDER_CSR_BASE),
        .MMIO_SHIM_SIZE(CCI_MPF_RSP_ORDER_CSR_SIZE),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .MMIO_NEXT_ADDR(CCI_MPF_RSP_ORDER_CSR_NEXT),
        .N_ADDR_BITS($bits(t_mpf_mmio_addr))
        )
      rsp_order
       (
        .clk,
        .reset,
        .mmioWrValid(c0_rx[0].mmioWrValid),
        .mmio_addr(c0_rx_addr),
        .wr_data(64'(c0_rx[0].data)),
        .rd_valid(rsp_order_rd_valid),
        .rd_data(rsp_order_rd_data)
        );


    logic latency_qos_rd_valid;
    logic [63:0] latency_qos_rd_data;

    cci_mpf_shim_csr_latency_qos
      #(
        .MPF_ENABLE_SHIM(MPF_ENABLE_LATENCY_QOS),
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .MMIO_SHIM_ADDR(CCI_MPF_LATENCY_QOS_CSR_BASE),
        .MMIO_SHIM_SIZE(CCI_MPF_LATENCY_QOS_CSR_SIZE),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .MMIO_NEXT_ADDR(CCI_MPF_LATENCY_QOS_CSR_NEXT),
        .N_ADDR_BITS($bits(t_mpf_mmio_addr))
        )
      latency_qos
       (
        .clk,
        .reset,
        .mmioWrValid(c0_rx[0].mmioWrValid),
        .mmio_addr(c0_rx_addr),
        .wr_data(64'(c0_rx[0].data)),
        .rd_valid(latency_qos_rd_valid),
        .rd_data(latency_qos_rd_data),

        .latency_qos_ctrl(csrs.latency_qos_ctrl),
        .latency_qos_ctrl_valid(csrs.latency_qos_ctrl_valid)
        );


    logic pwrite_rd_valid;
    logic [63:0] pwrite_rd_data;

    cci_mpf_shim_csr_pwrite
      #(
        .MPF_ENABLE_SHIM(MPF_ENABLE_PWRITE),
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .MMIO_SHIM_ADDR(CCI_MPF_PWRITE_CSR_BASE),
        .MMIO_SHIM_SIZE(CCI_MPF_PWRITE_CSR_SIZE),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .MMIO_NEXT_ADDR(CCI_MPF_PWRITE_CSR_NEXT),
        .N_ADDR_BITS($bits(t_mpf_mmio_addr))
        )
      pwrite
       (
        .clk,
        .reset,
        .mmioWrValid(c0_rx[0].mmioWrValid),
        .mmio_addr(c0_rx_addr),
        .wr_data(64'(c0_rx[0].data)),
        .rd_valid(pwrite_rd_valid),
        .rd_data(pwrite_rd_data),

        .pwrite_out_event_pwrite(events.pwrite_out_event_pwrite)
        );


    // ====================================================================
    //
    //  Read responses back to host
    //
    // ====================================================================

    logic rd_valid;
    logic [63:0] rd_data;
    t_ccip_tid rd_tid;

    // Only one shim will have a valid read in a given cycle
    always_ff @(posedge clk)
    begin
        rd_valid <= 1'b0;
        rd_tid <= cci_csr_getTid(c0_rx[1]);

        if (vtp_rd_valid)
        begin
            rd_valid <= c0_rx[1].mmioRdValid;
            rd_data <= vtp_rd_data;
        end

        if (vc_map_rd_valid)
        begin
            rd_valid <= c0_rx[1].mmioRdValid;
            rd_data <= vc_map_rd_data;
        end

        if (wro_rd_valid)
        begin
            rd_valid <= c0_rx[1].mmioRdValid;
            rd_data <= wro_rd_data;
        end

        if (rsp_order_rd_valid)
        begin
            rd_valid <= c0_rx[1].mmioRdValid;
            rd_data <= rsp_order_rd_data;
        end

        if (latency_qos_rd_valid)
        begin
            rd_valid <= c0_rx[1].mmioRdValid;
            rd_data <= latency_qos_rd_data;
        end

        if (pwrite_rd_valid)
        begin
            rd_valid <= c0_rx[1].mmioRdValid;
            rd_data <= pwrite_rd_data;
        end
    end

    // Push responses into a FIFO so they can be merged with other MMIO
    // read responses coming from the AFU.
    logic mmio_rsp_valid;
    logic [63:0] mmio_rsp_data;
    t_ccip_tid mmio_rsp_tid;
    logic mmio_rsp_en;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS(CCIP_TID_WIDTH + 64),
        .N_ENTRIES(64),
        .REGISTER_OUTPUT(1)
        )
      rsp_fifo
        (
         .clk,
         .reset,
         .enq_data({ rd_tid, rd_data }),
         .enq_en(rd_valid),
         .notFull(),
         .almostFull(),
         .first({ mmio_rsp_tid, mmio_rsp_data }),
         .deq_en(mmio_rsp_en),
         .notEmpty(mmio_rsp_valid)
         );

    // Forward responses to host, either generated locally (c2_rsp) or from
    // the AFU.
    assign mmio_rsp_en = mmio_rsp_valid && ! afu.c2Tx.mmioRdValid;

    always_ff @(posedge clk)
    begin
        if (mmio_rsp_en)
        begin
            fiu.c2Tx <= '0;
            fiu.c2Tx.mmioRdValid <= 1'b1;
            fiu.c2Tx.hdr.tid <= mmio_rsp_tid;
            fiu.c2Tx.data <= t_ccip_mmioData'(mmio_rsp_data);
        end
        else
        begin
            fiu.c2Tx <= afu.c2Tx;
        end
    end

endmodule // cci_mpf_shim_csr


// Standard prolog in shim CSR handlers. Define the UUID and some MMIO
// address parsing state.
`define MPF_CSR_SHIM_STD_PROLOG(BBB_UUID) \
    logic [127:0] shim_uuid; \
    assign shim_uuid = (MPF_ENABLE_SHIM ? BBB_UUID : 128'b0); \
    \
    // Low bits in mmio_addr that index 64 bit CSRs within this shim \
    localparam LOCAL_ADDR_BITS = $clog2(MMIO_SHIM_SIZE >> 3); \
    localparam SHIM_ADDR_BITS = N_ADDR_BITS - LOCAL_ADDR_BITS; \
    \
    logic [LOCAL_ADDR_BITS-1 : 0] mmio_addr_local, mmio_addr_local_q; \
    logic [SHIM_ADDR_BITS-1 : 0] mmio_addr_shim; \
    \
    assign {mmio_addr_shim, mmio_addr_local} = mmio_addr; \
    \
    // Does incoming address match this shim? \
    logic shim_addr_match; \
    assign shim_addr_match = \
        (mmio_addr_shim == SHIM_ADDR_BITS'(MMIO_SHIM_ADDR >> (LOCAL_ADDR_BITS + 3))); \
    \
    // Address computation and buffering for CSR writes \
    logic shim_wr_valid; \
    logic [$bits(wr_data)-1 : 0] wr_data_q; \
    always_ff @(posedge clk) \
    begin \
        shim_wr_valid <= shim_addr_match && mmioWrValid; \
        wr_data_q <= wr_data; \
        mmio_addr_local_q <= mmio_addr_local; \
    end


// Convert a CSR byte offset to a local 64-bit index
`define MPF_CSR_IDX(byte_offset) LOCAL_ADDR_BITS'(byte_offset >> 3)

// Generic event counter. Drive 0 when the shim is disabled.
`define MPF_CSR_STAT_ACCUM(N_BITS, NAME) \
    logic [N_BITS-1 : 0] ``NAME``_accum; \
    generate \
        if (MPF_ENABLE_SHIM == 0) \
        begin : nc_``NAME \
            assign ``NAME``_accum = '0; \
        end \
        else \
        begin : ctr_``NAME \
            cci_mpf_prim_counter_multicycle#(.NUM_BITS(N_BITS)) ctr \
               ( \
                .clk, \
                .reset, \
                .incr_by(N_BITS'(NAME)), \
                .value(``NAME``_accum) \
                ); \
        end \
    endgenerate

// Group of generic event counters. This macro differs from MPF_CSR_STAT_ACCUM
// only in the naming of the incoming event port.
`define MPF_CSR_STAT_ACCUM_GROUP(N_BITS, GROUP, NAME) \
    logic [N_BITS-1 : 0] ``GROUP``_``NAME``_accum; \
    generate \
        if (MPF_ENABLE_SHIM == 0) \
        begin : nc_``GROUP``_``NAME \
            assign ``GROUP``_``NAME``_accum = '0; \
        end \
        else \
        begin : ctr_``GROUP``_``NAME \
            cci_mpf_prim_counter_multicycle#(.NUM_BITS(N_BITS)) ctr_``GROUP``_``NAME \
               ( \
                .clk, \
                .reset, \
                .incr_by(N_BITS'(``GROUP``.NAME)), \
                .value(``GROUP``_``NAME``_accum) \
                ); \
        end \
    endgenerate

module cci_mpf_shim_csr_vtp
  #(
    parameter MPF_ENABLE_SHIM = 0,
    parameter MPF_INSTANCE_ID = 0,

    // Byte addresses
    parameter MMIO_SHIM_ADDR = 0,    // Address offset within MPF CSR space
    parameter MMIO_SHIM_SIZE = 0,
    parameter DFH_MMIO_BASE_ADDR,    // Base MMIO address of MPF CSR space
    parameter MMIO_NEXT_ADDR = 0,

    // Address bits in t_mpf_mmio_addr (64-bit word address in MPF CSR range)
    parameter N_ADDR_BITS = 0
    )
   (
    input  logic clk,
    input  logic reset,

    input  logic mmioWrValid,
    input  logic [N_ADDR_BITS-1 : 0] mmio_addr,
    input  logic [63:0] wr_data,

    // CSR read value in each cycle following mmio_addr. rd_valid is set as long as
    // mmio_addr matches this module's CSR range. There is no mmioRdValid trigger.
    // The parent module module is responsible for gating reads from mmioRdValid.
    output logic rd_valid,
    output logic [63:0] rd_data,

    mpf_services_gen_csr_if.to_slave gen_csr_if
    );

    //
    // VTP CSRs are managed inside the MPF VTP service. Decode MMIO addresses
    // and pass requests to VTP. The address passed to VTP is already decoded.
    // It is just the offset of the CSR within VTP's region.
    //

    `MPF_CSR_SHIM_STD_PROLOG(128'hc8a2982f_ff96_42bf_a705_45727f501901);

    // The DFH is generated here since the code here knows the MMIO address
    // space layout and VTP does not.
    assign gen_csr_if.dfh_value =
        ccip_dfh_genDFH(MMIO_NEXT_ADDR - MMIO_SHIM_ADDR - DFH_MMIO_BASE_ADDR,
                        MPF_INSTANCE_ID,
                        MMIO_NEXT_ADDR == 0);

    assign gen_csr_if.csr_req_idx = mmio_addr_local;
    assign gen_csr_if.rd_req_en = shim_addr_match;
    assign gen_csr_if.wr_req_en = shim_addr_match && mmioWrValid;
    assign gen_csr_if.wr_data = wr_data;

    assign rd_valid = gen_csr_if.rd_rsp_valid;
    assign rd_data = gen_csr_if.rd_data;

endmodule // cci_mpf_shim_csr_vtp


module cci_mpf_shim_csr_vc_map
  #(
    parameter MPF_ENABLE_SHIM = 0,
    parameter MPF_INSTANCE_ID = 0,

    // Byte addresses
    parameter MMIO_SHIM_ADDR = 0,    // Address offset within MPF CSR space
    parameter MMIO_SHIM_SIZE = 0,
    parameter DFH_MMIO_BASE_ADDR,    // Base MMIO address of MPF CSR space
    parameter MMIO_NEXT_ADDR = 0,

    // Address bits in t_mpf_mmio_addr (64-bit word address in MPF CSR range)
    parameter N_ADDR_BITS = 0
    )
   (
    input  logic clk,
    input  logic reset,

    input  logic mmioWrValid,
    input  logic [N_ADDR_BITS-1 : 0] mmio_addr,
    input  logic [63:0] wr_data,

    // CSR read value in each cycle following mmio_addr. rd_valid is set as long as
    // mmio_addr matches this module's CSR range. There is no mmioRdValid trigger.
    // The parent module module is responsible for gating reads from mmioRdValid.
    output logic rd_valid,
    output logic [63:0] rd_data,

    input  logic vc_map_out_event_mapping_changed,
    input  logic [63:0] vc_map_history,
    output logic [63:0] vc_map_ctrl,
    output logic vc_map_ctrl_valid
    );

    `MPF_CSR_SHIM_STD_PROLOG(128'h5046c86f_ba48_4856_b8f9_3b76e3dd4e74);

    `MPF_CSR_STAT_ACCUM(54, vc_map_out_event_mapping_changed);

    always_ff @(posedge clk)
    begin
        rd_valid <= shim_addr_match;

        case (mmio_addr_local)
            // DFH
          LOCAL_ADDR_BITS'(0):
            rd_data <= ccip_dfh_genDFH(MMIO_NEXT_ADDR - MMIO_SHIM_ADDR - DFH_MMIO_BASE_ADDR,
                                       MPF_INSTANCE_ID,
                                       MMIO_NEXT_ADDR == 0);
            // BBB ID
          LOCAL_ADDR_BITS'(1):
            rd_data <= shim_uuid[63:0];
          LOCAL_ADDR_BITS'(2):
            rd_data <= shim_uuid[127:64];

            // CSRs
          `MPF_CSR_IDX(CCI_MPF_VC_MAP_CSR_STAT_NUM_MAPPING_CHANGES):
            rd_data <= 64'(vc_map_out_event_mapping_changed_accum);
          `MPF_CSR_IDX(CCI_MPF_VC_MAP_CSR_STAT_HISTORY):
            rd_data <= vc_map_history;

          default:
            rd_data <= 64'b0;
        endcase
    end

    //
    // CSR writes
    //
    always_ff @(posedge clk)
    begin
        // Inval page held only one cycle
        vc_map_ctrl <= wr_data_q;
        vc_map_ctrl_valid <=
            shim_wr_valid &&
            (mmio_addr_local_q == `MPF_CSR_IDX(CCI_MPF_VC_MAP_CSR_CTRL_REG));

        if (reset)
        begin
            vc_map_ctrl_valid <= 1'b0;
        end
    end

endmodule // cci_mpf_shim_csr_vc_map


module cci_mpf_shim_csr_wro
  #(
    parameter MPF_ENABLE_SHIM = 0,
    parameter MPF_INSTANCE_ID = 0,

    // Byte addresses
    parameter MMIO_SHIM_ADDR = 0,    // Address offset within MPF CSR space
    parameter MMIO_SHIM_SIZE = 0,
    parameter DFH_MMIO_BASE_ADDR,    // Base MMIO address of MPF CSR space
    parameter MMIO_NEXT_ADDR = 0,

    // Address bits in t_mpf_mmio_addr (64-bit word address in MPF CSR range)
    parameter N_ADDR_BITS = 0
    )
   (
    input  logic clk,
    input  logic reset,

    input  logic mmioWrValid,
    input  logic [N_ADDR_BITS-1 : 0] mmio_addr,
    input  logic [63:0] wr_data,

    // CSR read value in each cycle following mmio_addr. rd_valid is set as long as
    // mmio_addr matches this module's CSR range. There is no mmioRdValid trigger.
    // The parent module module is responsible for gating reads from mmioRdValid.
    output logic rd_valid,
    output logic [63:0] rd_data,

    input  t_cci_mpf_wro_pipe_events wro_pipe_events,
    output logic [63:0] wro_ctrl,
    output logic wro_ctrl_valid
    );

    `MPF_CSR_SHIM_STD_PROLOG(128'h56b06b48_9dd7_4004_a47e_0681b4207a6d);

    // Event counters
    `MPF_CSR_STAT_ACCUM_GROUP(54, wro_pipe_events, rr_conflict);
    `MPF_CSR_STAT_ACCUM_GROUP(54, wro_pipe_events, rw_conflict);
    `MPF_CSR_STAT_ACCUM_GROUP(54, wro_pipe_events, wr_conflict);
    `MPF_CSR_STAT_ACCUM_GROUP(54, wro_pipe_events, ww_conflict);

    always_ff @(posedge clk)
    begin
        rd_valid <= shim_addr_match;

        case (mmio_addr_local)
            // DFH
          LOCAL_ADDR_BITS'(0):
            rd_data <= ccip_dfh_genDFH(MMIO_NEXT_ADDR - MMIO_SHIM_ADDR - DFH_MMIO_BASE_ADDR,
                                       MPF_INSTANCE_ID,
                                       MMIO_NEXT_ADDR == 0);
            // BBB ID
          LOCAL_ADDR_BITS'(1):
            rd_data <= shim_uuid[63:0];
          LOCAL_ADDR_BITS'(2):
            rd_data <= shim_uuid[127:64];

            // CSRs
          `MPF_CSR_IDX(CCI_MPF_WRO_CSR_STAT_RR_CONFLICT):
            rd_data <= 64'(wro_pipe_events_rr_conflict_accum);
          `MPF_CSR_IDX(CCI_MPF_WRO_CSR_STAT_RW_CONFLICT):
            rd_data <= 64'(wro_pipe_events_rw_conflict_accum);
          `MPF_CSR_IDX(CCI_MPF_WRO_CSR_STAT_WR_CONFLICT):
            rd_data <= 64'(wro_pipe_events_wr_conflict_accum);
          `MPF_CSR_IDX(CCI_MPF_WRO_CSR_STAT_WW_CONFLICT):
            rd_data <= 64'(wro_pipe_events_ww_conflict_accum);

          default:
            rd_data <= 64'b0;
        endcase
    end

    //
    // CSR writes
    //
    always_ff @(posedge clk)
    begin
        // Inval page held only one cycle
        wro_ctrl <= wr_data_q;
        wro_ctrl_valid <=
            shim_wr_valid &&
            (mmio_addr_local_q == `MPF_CSR_IDX(CCI_MPF_WRO_CSR_CTRL_REG));

        if (reset)
        begin
            wro_ctrl_valid <= 1'b0;
        end
    end

endmodule // cci_mpf_shim_csr_pwrite


module cci_mpf_shim_csr_rsp_order
  #(
    parameter MPF_ENABLE_SHIM = 0,
    parameter MPF_INSTANCE_ID = 0,

    // Byte addresses
    parameter MMIO_SHIM_ADDR = 0,    // Address offset within MPF CSR space
    parameter MMIO_SHIM_SIZE = 0,
    parameter DFH_MMIO_BASE_ADDR,    // Base MMIO address of MPF CSR space
    parameter MMIO_NEXT_ADDR = 0,

    // Address bits in t_mpf_mmio_addr (64-bit word address in MPF CSR range)
    parameter N_ADDR_BITS = 0
    )
   (
    input  logic clk,
    input  logic reset,

    input  logic mmioWrValid,
    input  logic [N_ADDR_BITS-1 : 0] mmio_addr,
    input  logic [63:0] wr_data,

    // CSR read value in each cycle following mmio_addr. rd_valid is set as long as
    // mmio_addr matches this module's CSR range. There is no mmioRdValid trigger.
    // The parent module module is responsible for gating reads from mmioRdValid.
    output logic rd_valid,
    output logic [63:0] rd_data
    );

    `MPF_CSR_SHIM_STD_PROLOG(128'h4c9c96f4_65ba_4dd8_b383_c70ace57bfe4);

    always_ff @(posedge clk)
    begin
        rd_valid <= shim_addr_match;

        case (mmio_addr_local)
            // DFH
          LOCAL_ADDR_BITS'(0):
            rd_data <= ccip_dfh_genDFH(MMIO_NEXT_ADDR - MMIO_SHIM_ADDR - DFH_MMIO_BASE_ADDR,
                                       MPF_INSTANCE_ID,
                                       MMIO_NEXT_ADDR == 0);
            // BBB ID
          LOCAL_ADDR_BITS'(1):
            rd_data <= shim_uuid[63:0];
          LOCAL_ADDR_BITS'(2):
            rd_data <= shim_uuid[127:64];

          default:
            rd_data <= 64'b0;
        endcase
    end

endmodule // cci_mpf_shim_csr_rsp_order


module cci_mpf_shim_csr_latency_qos
  #(
    parameter MPF_ENABLE_SHIM = 0,
    parameter MPF_INSTANCE_ID = 0,

    // Byte addresses
    parameter MMIO_SHIM_ADDR = 0,    // Address offset within MPF CSR space
    parameter MMIO_SHIM_SIZE = 0,
    parameter DFH_MMIO_BASE_ADDR,    // Base MMIO address of MPF CSR space
    parameter MMIO_NEXT_ADDR = 0,

    // Address bits in t_mpf_mmio_addr (64-bit word address in MPF CSR range)
    parameter N_ADDR_BITS = 0
    )
   (
    input  logic clk,
    input  logic reset,

    input  logic mmioWrValid,
    input  logic [N_ADDR_BITS-1 : 0] mmio_addr,
    input  logic [63:0] wr_data,

    // CSR read value in each cycle following mmio_addr. rd_valid is set as long as
    // mmio_addr matches this module's CSR range. There is no mmioRdValid trigger.
    // The parent module module is responsible for gating reads from mmioRdValid.
    output logic rd_valid,
    output logic [63:0] rd_data,

    output logic [63:0] latency_qos_ctrl,
    output logic latency_qos_ctrl_valid
    );

    `MPF_CSR_SHIM_STD_PROLOG(128'hb35138f6_ea39_4603_9412_a4cf1a999c49);

    always_ff @(posedge clk)
    begin
        rd_valid <= shim_addr_match;

        case (mmio_addr_local)
            // DFH
          LOCAL_ADDR_BITS'(0):
            rd_data <= ccip_dfh_genDFH(MMIO_NEXT_ADDR - MMIO_SHIM_ADDR - DFH_MMIO_BASE_ADDR,
                                       MPF_INSTANCE_ID,
                                       MMIO_NEXT_ADDR == 0);
            // BBB ID
          LOCAL_ADDR_BITS'(1):
            rd_data <= shim_uuid[63:0];
          LOCAL_ADDR_BITS'(2):
            rd_data <= shim_uuid[127:64];

          default:
            rd_data <= 64'b0;
        endcase
    end

    //
    // CSR writes
    //
    always_ff @(posedge clk)
    begin
        // Inval page held only one cycle
        latency_qos_ctrl <= wr_data_q;
        latency_qos_ctrl_valid <=
            shim_wr_valid &&
            (mmio_addr_local_q == `MPF_CSR_IDX(CCI_MPF_LATENCY_QOS_CSR_CTRL_REG));

        if (reset)
        begin
            latency_qos_ctrl_valid <= 1'b0;
        end
    end

endmodule // cci_mpf_shim_csr_latency_qos


module cci_mpf_shim_csr_pwrite
  #(
    parameter MPF_ENABLE_SHIM = 0,
    parameter MPF_INSTANCE_ID = 0,

    // Byte addresses
    parameter MMIO_SHIM_ADDR = 0,    // Address offset within MPF CSR space
    parameter MMIO_SHIM_SIZE = 0,
    parameter DFH_MMIO_BASE_ADDR,    // Base MMIO address of MPF CSR space
    parameter MMIO_NEXT_ADDR = 0,

    // Address bits in t_mpf_mmio_addr (64-bit word address in MPF CSR range)
    parameter N_ADDR_BITS = 0
    )
   (
    input  logic clk,
    input  logic reset,

    input  logic mmioWrValid,
    input  logic [N_ADDR_BITS-1 : 0] mmio_addr,
    input  logic [63:0] wr_data,

    // CSR read value in each cycle following mmio_addr. rd_valid is set as long as
    // mmio_addr matches this module's CSR range. There is no mmioRdValid trigger.
    // The parent module module is responsible for gating reads from mmioRdValid.
    output logic rd_valid,
    output logic [63:0] rd_data,

    input  logic pwrite_out_event_pwrite
    );

    `MPF_CSR_SHIM_STD_PROLOG(128'h9bdbbcaf_2c5a_4d17_a636_75b19a0b4f5c);

    `MPF_CSR_STAT_ACCUM(54, pwrite_out_event_pwrite);

    always_ff @(posedge clk)
    begin
        rd_valid <= shim_addr_match;

        case (mmio_addr_local)
            // DFH
          LOCAL_ADDR_BITS'(0):
            rd_data <= ccip_dfh_genDFH(MMIO_NEXT_ADDR - MMIO_SHIM_ADDR - DFH_MMIO_BASE_ADDR,
                                       MPF_INSTANCE_ID,
                                       MMIO_NEXT_ADDR == 0);
            // BBB ID
          LOCAL_ADDR_BITS'(1):
            rd_data <= shim_uuid[63:0];
          LOCAL_ADDR_BITS'(2):
            rd_data <= shim_uuid[127:64];

            // CSRs
          `MPF_CSR_IDX(CCI_MPF_PWRITE_CSR_STAT_NUM_PWRITES):
            rd_data <= 64'(pwrite_out_event_pwrite_accum);

          default:
            rd_data <= 64'b0;
        endcase
    end

endmodule // cci_mpf_shim_csr_pwrite
