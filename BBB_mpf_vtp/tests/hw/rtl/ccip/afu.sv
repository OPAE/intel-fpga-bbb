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
// Add a VTP server to the CCI-P interface and use virtual addresses in the
// test engine.
//

`include "ofs_plat_if.vh"
`include "cci_mpf_if.vh"

module afu
   (
    // Primary host interface
    ofs_plat_host_ccip_if.to_fiu host_ccip_if,

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

    localparam NUM_ENGINES = 1;


    // ====================================================================
    //
    //  Instantiate the VTP service for use by the host channel.
    //  The VTP service is an OFS CCI-P to OFS CCI-P shim that injects
    //  MMIO and page table traffic into the interface. The VTP
    //  translation ports are a separate interface that will be passed
    //  to the AFU memory engines.
    //
    // ====================================================================

    // One port for each of c0Tx and c1Tx
    mpf_vtp_port_if vtp_ports[2]();

    // Byte address of VTP CSRs
    localparam VTP_MMIO_BASE_ADDR = 'h4000;

    ofs_plat_host_ccip_if afu_ccip_if();

    mpf_vtp_svc_ofs_ccip
      #(
        // VTP's CSR byte address. The AFU will add this address to
        // the feature list.
        .DFH_MMIO_BASE_ADDR(VTP_MMIO_BASE_ADDR),
        .DFH_MMIO_NEXT_ADDR(0),
        .N_VTP_PORTS(2),
        // The tag must use value not used by the AFU so VTP can identify
        // it's own DMA traffic.
        .MDATA_TAG_MASK(1 << (CCIP_MDATA_WIDTH-2))
        )
      vtp_svc
       (
        .to_fiu(host_ccip_if),
        .to_afu(afu_ccip_if),
        .vtp_ports
        );


    // ====================================================================
    //
    //  Split the CCI-P interface into separate host memory and MMIO
    //  interfaces.
    //
    // ====================================================================

    // Enable simulation-time debug logging on these AFU interfaces
    ofs_plat_host_ccip_if#(.LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)) host_mem_if();
    ofs_plat_host_ccip_if#(.LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)) host_mmio_if();

    ofs_plat_shim_ccip_split_mmio ccip_split
       (
        .to_fiu(afu_ccip_if),
        .host_mem(host_mem_if),
        .mmio(host_mmio_if)
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
    ofs_plat_host_ccip_if#(.LOG_CLASS(ofs_plat_log_pkg::HOST_CHAN)) host_mem_va_if();

    mpf_vtp_translate_ofs_ccip vtp
       (
        .host_mem_if,
        .host_mem_va_if,
        .error_c0(),
        .error_c1(),
        .vtp_ports
        );

    // Instantiate the test engine, which will generate requests using
    // virtual addresses.
    host_mem_rdwr_engine_ccip
      #(
        .ENGINE_NUMBER(0)
        )
      eng
       (
        .host_mem_if(host_mem_va_if),
        .csrs(eng_csr[0])
        );


    // ====================================================================
    //
    //  Instantiate control via CSRs
    //
    // ====================================================================

    t_ccip_c0_ReqMmioHdr mmio_hdr;
    assign mmio_hdr = t_ccip_c0_ReqMmioHdr'(host_mmio_if.sRx.c0.hdr);

    // Tie off unused Tx ports
    assign host_mmio_if.sTx.c0 = '0;
    assign host_mmio_if.sTx.c1 = '0;

    csr_mgr
      #(
        .NUM_ENGINES(NUM_ENGINES),
        .DFH_MMIO_NEXT_ADDR(VTP_MMIO_BASE_ADDR),
        // Convert to QWORD index space (drop the low address bit)
        .MMIO_ADDR_WIDTH(CCIP_MMIOADDR_WIDTH - 1)
        )
      csr_mgr
       (
        .clk(host_mmio_if.clk),
        .reset_n(host_mmio_if.reset_n),
        .pClk,

        .wr_write(host_mmio_if.sRx.c0.mmioWrValid),
        .wr_address(mmio_hdr.address[CCIP_MMIOADDR_WIDTH-1 : 1]),
        .wr_writedata(host_mmio_if.sRx.c0.data[63:0]),

        .rd_read(host_mmio_if.sRx.c0.mmioRdValid),
        .rd_address(mmio_hdr.address[CCIP_MMIOADDR_WIDTH-1 : 1]),
        .rd_tid_in(mmio_hdr.tid),
        .rd_readdatavalid(host_mmio_if.sTx.c2.mmioRdValid),
        .rd_readdata(host_mmio_if.sTx.c2.data),
        .rd_tid_out(host_mmio_if.sTx.c2.hdr.tid),

        .eng_csr_glob,
        .eng_csr
        );

endmodule // afu
