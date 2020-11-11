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
// Instantiate a VTP service connected to an OFS CCI-P interface. The service
// is a transparent shim on the CCI-P interface that passes through the
// module. The shim takes over the specified MMIO range to control VTP and
// injects page table DMA requests.
//
// The shim connection doesn't perform translation -- it only manages the
// host I/O (MMIO and DMA) that supports translation. The shim exports a
// vector of VTP translation ports (vtp_ports), which the AFU may use to
// translate addresses within the AFU. VTP provides two wrapper modules,
// mpf_svc_vtp_port_wrapper_unordered and mpf_svc_vtp_port_wrapper_ordered,
// to connect read or write DMA pipelines to a VTP translation port.
//

`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

module mpf_vtp_svc_ofs_ccip
  #(
    // Instance ID reported in feature IDs of all device feature
    // headers instantiated under this instance of MPF. If only a single
    // MPF instance is instantiated in the AFU then leaving the instance
    // ID at 1 is probably the right choice.
    parameter MPF_INSTANCE_ID = 1,

    // MMIO base address (byte level) allocated to VTP for feature lists
    // and CSRs. The AFU allocating this module must build at least
    // a device feature header (DFH) for the AFU. The chain of device
    // features in the AFU must then point to the base address here
    // as another feature in the chain. VTP will continue the list.
    // The base address here must point to a region that is at least
    // CCI_MPF_VTP_CSR_SIZE bytes.
    parameter DFH_MMIO_BASE_ADDR,

    // Address of the next device feature header outside VTP. VTP will
    // terminate the feature list if the next address is 0.
    parameter DFH_MMIO_NEXT_ADDR = 0,

    // The page table walker must be able to identify responses to DMA
    // requests. It uses a unique tag in the CCI-P header's mdata field.
    // These parameters define a set of bits (MDATA_TAG_MASK) and a value
    // of those bits (MDATA_TAG_VALUE) that this module should set in
    // mdata to tag internal traffic. It is illegal for the tag to be
    // present on any requests incoming on the to_afu interface. If an
    // illegal mdata field is found the error bit below will be set and
    // all traffic will be blocked.
    //
    // By default, the high mdata bit is used as the tag.
    parameter t_ccip_mdata MDATA_TAG_MASK = 1 << (CCIP_MDATA_WIDTH-1),
    // MDATA_TAG_VALUE allows an AFU to support multiple engines that
    // need tags using a common mask but unique tags for each engine.
    // By default, the tag sets all masked bits.
    parameter t_ccip_mdata MDATA_TAG_VALUE = MDATA_TAG_MASK,

    // Number of VTP translation ports required by the AFU.
    parameter N_VTP_PORTS,

    // Two implementations of physical to virtual page translation are
    // available in VTP. Pick mode "HARDWARE_WALKER" to walk the VTP
    // page table using AFU-generated memory reads. Pick mode
    // "SOFTWARE_SERVICE" to send translation requests to software.
    // In HARDWARE_WALKER mode it is the user code's responsibility to
    // pin all pages that may be touched by the FPGA. The SOFTWARE_SERVICE
    // mode may pin pages automatically on demand.
    parameter string VTP_PT_MODE = "HARDWARE_WALKER",

    // Address mode. Normally, this is "IOADDR", indicating that the FPGA
    // DMA uses IO addresses from fpgaGetIOAddress(). When set to "HPA",
    // the FPGA uses host physical addresses.
    parameter string VTP_ADDR_MODE = "IOADDR",

    // Enable simulation debug messages?
    parameter VTP_DEBUG_MESSAGES = 0
    )
   (
    ofs_plat_host_ccip_if.to_fiu to_fiu,
    ofs_plat_host_ccip_if.to_afu to_afu,

    // Exported translation ports
    mpf_vtp_port_if.to_master vtp_ports[N_VTP_PORTS]
    );

    import cci_mpf_shim_pkg::*;
    import mpf_vtp_pkg::*;

    logic clk;
    assign clk = to_fiu.clk;
    logic reset_n;
    assign reset_n = to_fiu.reset_n;

    assign to_afu.clk = to_fiu.clk;
    assign to_afu.reset_n = to_fiu.reset_n;
    assign to_afu.error = to_fiu.error;
    assign to_afu.instance_number = to_fiu.instance_number;

    logic error;

    // ====================================================================
    //
    //  Instantiate VTP service
    //
    // ====================================================================

    // Interface for page table I/O requests from the VTP service. These
    // will be mapped here to CCI-P traffic.
    mpf_vtp_pt_host_if pt_fim();

    // The VTP service manages its own CSR space using a simple interface.
    // The code here must map CCI-P MMIO traffic to the interface.
    mpf_services_gen_csr_if
      #(
        .N_ENTRIES(mpf_vtp_pkg::MPF_VTP_CSR_N_ENTRIES),
        .N_DATA_BITS(mpf_vtp_pkg::MPF_VTP_CSR_N_DATA_BITS)
        )
      vtp_csrs();

    // The VTP service
    mpf_svc_vtp
      #(
        .ENABLE_VTP(1),
        .N_VTP_PORTS(N_VTP_PORTS),
        .VTP_PT_MODE(VTP_PT_MODE),
        .VTP_ADDR_MODE(VTP_ADDR_MODE),
        .DEBUG_MESSAGES(VTP_DEBUG_MESSAGES)
        )
      vtp
       (
        .clk,
        .reset(!reset_n),
        .vtp_ports,
        .pt_fim,
        .gen_csr_if(vtp_csrs)
        );


    // ====================================================================
    //
    //  Inject page table reads
    //
    // ====================================================================

    // Reads flow through undisturbed except for the need to inject reads
    // requested by the page table walker here.

    logic pt_walk_read_req;
    logic pt_walk_emit_req;
    t_cci_clAddr pt_walk_read_addr;
    t_cci_mpf_shim_mdata_value pt_walk_read_req_tag;

    assign pt_fim.readRdy = ! pt_walk_read_req;

    //
    // Track requests to read a line in the page table.
    //
    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            pt_walk_read_req <= 1'b0;
        end
        else
        begin
            // Either a request completed or a new one arrived
            pt_walk_read_req <= (pt_walk_read_req ^ pt_walk_emit_req) ||
                                pt_fim.readEn;
        end

        // Register requested address
        if (pt_fim.readEn)
        begin
            pt_walk_read_addr <= pt_fim.readAddr;
            pt_walk_read_req_tag <= pt_fim.readReqTag;
        end
    end

    // Emit the read for PT walk if a request is outstanding.
    assign pt_walk_emit_req = pt_walk_read_req &&
                              ! to_afu.sTx.c0.valid &&
                              ! to_fiu.sRx.c0TxAlmFull;

    // Request header for PT walk reads
    t_cci_mpf_c0_ReqMemHdr pt_walk_read_hdr;
    assign pt_walk_read_hdr =
        cci_mpf_c0_genReqHdr(eREQ_RDLINE_I,
                             pt_walk_read_addr,
                             MDATA_TAG_VALUE | pt_walk_read_req_tag,
                             cci_mpf_defaultReqHdrParams(0));

    //
    // Forward read requests
    //
    always_comb
    begin
        to_fiu.sTx.c0 = to_afu.sTx.c0;

        if (pt_walk_emit_req)
        begin
            to_fiu.sTx.c0 = '0;
            to_fiu.sTx.c0.hdr = pt_walk_read_hdr.base;
            to_fiu.sTx.c0.valid = 1'b1;
        end
    end

    // Is the read response for the page table walker?
    logic is_pt_c0_rsp;
    assign is_pt_c0_rsp = ((to_fiu.sRx.c0.hdr.mdata & MDATA_TAG_MASK) == MDATA_TAG_VALUE);

    always_comb
    begin
        pt_fim.readDataEn = ccip_c0Rx_isReadRsp(to_fiu.sRx.c0) && is_pt_c0_rsp;
        pt_fim.readData = to_fiu.sRx.c0.data;
        pt_fim.readRspTag = t_cci_mpf_shim_mdata_value'(to_fiu.sRx.c0.hdr.mdata);
    end


    // ====================================================================
    //
    //  Inject page table manager writes
    //
    // ====================================================================

    logic pt_mgr_write_req;
    logic pt_mgr_emit_req;
    t_cci_clAddr pt_mgr_write_addr;
    t_mpf_vtp_pt_fim_wr_data pt_mgr_write_data;

    assign pt_fim.writeRdy = ! pt_mgr_write_req;

    //
    // Track requests to write a line in the page table.
    //
    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            pt_mgr_write_req <= 1'b0;
        end
        else
        begin
            // Either a request completed or a new one arrived
            pt_mgr_write_req <= (pt_mgr_write_req ^ pt_mgr_emit_req) ||
                                pt_fim.writeEn;
        end

        // Register requested address
        if (pt_fim.writeEn)
        begin
            pt_mgr_write_addr <= pt_fim.writeAddr;
            pt_mgr_write_data <= pt_fim.writeData;
        end
    end

    // Track multi-line AFU writes so we don't inject a write in the middle of
    // a packet.
    logic c1Tx_packet_active;

    ofs_plat_utils_ccip_track_multi_write pkt_track
       (
        .clk,
        .reset_n,
        .c1Tx(to_afu.sTx.c1),
        .c1Tx_en(1'b1),
        .eop(),
        .packetActive(c1Tx_packet_active),
        .nextBeatNum()
        );

    // Emit the write for PT manager if a request is outstanding.
    assign pt_mgr_emit_req = pt_mgr_write_req &&
                             ! c1Tx_packet_active &&
                             ! to_afu.sTx.c1.valid &&
                             ! to_fiu.sRx.c1TxAlmFull;

    // Request header for PT manager writes
    t_cci_mpf_c1_ReqMemHdr pt_mgr_write_hdr;
    assign pt_mgr_write_hdr =
        cci_mpf_c1_genReqHdr(eREQ_WRLINE_I,
                             pt_mgr_write_addr,
                             MDATA_TAG_VALUE,
                             cci_mpf_defaultReqHdrParams(0));

    //
    // Forward write requests
    //
    always_comb
    begin
        to_fiu.sTx.c1 = to_afu.sTx.c1;

        if (pt_mgr_emit_req)
        begin
            to_fiu.sTx.c1 = '0;
            to_fiu.sTx.c1.hdr = pt_mgr_write_hdr.base;
            to_fiu.sTx.c1.data = t_ccip_clData'(pt_mgr_write_data);
            to_fiu.sTx.c1.valid = 1'b1;
        end
    end

    // Is the write response for the page table walker?
    logic is_pt_c1_rsp;
    assign is_pt_c1_rsp = ((to_fiu.sRx.c1.hdr.mdata & MDATA_TAG_MASK) == MDATA_TAG_VALUE);


    // ====================================================================
    //
    //  Confirm that MDATA tag is not used by the AFU
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        if (cci_mpf_c0TxIsReadReq(to_afu.sTx.c0) &&
            ((to_afu.sTx.c0.hdr.mdata & MDATA_TAG_MASK) == MDATA_TAG_VALUE))
        begin
            error <= 1'b1;

            // synthesis translate_off
            $fatal(2, "** ERROR ** %m: to_afu.sTx.c0.hdr.mdata (0x%h) uses reserved tag MDATA_TAG_VALUE (0x%h), MDATA_TAG_MASK (0x%h)",
                   to_afu.sTx.c0.hdr.mdata, MDATA_TAG_VALUE, MDATA_TAG_MASK);
            // synthesis translate_on
        end

        if (cci_mpf_c1TxIsWriteReq(to_afu.sTx.c1) &&
            ((to_afu.sTx.c1.hdr.mdata & MDATA_TAG_MASK) == MDATA_TAG_VALUE))
        begin
            error <= 1'b1;

            // synthesis translate_off
            $fatal(2, "** ERROR ** %m: to_afu.sTx.c1.hdr.mdata (0x%h) uses reserved tag MDATA_TAG_VALUE (0x%h), MDATA_TAG_MASK (0x%h)",
                   to_afu.sTx.c1.hdr.mdata, MDATA_TAG_VALUE, MDATA_TAG_MASK);
            // synthesis translate_on
        end

        if (!reset_n)
        begin
            error <= 1'b0;

            // No MDATA_TAG_VALUE bits should be set without a corresponding
            // bit set in MDATA_TAG_MASK.
            if ((MDATA_TAG_VALUE & ~MDATA_TAG_MASK) != t_ccip_mdata'(0))
            begin
                error <= 1'b1;

                // synthesis translate_off
                $fatal(2, "** ERROR ** %m: MDATA_TAG_VALUE (0x%h) has bits set that are not in MDATA_TAG_MASK (0x%h)",
                       MDATA_TAG_VALUE, MDATA_TAG_MASK);
                // synthesis translate_on
            end
        end
    end


    // ====================================================================
    //
    //  Handle VTP MMIO requests
    //
    // ====================================================================

    t_ccip_mmioAddr csr_addr;
    assign csr_addr = cci_csr_getAddress(to_fiu.sRx.c0);

    logic mmio_rsp_valid;
    t_ccip_tid mmio_rsp_tid;
    logic [63:0] mmio_rsp_data;
    logic mmio_rsp_en;

    logic is_vtp_mmio;

    mpf_vtp_svc_mmio
      #(
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .DFH_MMIO_NEXT_ADDR(DFH_MMIO_NEXT_ADDR)
        )
      mmio
       (
        .clk,
        .reset(!reset_n),

        // Drop the low bit from the MMIO address to convert from 32 bit data
        // to 64 bit data offsets.
        .csr_addr(csr_addr[CCIP_MMIOADDR_WIDTH-1 : 1]),

        .write_req(to_fiu.sRx.c0.mmioWrValid),
        .write_data(64'(to_fiu.sRx.c0.data)),

        .read_req(to_fiu.sRx.c0.mmioRdValid),
        .read_tid_in(cci_csr_getTid(to_fiu.sRx.c0)),
        .read_rsp(mmio_rsp_valid),
        .read_tid_out(mmio_rsp_tid),
        .read_data(mmio_rsp_data),
        .read_deq(mmio_rsp_en),

        .is_vtp_mmio,

        .vtp_csrs
        );

    // Forward responses to host, either generated locally or from
    // the AFU.
    assign mmio_rsp_en = mmio_rsp_valid && ! to_afu.sTx.c2.mmioRdValid;

    always_ff @(posedge clk)
    begin
        if (mmio_rsp_en)
        begin
            to_fiu.sTx.c2 <= '0;
            to_fiu.sTx.c2.mmioRdValid <= 1'b1;
            to_fiu.sTx.c2.hdr.tid <= mmio_rsp_tid;
            to_fiu.sTx.c2.data <= t_ccip_mmioData'(mmio_rsp_data);
        end
        else
        begin
            to_fiu.sTx.c2 <= to_afu.sTx.c2;
        end
    end


    // ====================================================================
    //
    //  Send CCI-P responses to the AFU, dropping responses that were
    //  to the VTP service managed here.
    //
    // ====================================================================

    always_comb
    begin
        to_afu.sRx = to_fiu.sRx;

        //
        // Force almost full when the page table is trying to emit DMA requests
        //
        to_afu.sRx.c0TxAlmFull = to_fiu.sRx.c0TxAlmFull || pt_walk_read_req || error;
        to_afu.sRx.c1TxAlmFull = to_fiu.sRx.c1TxAlmFull || pt_mgr_write_req || error;

        //
        // Don't forward VTP's private traffic
        //

        if (ccip_c0Rx_isReadRsp(to_fiu.sRx.c0) && is_pt_c0_rsp)
        begin
            to_afu.sRx.c0.rspValid = 1'b0;
        end

        if (ccip_c1Rx_isWriteRsp(to_fiu.sRx.c1) && is_pt_c1_rsp)
        begin
            to_afu.sRx.c1.rspValid = 1'b0;
        end

        if (is_vtp_mmio)
        begin
            to_afu.sRx.c0.mmioRdValid = 1'b0;
            to_afu.sRx.c0.mmioWrValid = 1'b0;
        end
    end

endmodule // mpf_vtp_svc_ofs_ccip
