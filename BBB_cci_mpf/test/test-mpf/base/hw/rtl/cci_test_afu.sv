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

`include "cci_mpf_if.vh"
`include "cci_mpf_platform.vh"
`include "cci_mpf_test_conf_default.vh"
`include "cci_test_csrs.vh"

module ofs_plat_afu
   (
    // All platform wires, wrapped in one interface.
    ofs_plat_if plat_ifc
    );

    // ====================================================================
    //
    //  Get a CCI-P port from the platform.
    //
    // ====================================================================

    // Instance of a CCI-P interface. The interface wraps usual CCI-P
    // sRx and sTx structs as well as the associated clock and reset.
    ofs_plat_host_ccip_if ccip_fiu_if();

    // Use the platform-provided module to map the primary host interface
    // to CCI-P. The "primary" interface is the port that includes the
    // main OPAE-managed MMIO connection.
    ofs_plat_host_chan_as_ccip
      #(
`ifdef TEST_PARAM_AFU_CLK
        .ADD_CLOCK_CROSSING(1)
`endif
        )
      primary_ccip
       (
        .to_fiu(plat_ifc.host_chan.ports[0]),
        .to_afu(ccip_fiu_if),

`ifdef TEST_PARAM_AFU_CLK
        .afu_clk(`TEST_PARAM_AFU_CLK.clk),
        .afu_reset_n(`TEST_PARAM_AFU_CLK.reset_n)
`else
        .afu_clk(),
        .afu_reset_n()
`endif
        );

    logic afu_clk;
    assign afu_clk = ccip_fiu_if.clk;

    // pwrState in afu_clk domain
    logic [1:0] pwrState;
    ofs_plat_prim_clock_crossing_reg
      #(
        .WIDTH(2)
        )
      pwrState_cross
       (
        .clk_src(plat_ifc.host_chan.ports[0].clk),
        .clk_dst(afu_clk),
        .r_in(plat_ifc.pwrState),
        .r_out(pwrState)
        );


    // ====================================================================
    //
    //  Tie off unused ports.
    //
    // ====================================================================

    ofs_plat_if_tie_off_unused
      #(
        .HOST_CHAN_IN_USE_MASK(1)
        )
        tie_off(plat_ifc);


    // ====================================================================
    //
    //  Convert the external wires to an MPF interface.
    //
    // ====================================================================

    //
    // MPF represents CCI as a SystemVerilog interface, derived from the
    // same basic types defined in ccip_if_pkg.  Interfaces reduce the
    // number of internal MPF module parameters, since each internal MPF
    // shim has a bus connected toward the AFU and a bus connected toward
    // the FIU.
    //

    //
    // Expose FIU as an MPF interface
    //
    cci_mpf_if#(.ENABLE_LOG(1)) mpf_fiu_if(.clk(afu_clk));

    ofs_plat_ccip_if_to_mpf
      #(
        // All inputs and outputs in PR region (AFU) must be registered!
        .REGISTER_INPUTS(1),
        .REGISTER_OUTPUTS(1)
        )
      map_ifc
       (
        .ofs_ccip(ccip_fiu_if),
        .mpf_ccip(mpf_fiu_if)
        );


    // ====================================================================
    //
    //  Add flow control to the FIU by adding control over the almost full
    //  wires.  This is used by some tests to limit the number of requests
    //  outstanding in the FIU.
    //
    // ====================================================================

    cci_mpf_if fiu_flow(.clk(afu_clk));
    logic c0_force_almost_full;
    logic c1_force_almost_full;

    always_comb
    begin
        fiu_flow.reset = mpf_fiu_if.reset;

        fiu_flow.c0TxAlmFull = mpf_fiu_if.c0TxAlmFull || c0_force_almost_full;
        fiu_flow.c1TxAlmFull = mpf_fiu_if.c1TxAlmFull || c1_force_almost_full;

        fiu_flow.c0Rx = mpf_fiu_if.c0Rx;
        fiu_flow.c1Rx = mpf_fiu_if.c1Rx;

        mpf_fiu_if.c0Tx = fiu_flow.c0Tx;
        mpf_fiu_if.c1Tx = fiu_flow.c1Tx;
        mpf_fiu_if.c2Tx = fiu_flow.c2Tx;
    end


    // ====================================================================
    //
    //  Manage CSRs at the lowest level so they can observe the edge state
    //  and to keep them available even when other code fails.
    //
    // ====================================================================

    //
    // The AFU exposes the primary AFU device feature header (DFH) at MMIO
    // address 0.  MPF defines a set of its own DFHs.  The AFU must
    // build its feature chain to point to the MPF chain.  The AFU must
    // also tell the MPF module the MMIO address at which MPF should start
    // its feature chain.
    //
`ifndef MPF_DISABLED
    localparam MPF_DFH_MMIO_ADDR = 'h1000;
`else
    localparam MPF_DFH_MMIO_ADDR = 0;
`endif

    cci_mpf_if afu_csrs(.clk(afu_clk));
    test_csrs csrs();

    cci_test_csrs
      #(
        .NEXT_DFH_BYTE_OFFSET(MPF_DFH_MMIO_ADDR)
        )
      csr_io
       (
        .clk(afu_clk),
        .pClk(plat_ifc.clocks.pClk.clk),
        .fiu(fiu_flow),
        .afu(afu_csrs),
        .pck_cp2af_pwrState(pwrState),
        .pck_cp2af_error(ccip_fiu_if.error),
        .csrs
        );


    // ====================================================================
    //
    //  Instantiate a memory properties factory (MPF) between the external
    //  interface and the AFU, adding support for virtual memory and
    //  control over memory ordering.
    //
    // ====================================================================

    cci_mpf_if#(.ENABLE_LOG(1)) afu(.clk(afu_clk));

    logic c0NotEmpty;
    logic c1NotEmpty;

`ifndef MPF_DISABLED

    cci_mpf
      #(
        // Should read responses be returned in the same order that
        // the reads were requested?
        .SORT_READ_RESPONSES(`MPF_CONF_SORT_READ_RESPONSES),

        // Should the Mdata from write requests be returned in write
        // responses?  If the AFU is simply counting write responses
        // and isn't consuming Mdata, then setting this to 0 eliminates
        // the memory and logic inside MPF for preserving Mdata.
        .PRESERVE_WRITE_MDATA(`MPF_CONF_PRESERVE_WRITE_MDATA),

        // Enable virtual to physical translation?  When enabled, MPF
        // accepts requests with either virtual or physical addresses.
        // Virtual addresses are indicated by setting the
        // addrIsVirtual flag in the MPF extended Tx channel
        // request header.
        .ENABLE_VTP(`MPF_CONF_ENABLE_VTP),

  `ifdef MPF_CONF_VTP_PT_MODE_HARDWARE_WALKER
        .VTP_PT_MODE("HARDWARE_WALKER"),
  `elsif MPF_CONF_VTP_PT_MODE_SOFTWARE_SERVICE
        .VTP_PT_MODE("SOFTWARE_SERVICE"),
  `endif

        // Enable mapping of eVC_VA to physical channels?  AFUs that both use
        // eVC_VA and read back memory locations written by the AFU must either
        // emit WrFence on VA or use explicit physical channels and enforce
        // write/read order.  Each method has tradeoffs.  WrFence VA is expensive
        // and should be emitted only infrequently.  Memory requests to eVC_VA
        // may have higher bandwidth than explicit mapping.  The MPF module for
        // physical channel mapping is optimized for each CCI platform.
        //
        // If you set ENFORCE_WR_ORDER below you probably also want to set
        // ENABLE_VC_MAP.
        //
        // The mapVAtoPhysChannel extended header bit must be set on each
        // request to enable mapping.
        .ENABLE_VC_MAP(`MPF_CONF_ENABLE_VC_MAP),
        // When ENABLE_VC_MAP is set the mapping is either static for the entire
        // run or dynamic, changing in response to traffic patterns.  The mapper
        // guarantees synchronization when the mapping changes by emitting a
        // WrFence on eVC_VA and draining all reads.  Ignored when ENABLE_VC_MAP
        // is 0.
        .ENABLE_DYNAMIC_VC_MAPPING(`MPF_CONF_ENABLE_DYNAMIC_VC_MAPPING),

        // Manage traffic to reduce latency without sacrificing bandwidth?
        // The blue bitstream buffers for a given channel may be larger than
        // necessary to sustain full bandwidth.  Allowing more requests beyond
        // this threshold to enter the channel increases latency without
        // increasing bandwidth.  While this is fine for some applications,
        // those with multiple kernels connected to the CCI memory interface
        // may see performance gains when a kernel's performance is a
        // latency-sensitive.
        .ENABLE_LATENCY_QOS(`MPF_CONF_ENABLE_LATENCY_QOS),

        // Should write/write and write/read ordering within a cache
        // be enforced?  By default CCI makes no guarantees on the order
        // in which operations to the same cache line return.  Setting
        // this to 1 adds logic to filter reads and writes to ensure
        // that writes retire in order and the reads correspond to the
        // most recent write.
        //
        // ***  Even when set to 1, MPF guarantees order only within
        // ***  a given virtual channel.  There is no guarantee of
        // ***  order across virtual channels and no guarantee when
        // ***  using eVC_VA, since it spreads requests across all
        // ***  channels.  Synchronizing writes across virtual channels
        // ***  can be accomplished only by requesting a write fence on
        // ***  eVC_VA.  Syncronizing writes across virtual channels
        // ***  and then reading back the same data requires both
        // ***  requesting a write fence on eVC_VA and waiting for the
        // ***  corresponding write fence response.
        //
        .ENFORCE_WR_ORDER(`MPF_CONF_ENFORCE_WR_ORDER),

        // Enable partial write emulation.  The original CCI-P standard
        // had no support for partial writes.  MPF can emulate partial
        // writes using read-modify-write.  The original MPF encoding
        // was a byte-level mask, one bit per byte.  CCI-P has since
        // added an encoding for partial writes, but the encoding supports
        // only a contiguous range of bytes -- a limitation imposed by
        // PCIe.  MPF supports either encoding, depending on the setting
        // of PARTIAL_WRITE_MODE below.
        //
        // NOTE: When PARTIAL_WRITE_MODE is set to BYTE_RANGE and the
        // platform supports CCI-P with byte ranges, partial write emulation
        // in MPF is automatically disabled even when ENABLE_PARTIAL_WRITES
        // is set.  This behavior allows an AFU to set ENABLE_PARTIAL_WRITES
        // and MPF will automatically either emulate the behavior or pass
        // the request to the FIU, as appropriate.
        //
        // In emulation mode, when coupled with ENFORCE_WR_ORDER, partial
        // writes are free of races on the FPGA side.  Due to the read-modify-
        // write in the emulation, there are no guarantees of atomicity and
        // there is no protection against races with CPU-generates writes.
        .ENABLE_PARTIAL_WRITES(`MPF_CONF_ENABLE_PARTIAL_WRITES),
        // CCI-P added partial write encoding.  Use "BYTE_MASK" for the
        // original MPF mask -- one bit per byte.  Use "BYTE_RANGE" for the
        // CCI-P native encoding using byte_start/byte_len.
        .PARTIAL_WRITE_MODE(`MPF_CONF_PARTIAL_WRITE_MODE),

        // Experimental:  Merge nearby reads from the same address?  Some
        // applications generate reads to the same line within a few cycles
        // of each other.  This module reduces the requests to single host
        // read and replicates the result.  The module requires a wide
        // block RAM FIFO, so should not be enabled without some thought.
        .MERGE_DUPLICATE_READS(`MPF_CONF_MERGE_DUPLICATE_READS),

        // Address of the MPF feature header.  See comment above.
        .DFH_MMIO_BASE_ADDR(MPF_DFH_MMIO_ADDR)
        )
      mpf
       (
        .clk(afu_clk),
        .fiu(afu_csrs),
        .afu,
        .c0NotEmpty,
        .c1NotEmpty
        );

`else // !`ifndef MPF_DISABLED

    // Not using MPF.  Inject a dummy instance that passes the signals
    // through and generates the not empty signals.
    cci_mpf_null
      mpf_null
       (
        .clk(afu_clk),
        .fiu(afu_csrs),
        .afu,
        .c0NotEmpty,
        .c1NotEmpty
        );

`endif // !`ifndef MPF_DISABLED

    // ====================================================================
    //
    //  Optional active line tracking and flow control.
    //
    // ====================================================================

`ifdef CCI_TEST_FLOW_CONTROL

    localparam MAX_ACTIVE_LINES = ccip_cfg_pkg::C0_MAX_BW_ACTIVE_LINES[0];
    localparam MAX_ACTIVE_WRFENCES = CCI_TX_ALMOST_FULL_THRESHOLD * 2;

    typedef logic [$clog2(MAX_ACTIVE_LINES) : 0] t_active_cnt;
    t_active_cnt c0_num_fiu_active, c1_num_fiu_active;

    cci_mpf_prim_track_active_reqs
      #(
        .MAX_ACTIVE_LINES(MAX_ACTIVE_LINES),
        .MAX_ACTIVE_WRFENCES(MAX_ACTIVE_WRFENCES)
        )
      tracker
       (
        .clk(afu_clk),

        .cci_bus(mpf_fiu_if),

        .c0NotEmpty(),
        .c1NotEmpty(),
        .c0ActiveLines(c0_num_fiu_active),
        .c1ActiveLines(c1_num_fiu_active),
        .c1ActiveWrFences()
        );

`else

    assign c0_force_almost_full = 1'b0;
    assign c1_force_almost_full = 1'b0;

`endif

    // ====================================================================
    //
    //  Instantiate the test.
    //
    // ====================================================================

    test_afu
`ifdef CCI_TEST_FLOW_CONTROL
      #(
        .MAX_ACTIVE_LINES(MAX_ACTIVE_LINES)
        )
`endif
      test
       (
        .clk(afu_clk),
        .fiu(afu),
        .csrs,
`ifdef CCI_TEST_FLOW_CONTROL
        .c0ActiveLines(c0_num_fiu_active),
        .c1ActiveLines(c1_num_fiu_active),
        .c0ForceAlmFull(c0_force_almost_full),
        .c1ForceAlmFull(c1_force_almost_full),
`endif
        .c0NotEmpty,
        .c1NotEmpty
        );

endmodule
