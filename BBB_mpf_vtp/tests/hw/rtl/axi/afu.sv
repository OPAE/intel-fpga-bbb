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
// Add a VTP server to the host memory interface and use virtual addresses
// in the test engine.
//

`include "ofs_plat_if.vh"
`include "cci_mpf_if.vh"

module afu
   (
    // Primary host interface
    ofs_plat_axi_mem_if.to_sink host_mem_if,

    // MMIO (CSR space)
    ofs_plat_axi_mem_lite_if.to_source mmio64_if,

    // pClk is used to compute the frequency of the AFU's clk, since pClk
    // is a known frequency.
    input  logic pClk,

    // AFU Power State
    input  t_ofs_plat_power_state pwrState
    );

    import cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value;

    logic clk;
    assign clk = host_mem_if.clk;
    logic reset_n;
    assign reset_n = host_mem_if.reset_n;

    localparam NUM_ENGINES = 1;

    // The width of the AXI-MM ID fields are narrower on the AFU side
    // of VTP, since VTP uses a bit to flag VTP page table traffic.
    // Drop the high bit of each ID field on the AFU side.
    localparam AFU_RID_WIDTH = host_mem_if.RID_WIDTH_ - 1;
    localparam AFU_WID_WIDTH = host_mem_if.WID_WIDTH_ - 1;

    localparam AFU_USER_WIDTH = host_mem_if.USER_WIDTH_;


    // ====================================================================
    //
    //  Instantiate the VTP service for use by the host channel.
    //  The VTP service is an OFS AXI shim that injects MMIO and page
    //  table traffic into the interface. The VTP translation ports are
    //  a separate interface that will be passed to the AFU memory engines.
    //
    // ====================================================================

    // One port for each of c0Tx and c1Tx
    mpf_vtp_port_if vtp_ports[2]();

    // Byte address of VTP CSRs
    localparam VTP_MMIO_BASE_ADDR = 'h4000;

    // Physical address interface for use by the AFU. This instance
    // will be the AFU side of the VTP service shim. (The service
    // shim injects page table requests. It is does not translate
    // addresses on the memory interfaces. The service shim's VTP
    // ports must be used by the AFU for translation.)
    ofs_plat_axi_mem_if
      #(
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS_EXCEPT_TAGS(host_mem_if),
        .RID_WIDTH(AFU_RID_WIDTH),
        .WID_WIDTH(AFU_WID_WIDTH),
        .USER_WIDTH(AFU_USER_WIDTH),
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
      host_mem_afu_pa_if();

    assign host_mem_afu_pa_if.clk = host_mem_if.clk;
    assign host_mem_afu_pa_if.reset_n = host_mem_if.reset_n;
    assign host_mem_afu_pa_if.instance_number = host_mem_if.instance_number;

    ofs_plat_axi_mem_lite_if
      #(
        `OFS_PLAT_AXI_MEM_LITE_IF_REPLICATE_PARAMS(mmio64_if)
        )
      mmio64_afu_if();

    assign mmio64_afu_if.clk = mmio64_if.clk;
    assign mmio64_afu_if.reset_n = mmio64_if.reset_n;
    assign mmio64_afu_if.instance_number = mmio64_if.instance_number;

    mpf_vtp_svc_ofs_axi_mem
      #(
        // VTP's CSR byte address. The AFU will add this address to
        // the feature list.
        .DFH_MMIO_BASE_ADDR(VTP_MMIO_BASE_ADDR),
        .DFH_MMIO_NEXT_ADDR(0),
        .N_VTP_PORTS(2),
        // The tag must use value not used by the AFU so VTP can identify
        // it's own DMA traffic.
        .RID_TAG_IDX(AFU_RID_WIDTH),
        .WID_TAG_IDX(AFU_WID_WIDTH)
        )
      vtp_svc
       (
        .mem_sink(host_mem_if),
        .mem_source(host_mem_afu_pa_if),

        .mmio64_source(mmio64_if),
        .mmio64_sink(mmio64_afu_if),

        .vtp_ports
        );


    // ====================================================================
    //
    //  Global CSRs (mostly to tell SW about the AFU configuration)
    //
    // ====================================================================

    engine_csr_if eng_csr_glob();
    engine_csr_if eng_csr[NUM_ENGINES]();

    // Unique ID for this test
    logic [127:0] test_id = 128'hf04c218a_7ba3_4c3f_abdd_63f9692b7d1f;

    always_comb
    begin
        eng_csr_glob.rd_data[0] = test_id[63:0];
        eng_csr_glob.rd_data[1] = test_id[127:64];
        // One active port
        eng_csr_glob.rd_data[2] = { 56'd0, 8'(1) };

        for (int e = 3; e < eng_csr_glob.NUM_CSRS; e = e + 1)
        begin
            eng_csr_glob.rd_data[e] = 64'(0);
        end

        // This signal means nothing
        eng_csr_glob.status_active = 1'b0;
    end


    // ====================================================================
    //
    //  Host memory test engine
    //
    // ====================================================================

    // Generate a host memory interface that accepts virtual addresses.
    // The code below will connect it to the host_mem_if, which expects
    // IOVAs, performing the translation using the two VTP ports.
    ofs_plat_axi_mem_if
      #(
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS_EXCEPT_TAGS(host_mem_if),
        .RID_WIDTH(AFU_RID_WIDTH),
        .WID_WIDTH(AFU_WID_WIDTH),
        .USER_WIDTH(AFU_USER_WIDTH),
        .LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)
        )
      host_mem_afu_va_if();

    assign host_mem_afu_va_if.clk = host_mem_if.clk;
    assign host_mem_afu_va_if.reset_n = host_mem_if.reset_n;
    assign host_mem_afu_va_if.instance_number = host_mem_if.instance_number;

    mpf_vtp_translate_ofs_axi_mem vtp
       (
        .host_mem_if(host_mem_afu_pa_if),
        .host_mem_va_if(host_mem_afu_va_if),
        .rd_error(),
        .wr_error(),
        .vtp_ports
        );


    // Don't track host channel low-level events
    host_chan_events_if host_chan_events();
    host_chan_events_none n(.events(host_chan_events));

    // Instantiate the test engine, which will generate requests using
    // virtual addresses.
    host_mem_rdwr_engine_axi
      #(
        .ENGINE_NUMBER(0),
        .ADDRESS_SPACE("VA")
        )
      eng
       (
        .host_mem_if(host_mem_afu_va_if),
        .host_chan_events_if(host_chan_events),
        .csrs(eng_csr[0])
        );


    // ====================================================================
    //
    //  Instantiate control via CSRs
    //
    // ====================================================================

    csr_mgr_axi
      #(
        .NUM_ENGINES(NUM_ENGINES),
        .DFH_MMIO_NEXT_ADDR(VTP_MMIO_BASE_ADDR)
        )
      csr_mgr
       (
        .mmio_if(mmio64_afu_if),
        .pClk,

        .eng_csr_glob,
        .eng_csr
        );

endmodule // afu
