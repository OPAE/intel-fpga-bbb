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

//
// Add an MPF pipeline, including VTP, to the primary CCI-P interface.
// Add a separate VTP service to the G1 ports, if present. Use virtual
// addresses in the test engine.
//

`include "ofs_plat_if.vh"
`include "cci_mpf_if.vh"

module afu
  #(
    parameter NUM_PORTS_G1 = 0,
    parameter string HOST_MEM_G1_ADDRESS_SPACE = "IOADDR"
    )
   (
    // Primary host interface
    ofs_plat_host_ccip_if.to_fiu host_ccip_if,

    // Secondary host memory interface (as Avalon). Zero length vectors are illegal.
    // Force minimum size 1 dummy entry in case no secondary ports exist.
    ofs_plat_avalon_mem_if.to_sink host_mem_g1_if[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1],

    // pClk is used to compute the frequency of the AFU's clk, since pClk
    // is a known frequency.
    input  logic pClk,

    // AFU Power State
    input  t_ofs_plat_power_state pwrState
    );

    logic clk;
    assign clk = host_ccip_if.clk;
    logic reset_n;
    assign reset_n = host_ccip_if.reset_n;

    localparam NUM_PORTS_G0 = 1;
    localparam NUM_ENGINES = NUM_PORTS_G0 + NUM_PORTS_G1;

    // Byte address of MPF's CSRs
    localparam PRIMARY_MPF_MMIO_BASE_ADDR = 'h5000;


    // ====================================================================
    //
    //  Instantiate the VTP service for use by the host channel.
    //  The VTP service is an OFS CCI-P to OFS CCI-P shim that injects
    //  MMIO and page table traffic into the interface. The VTP
    //  translation ports are a separate interface that will be passed
    //  to the AFU memory engines.
    //
    // ====================================================================

    // One port for each of read and write ports
    localparam N_VTP_PORTS = (NUM_PORTS_G1 > 0) ? NUM_PORTS_G1 * 2 : 1;
    mpf_vtp_port_if vtp_ports[N_VTP_PORTS]();

    // Byte address of VTP CSRs
    localparam VTP_MMIO_BASE_ADDR = 'h4000;
    localparam AFU_NEXT_MMIO_ADDR = (NUM_PORTS_G1 > 0 ? VTP_MMIO_BASE_ADDR :
                                                        PRIMARY_MPF_MMIO_BASE_ADDR);

    ofs_plat_host_ccip_if afu_ccip_if();

    generate
        if (NUM_PORTS_G1 > 0)
        begin : v
            mpf_vtp_svc_ofs_ccip
              #(
                // Use a unique MPF instance ID for the group 1 VTP service.
                // The primary MPF instance ID on the main CCI-P port is 1.
                .MPF_INSTANCE_ID(2),
                .VTP_ADDR_MODE(HOST_MEM_G1_ADDRESS_SPACE),
                // VTP's CSR byte address. The AFU will add this address to
                // the feature list.
                .DFH_MMIO_BASE_ADDR(VTP_MMIO_BASE_ADDR),
                .DFH_MMIO_NEXT_ADDR(PRIMARY_MPF_MMIO_BASE_ADDR),
                .N_VTP_PORTS(N_VTP_PORTS),
                // The primary MPF instance (cci_mpf below) uses mdata bit
                // CCIP_MDATA_WIDTH-2 to signal internal DMA requests, but
                // guarantees never to set both CCIP_MDATA_WIDTH-2 and -3.
                // This VTP instance uses those two bits together to mark
                // internal DMA requests.
                .MDATA_TAG_MASK('b11 << (CCIP_MDATA_WIDTH-3))
                )
              vtp_svc
               (
                .to_fiu(host_ccip_if),
                .to_afu(afu_ccip_if),
                .vtp_ports
                );
        end
        else
        begin : nv
            // VTP not needed. Don't use the shim -- just wire to the next
            // CCI-P stage.
            ofs_plat_ccip_if_connect conn_mpf(.to_fiu(host_ccip_if), .to_afu(afu_ccip_if));
        end
    endgenerate


    // ====================================================================
    //
    //  Instantiate MPF on the primary port. MPF will provide a separate
    //  VTP service here as well as memory property shims, such as
    //  response ordering.
    //
    // ====================================================================

    cci_mpf_if#(.ENABLE_LOG(1)) mpf_to_fiu(.clk);
    cci_mpf_if#(.ENABLE_LOG(1)) mpf_to_afu(.clk);

    // Map OFS CCI-P to MPF's interface
    ofs_plat_ccip_if_to_mpf
      #(
        // CCI-P interface is already registered by the OFS PIM
        .REGISTER_INPUTS(0),
        .REGISTER_OUTPUTS(0)
        )
      map_ifc
       (
        .ofs_ccip(afu_ccip_if),
        .mpf_ccip(mpf_to_fiu)
        );


    // Intermediate MPF interface to manage VTP failures on the primary
    // CCI-P port. If VTP is expected to succeed for every translation
    // request then keep VTP_HALT_ON_FAILURE at its default (1) and
    // mpf_xlate_if is not needed. cci_mpf below could connect directly
    // to mpf_to_fiu instead of mpf_xlate_if.
    cci_mpf_if mpf_xlate_if(.clk);
    logic [63:0] csr_mpf_c0_vtp_fail_va;
    logic [15:0] csr_mpf_c0_vtp_fail_cnt;
    logic [63:0] csr_mpf_c1_vtp_fail_va;
    logic [15:0] csr_mpf_c1_vtp_fail_cnt;

    dummy_failed_mpf_ccip_shim ccip_failed_shim
       (
        .clk,
        .to_fiu(mpf_to_fiu),
        .to_afu(mpf_xlate_if),

        // Statistics
        .csr_mpf_c0_vtp_fail_va,
        .csr_mpf_c0_vtp_fail_cnt,
        .csr_mpf_c1_vtp_fail_va,
        .csr_mpf_c1_vtp_fail_cnt
        );


    cci_mpf
      #(
        .DFH_MMIO_BASE_ADDR(PRIMARY_MPF_MMIO_BASE_ADDR),
        // MPF terminates the feature list
        .DFH_MMIO_NEXT_ADDR(0),

        // Enable virtual to physical translation
        .ENABLE_VTP(1),
        // Don't halt VTP on translation failure. Let the AFU deal with
        // untranslatable addresses.
        .VTP_HALT_ON_FAILURE(0),

        // VC map is used only on older platforms with multiple physical
        // channels mapped to one logical CCI-P port. VC map is required
        // when ENFORCE_WR_ORDER is set, so it is enabled here.
        .ENABLE_VC_MAP(1),

        // Enforce write/write and write/read ordering with cache lines
        .ENFORCE_WR_ORDER(1),

        // Return read responses in the order they were requested
        .SORT_READ_RESPONSES(1),

        // Preserve Mdata field in write requests.
        .PRESERVE_WRITE_MDATA(1)
        )
      mpf_primary
       (
        .clk,
        .fiu(mpf_xlate_if),
        .afu(mpf_to_afu),
        .c0NotEmpty(),
        .c1NotEmpty()
        );


    // ====================================================================
    //
    //  Split the MPF AFU interface into separate host memory and MMIO
    //  interfaces.
    //
    // ====================================================================

    cci_mpf_if#(.ENABLE_LOG(1)) mpf_host_mem(.clk);
    cci_mpf_if#(.ENABLE_LOG(1)) mpf_mmio(.clk);

    mpf_if_split_mmio split_mmio
       (
        .clk,
        .to_fiu(mpf_to_afu),
        .host_mem(mpf_host_mem),
        .mmio(mpf_mmio)
        );


    // ====================================================================
    //
    //  Global CSRs (mostly to tell SW about the AFU configuration)
    //
    // ====================================================================

    engine_csr_if eng_csr_glob();
    engine_csr_if eng_csr[NUM_ENGINES]();

    // Unique ID for this test
    logic [127:0] test_id = 128'h9dcf6fcd_3699_4979_956a_666f7cff59d6;

    logic [63:0] csr_g1_rd_vtp_fail_va;
    logic [15:0] csr_g1_rd_vtp_fail_cnt;
    logic [63:0] csr_g1_wr_vtp_fail_va;
    logic [15:0] csr_g1_wr_vtp_fail_cnt;

    always_comb
    begin
        eng_csr_glob.rd_data[0] = test_id[63:0];
        eng_csr_glob.rd_data[1] = test_id[127:64];
        eng_csr_glob.rd_data[2] = { 48'd0, 8'(NUM_PORTS_G1), 8'(NUM_PORTS_G0) };

        // Store the most recent VTP translation failure address on the primary
        // CCI-P port in global CSRs 3 (read) and 4 (write).
        eng_csr_glob.rd_data[3] = csr_mpf_c0_vtp_fail_va;
        eng_csr_glob.rd_data[4] = csr_mpf_c1_vtp_fail_va;

        // Store the most recent VTP translation failure address on group 1
        // ports in global CSRs 5 (read) and 6 (write). All ports share the
        // same two registers.
        eng_csr_glob.rd_data[5] = csr_g1_rd_vtp_fail_va;
        eng_csr_glob.rd_data[6] = csr_g1_wr_vtp_fail_va;

        // Count of VTP failure flits. Group 1 counts at most one per cycle,
        // so could undercount.
        eng_csr_glob.rd_data[7] = { csr_g1_wr_vtp_fail_cnt, csr_g1_rd_vtp_fail_cnt,
                                    csr_mpf_c1_vtp_fail_cnt, csr_mpf_c0_vtp_fail_cnt };

        for (int e = 8; e < eng_csr_glob.NUM_CSRS; e = e + 1)
        begin
            eng_csr_glob.rd_data[e] = 64'(0);
        end

        // This signal means nothing
        eng_csr_glob.status_active = 1'b0;
    end


    // ====================================================================
    //
    //  Engine for primary interface (the one routed through MPF)
    //
    // ====================================================================

    // Convert the MPF interface to a normal OFS CCI-P interface
    ofs_plat_host_ccip_if
      #(
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
      host_mem_va_if();

    t_cci_mpf_ReqMemHdrExt cTx_ext;

    // MPF extension header, used for things like requesting virtual to
    // physical translation. This must be passed in along with the
    // generic OFS CCI-P interface in order to configure MPF requests.
    always_comb
    begin
        cTx_ext = '0;
        cTx_ext.addrIsVirtual = 1'b1;
    end

    mpf_if_to_ofs_plat_ccip hm
       (
        .clk,
        .error(host_ccip_if.error),
        .mpf_ccip(mpf_host_mem),
        .ofs_ccip(host_mem_va_if),
        .c0Tx_ext(cTx_ext),
        .c1Tx_ext(cTx_ext),
        // MPF partial writes not used in this test
        .c1Tx_pwrite('0)
        );

    // Don't track host channel low-level events
    host_chan_events_if host_chan_events();
    host_chan_events_none n(.events(host_chan_events));

    host_mem_rdwr_engine_ccip
      #(
        .ENGINE_NUMBER(0)
        )
      eng
       (
        .host_mem_if(host_mem_va_if),
        .host_chan_events_if(host_chan_events),
        .csrs(eng_csr[0])
        );

    // Successfully translated requests will be routed to host_mem_g1_if.
    // Here, we add a separate Avalon interface to which failed translations
    // will be routed. The code here only detects the failure and routes it
    // to host_mem_failed_if, where it is noted and dumped on the floor.
    // A real handler would route the requests somewhere, perhaps to
    // an interface with a different memory space.
    ofs_plat_avalon_mem_if
      #(
        `OFS_PLAT_AVALON_MEM_IF_REPLICATE_PARAMS(host_mem_g1_if[0]),
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
      host_mem_g1_failed_if[NUM_PORTS_G1 > 0 ? NUM_PORTS_G1 : 1]();

    genvar p;
    generate
        // Instantiate traffic generators for the group 1 ports
        for (p = 0; p < NUM_PORTS_G1; p = p + 1)
        begin : g1
            g1_worker
              #(
`ifdef OFS_PLAT_PARAM_HOST_CHAN_G1_IS_NATIVE_AVALON
                // Simple Avalon ports don't support write fences
                .WRITE_FENCE_SUPPORTED(0),
`endif
                .ENGINE_NUMBER(NUM_PORTS_G0 + p)
                )
              wrk
               (
                .host_mem_if(host_mem_g1_if[p]),
                .host_mem_failed_if(host_mem_g1_failed_if[p]),
                .csrs(eng_csr[NUM_PORTS_G0 + p]),

                .vtp_ports(vtp_ports[p*2 : p*2+1])
                );

            assign host_mem_g1_failed_if[p].clk = host_mem_g1_if[p].clk;
            assign host_mem_g1_failed_if[p].reset_n = host_mem_g1_if[p].reset_n;
            assign host_mem_g1_failed_if[p].instance_number = host_mem_g1_if[p].instance_number;
        end
    endgenerate

    //
    // Note VTP translation failures. A real implementation that handles
    // translation failures would have to be much smarter than this.
    //
    dummy_failed_g1_sinks
      #(
        .NUM_PORTS_G1(NUM_PORTS_G1)
        )
      g1_failed_sinks
       (
        .host_mem_g1_failed_if,

        // Statistics
        .csr_g1_rd_vtp_fail_va,
        .csr_g1_rd_vtp_fail_cnt,
        .csr_g1_wr_vtp_fail_va,
        .csr_g1_wr_vtp_fail_cnt
        );


    // ====================================================================
    //
    //  Instantiate control via CSRs
    //
    // ====================================================================

    t_ccip_c0_ReqMmioHdr mmio_hdr;
    assign mmio_hdr = t_ccip_c0_ReqMmioHdr'(mpf_mmio.c0Rx.hdr);

    // Tie off unused Tx ports
    assign mpf_mmio.c0Tx = '0;
    assign mpf_mmio.c1Tx = '0;

    csr_mgr
      #(
        .NUM_ENGINES(NUM_ENGINES),
        .DFH_MMIO_NEXT_ADDR(AFU_NEXT_MMIO_ADDR),
        // Convert to QWORD index space (drop the low address bit)
        .MMIO_ADDR_WIDTH(CCIP_MMIOADDR_WIDTH - 1)
        )
      csr_mgr
       (
        .clk(mpf_mmio.clk),
        .reset_n(!mpf_mmio.reset),
        .pClk,

        .wr_write(mpf_mmio.c0Rx.mmioWrValid),
        .wr_address(mmio_hdr.address[CCIP_MMIOADDR_WIDTH-1 : 1]),
        .wr_writedata(mpf_mmio.c0Rx.data[63:0]),

        .rd_read(mpf_mmio.c0Rx.mmioRdValid),
        .rd_address(mmio_hdr.address[CCIP_MMIOADDR_WIDTH-1 : 1]),
        .rd_tid_in(mmio_hdr.tid),
        .rd_readdatavalid(mpf_mmio.c2Tx.mmioRdValid),
        .rd_readdata(mpf_mmio.c2Tx.data),
        .rd_tid_out(mpf_mmio.c2Tx.hdr.tid),

        .eng_csr_glob,
        .eng_csr
        );

endmodule // afu


module g1_worker
  #(
    parameter ENGINE_NUMBER = 0,
    parameter WRITE_FENCE_SUPPORTED = 1
    )
   (
    ofs_plat_avalon_mem_if.to_sink host_mem_if,
    // Failed translations are routed here
    ofs_plat_avalon_mem_if.to_sink host_mem_failed_if,
    engine_csr_if.engine csrs,

    mpf_vtp_port_if.to_slave vtp_ports[2]
    );

    logic clk;
    assign clk = host_mem_if.clk;
    logic reset_n;
    assign reset_n = host_mem_if.reset_n;

    logic vtp_xlate_error;

    // Translated requests, both successful and failed, go first to this
    // host_mem_xlate_if. They will then be routed either to host_mem_if
    // or host_mem_failed_if.
    //
    // NOTE:
    //  This interface and pick_path below are not required if
    //  FAIL_ON_ERROR(1) is set below (the default). In that case, all
    //  translations would have to succeed.
    //  mpf_vtp_translate_ofs_avalon_mem below could then connect
    //  directly to host_mem_if.
    ofs_plat_avalon_mem_if
      #(
        `OFS_PLAT_AVALON_MEM_IF_REPLICATE_PARAMS(host_mem_if)
        )
      host_mem_xlate_if();

    assign host_mem_xlate_if.clk = host_mem_if.clk;
    assign host_mem_xlate_if.reset_n = host_mem_if.reset_n;
    assign host_mem_xlate_if.instance_number = host_mem_if.instance_number;

    // For translations, successful to host_mem_if and failed to
    // host_mem_failed_if. In this toy example, failed translations will
    // be printed and dropped and no responses are expected from
    // host_mem_failed_if.
    fork_avalon_mem pick_path
       (
        .sink0(host_mem_if),
        .sink1(host_mem_failed_if),
        .source(host_mem_xlate_if),
        .pick_path(vtp_xlate_error)
        );

    // Generate a host memory interface that accepts virtual addresses.
    // The code below will connect it to the host_mem_if, which expects
    // IOVAs, performing the translation using the two VTP ports.
    ofs_plat_avalon_mem_if
      #(
        `OFS_PLAT_AVALON_MEM_IF_REPLICATE_PARAMS(host_mem_if),
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
      host_mem_va_if();

    assign host_mem_va_if.clk = host_mem_if.clk;
    assign host_mem_va_if.reset_n = host_mem_if.reset_n;
    assign host_mem_va_if.instance_number = host_mem_if.instance_number;

    mpf_vtp_translate_ofs_avalon_mem
      #(
        .FAIL_ON_ERROR(0)
        )
      vtp
       (
        .host_mem_if(host_mem_xlate_if),
        .host_mem_va_if,
        .error(vtp_xlate_error),
        .vtp_ports
        );

    // The traffic generator expects a split-bus interface. Promote the
    // interface to ofs_plat_avalon_mem_rdwr_if. This is required only for
    // the test and only because host_mem_rdwr_engine_avalon requires it.
    ofs_plat_avalon_mem_rdwr_if
      #(
        `OFS_PLAT_AVALON_MEM_IF_REPLICATE_PARAMS(host_mem_if)
        )
      host_mem_engine_if();

    assign host_mem_engine_if.clk = host_mem_if.clk;
    assign host_mem_engine_if.reset_n = host_mem_if.reset_n;
    assign host_mem_engine_if.instance_number = host_mem_if.instance_number;

    ofs_plat_avalon_mem_rdwr_if_to_mem_if conn_engine
       (
        .mem_sink(host_mem_va_if),
        .mem_source(host_mem_engine_if)
        );

    // Don't track host channel low-level events
    host_chan_events_if host_chan_events();
    host_chan_events_none n(.events(host_chan_events));

    host_mem_rdwr_engine_avalon
      #(
        .ENGINE_NUMBER(ENGINE_NUMBER),
        .ENGINE_GROUP(1),
        .ADDRESS_SPACE("VA"),
        .WRITE_FENCE_SUPPORTED(WRITE_FENCE_SUPPORTED)
        )
      eng
       (
        .host_mem_if(host_mem_engine_if),
        .host_chan_events_if(host_chan_events),
        .csrs
        );

endmodule // g1_worker
