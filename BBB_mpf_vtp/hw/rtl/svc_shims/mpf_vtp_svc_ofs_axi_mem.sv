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
// Instantiate a VTP service connected to an OFS AXI host channel
// interface. The service is a transparent shim on the AXI split-bus
// read/write interface that passes through the module. The shim takes
// over the specified MMIO range to control VTP and injects page table
// DMA requests.
//
// The shim connection doesn't perform translation -- it only manages the
// host I/O (MMIO and DMA) that supports translation. The shim exports a
// vector of VTP translation ports (vtp_ports), which the AFU may use to
// translate addresses within the AFU. VTP provides two wrapper modules,
// mpf_svc_vtp_port_wrapper_unordered and mpf_svc_vtp_port_wrapper_ordered,
// to connect read or write DMA pipelines to a VTP translation port.
//

`include "ofs_plat_if.vh"
`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

module mpf_vtp_svc_ofs_axi_mem
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

    // Index of the RID and WID field's bits to use as a tag to flag DMA
    // page table traffic.
    parameter RID_TAG_IDX,
    parameter WID_TAG_IDX,

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
    // The service will be instantiated between mem_source (the AFU) and
    // mem_sink (the FIM).
    ofs_plat_axi_mem_if.to_source mem_source,
    ofs_plat_axi_mem_if.to_sink mem_sink,

    // The service also must act as an MMIO shim in order to manage the
    // VTP CSR space. An MMIO space with 64 bit data is required.
    ofs_plat_axi_mem_lite_if.to_source mmio64_source,
    ofs_plat_axi_mem_lite_if.to_sink mmio64_sink,

    // Exported translation ports
    mpf_vtp_port_if.to_master vtp_ports[N_VTP_PORTS]
    );

    import cci_mpf_shim_pkg::*;
    import mpf_vtp_pkg::*;

    logic clk;
    assign clk = mem_sink.clk;
    logic reset_n;
    assign reset_n = mem_sink.reset_n;

    logic error;

    localparam ADDR_WIDTH = mem_source.ADDR_WIDTH;
    typedef logic [ADDR_WIDTH-1 : 0] t_addr;

    localparam RID_WIDTH = mem_sink.RID_WIDTH;
    localparam WID_WIDTH = mem_sink.WID_WIDTH;


    // ====================================================================
    //
    //  Instantiate VTP service
    //
    // ====================================================================

    // Interface for page table I/O requests from the VTP service. These
    // will be mapped here to CCI-P traffic.
    mpf_vtp_pt_host_if pt_fim();

    // The VTP service manages its own CSR space using a simple interface.
    // The code below must map MMIO traffic to the interface.
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
    //  Hold AFU read requests (non-page table) in a skid buffer
    //
    // ====================================================================

    // Page table access insertion will add arbitration between the
    // output of the skid buffers and the page table I/O pipelines.

    ofs_plat_axi_mem_if
      #(
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(mem_source)
        )
      mem_source_skid();

    assign mem_source_skid.clk = mem_source.clk;
    assign mem_source_skid.reset_n = mem_source.reset_n;
    assign mem_source_skid.instance_number = mem_source.instance_number;

    ofs_plat_axi_mem_if_skid afu_mem_skid
       (
        .mem_source,
        .mem_sink(mem_source_skid)
        );

    // Synchronize AW and W channels in the source request stream so
    // the code below has a clear point at which a write request can
    // be injected into the stream.
    ofs_plat_axi_mem_if
      #(
        `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(mem_source)
        )
      mem_source_sync();

    assign mem_source_sync.clk = mem_source.clk;
    assign mem_source_sync.reset_n = mem_source.reset_n;
    assign mem_source_sync.instance_number = mem_source.instance_number;

    ofs_plat_axi_mem_if_sync afu_mem_sync
       (
        .mem_source(mem_source_skid),
        .mem_sink(mem_source_sync)
        );


    // ====================================================================
    //
    //  Inject page table reads
    //
    // ====================================================================

    // Reads flow through undisturbed except for the need to inject reads
    // requested by the page table walker here.

    // When injecting a DMA request, the walker tags page table requests
    // by setting the bit at RID_TAG_IDX.
    //
    // The page table walker may have multiple reads outstanding. They are
    // tagged with pt_fim.readReqTag, of type t_cci_mpf_shim_mdata_value.
    // Those tags are stored in the low bits of the RID tag. The RID_TAG_IDX
    // must be large enough to leave space for a t_cci_mpf_shim_mdata_value
    // below it.
    localparam PT_REQ_TAG_BIT_IDX = 0;

    logic pt_walk_read_req;
    logic pt_walk_emit_req;
    t_addr pt_walk_read_addr;
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
            // Low address bits in the 64 byte line are 0
            pt_walk_read_addr <= { pt_fim.readAddr, 6'b0 };
            pt_walk_read_req_tag <= pt_fim.readReqTag;
        end
    end

    // Emit the read for PT walk if a request is outstanding.
    assign pt_walk_emit_req = pt_walk_read_req && mem_sink.arready;
    assign mem_source_sync.arready = !pt_walk_read_req && mem_sink.arready;

    //
    // Forward read requests
    //
    always_comb
    begin
        mem_sink.arvalid = mem_source_sync.arvalid;
        // Field-by-field AR copy (supports different ID sizes on source/sink)
        `OFS_PLAT_AXI_MEM_IF_COPY_AR(mem_sink.ar, =, mem_source_sync.ar);
        // Normal AFU reads have the RID_TAG_IDX bit clear
        mem_sink.ar.id[RID_TAG_IDX] = 1'b0;

        // Is there a page table read pending?
        if (pt_walk_read_req)
        begin
            mem_sink.arvalid = 1'b1;

            // Assume the data width is 64 bytes
            mem_sink.ar = '0;
            mem_sink.ar.addr = pt_walk_read_addr;
            mem_sink.ar.size = 3'b110;

            // Tag read request as a page table read
            mem_sink.ar.id[RID_TAG_IDX] = 1'b1;
            // Record the page table read tag (multiple reads may be outstanding)
            mem_sink.ar.id[PT_REQ_TAG_BIT_IDX +: $bits(pt_walk_read_req_tag)] = pt_walk_read_req_tag;
        end
    end

    // Is the read response for the page table walker?
    logic is_pt_rd_rsp;
    assign is_pt_rd_rsp = mem_sink.r.id[RID_TAG_IDX];

    // Forward responses to page table reader
    always_ff @(posedge clk)
    begin
        pt_fim.readDataEn <= mem_sink.rvalid && mem_sink.rready && is_pt_rd_rsp;
        pt_fim.readData <= mem_sink.r.data;
        pt_fim.readRspTag <= mem_sink.r.id[PT_REQ_TAG_BIT_IDX +: $bits(pt_walk_read_req_tag)];
    end

    // Forward non-page table read responses to AFU
    assign mem_sink.rready = mem_source_sync.rready;
    assign mem_source_sync.rvalid = mem_sink.rvalid && !is_pt_rd_rsp;
    always_comb
    begin
        // Field-by-field R copy (supports different ID sizes on source/sink)
        `OFS_PLAT_AXI_MEM_IF_COPY_R(mem_source_sync.r, =, mem_sink.r);
    end


    // ====================================================================
    //
    //  Inject page table manager writes
    //
    // ====================================================================

    logic pt_mgr_write_req;
    logic pt_mgr_emit_req;
    t_addr pt_mgr_write_addr;
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
            pt_mgr_write_addr <= { pt_fim.writeAddr, 6'b0 };
            pt_mgr_write_data <= pt_fim.writeData;
        end
    end

    // Track multi-line AFU writes so we don't inject a write in the middle of
    // a packet. The split address and data buses make this a little complicated,
    // which we "solve" by forcing the address bus to align with the first
    // beat of data that corresponds to the address.
    logic afu_wr_is_sop;
    always_ff @(posedge clk)
    begin
        if (mem_source_sync.wready && mem_source_sync.wvalid)
        begin
            afu_wr_is_sop <= mem_source_sync.w.last;
        end

        if (!reset_n)
        begin
            afu_wr_is_sop <= 1'b1;
        end
    end

    // Accept AFU write addresses at the start of a burst but only when
    // there is no page table manager write pending. The W channel must
    // be ready too in order to keep AW and W synchronized.
    assign mem_source_sync.awready = mem_sink.awready && mem_sink.wready &&
                                     !pt_mgr_write_req;

    // Accept AFU write data to complete a burst or when there is no page
    // table manager write.
    assign mem_source_sync.wready = mem_sink.wready &&
                                    (!afu_wr_is_sop || (mem_sink.awready && !pt_mgr_write_req));

    // Emit the write for PT manager if a request is outstanding.
    assign pt_mgr_emit_req = pt_mgr_write_req && afu_wr_is_sop &&
                             mem_sink.awready && mem_sink.wready;

    //
    // Forward write requests
    //
    always_comb
    begin
        mem_sink.awvalid = mem_source_sync.awvalid && mem_source_sync.awready;
        // Field-by-field AW copy (supports different ID sizes on source/sink)
        `OFS_PLAT_AXI_MEM_IF_COPY_AW(mem_sink.aw, =, mem_source_sync.aw);
        // Normal AFU reads have the WID_TAG_IDX bit clear
        mem_sink.aw.id[WID_TAG_IDX] = 1'b0;

        mem_sink.wvalid = mem_source_sync.wvalid && mem_source_sync.wready;
        // Field-by-field W copy (supports different ID sizes on source/sink)
        `OFS_PLAT_AXI_MEM_IF_COPY_W(mem_sink.w, =, mem_source_sync.w);

        // Is there a page table manager write pending?
        if (pt_mgr_emit_req)
        begin
            mem_sink.awvalid = 1'b1;
            mem_sink.aw = '0;
            mem_sink.aw.addr = pt_mgr_write_addr;
            mem_sink.aw.size = 3'b110;
            mem_sink.aw.id[WID_TAG_IDX] = 1'b1;

            mem_sink.wvalid = 1'b1;
            mem_sink.w = '0;
            mem_sink.w.data = { '0, pt_mgr_write_data };
            mem_sink.w.strb = ~mem_sink.w.strb;
            mem_sink.w.last = 1'b1;
        end
    end

    // Is the write response for the page table walker?
    logic is_pt_wr_rsp;
    assign is_pt_wr_rsp = mem_sink.b.id[WID_TAG_IDX];

    // Forward non-page table write responses to AFU
    assign mem_sink.bready = mem_source_sync.bready || is_pt_wr_rsp;
    assign mem_source_sync.bvalid = mem_sink.bvalid && !is_pt_wr_rsp;
    always_comb
    begin
        // Field-by-field B copy (supports different ID sizes on source/sink)
        `OFS_PLAT_AXI_MEM_IF_COPY_B(mem_source_sync.b, =, mem_sink.b);
    end


    // ====================================================================
    //
    //  Error checking
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        if (!reset_n)
        begin
            error <= 1'b0;

            if (RID_TAG_IDX >= RID_WIDTH)
            begin
                error <= 1'b1;

                // synthesis translate_off
                $fatal(2, "** ERROR ** %m: RID_TAG_IDX (%0d) is outside RID_WIDTH (%0d)!",
                       RID_TAG_IDX, RID_WIDTH);
                // synthesis translate_on
            end

            if (WID_TAG_IDX >= WID_WIDTH)
            begin
                error <= 1'b1;

                // synthesis translate_off
                $fatal(2, "** ERROR ** %m: WID_TAG_IDX (%0d) is outside WID_WIDTH (%0d)!",
                       WID_TAG_IDX, WID_WIDTH);
                // synthesis translate_on
            end

            if ((PT_REQ_TAG_BIT_IDX + $bits(t_cci_mpf_shim_mdata_value)) > RID_TAG_IDX)
            begin
                error <= 1'b1;

                // synthesis translate_off
                // If this fires, either the AXI interface's RID_TAG_WIDTH must be larger
                // or RID_TAG_IDX must point to a higher bit in the user field.
                $fatal(2, "** ERROR ** %m: Not enough space for a t_cci_mpf_shim_mdata_value between PT_REQ_TAG_BIT_IDX (%0d), tag bits (%0d) and RID_TAG_IDX (%0d)",
                       PT_REQ_TAG_BIT_IDX, $bits(t_cci_mpf_shim_mdata_value), RID_TAG_IDX);
                // synthesis translate_on
            end
        end
    end


    // ====================================================================
    //
    //  Handle VTP MMIO requests
    //
    // ====================================================================

    ofs_plat_axi_mem_lite_if
      #(
        `OFS_PLAT_AXI_MEM_LITE_IF_REPLICATE_PARAMS(mmio64_source)
        )
      mmio64_source_skid();

    assign mmio64_source_skid.clk = mmio64_source.clk;
    assign mmio64_source_skid.reset_n = mmio64_source.reset_n;
    assign mmio64_source_skid.instance_number = mmio64_source.instance_number;

    ofs_plat_axi_mem_lite_if_skid fim_mmio_skid
       (
        .mem_source(mmio64_source),
        .mem_sink(mmio64_source_skid)
        );

    //
    // Change the behavior of the AXI channels to map more easily to CSRs.
    // The PIM provides a module that makes AXI lite more like Avalon:
    // AW and W are tied together and only a read or write request may
    // be valid but not both.
    //
    ofs_plat_axi_mem_lite_if
      #(
        `OFS_PLAT_AXI_MEM_LITE_IF_REPLICATE_PARAMS(mmio64_source)
        )
      mmio64_source_sync();

    assign mmio64_source_sync.clk = mmio64_source_skid.clk;
    assign mmio64_source_sync.reset_n = mmio64_source_skid.reset_n;
    assign mmio64_source_sync.instance_number = mmio64_source_skid.instance_number;

    ofs_plat_axi_mem_lite_if_sync
      #(
        .NO_SIMULTANEOUS_RW(1)
        )
      fim_mmio64_source_sync
       (
        .mem_source(mmio64_source_skid),
        .mem_sink(mmio64_source_sync)
        );

    //
    // Add a skid buffer to the AFU side of the MMIO interface too.
    //
    ofs_plat_axi_mem_lite_if
      #(
        `OFS_PLAT_AXI_MEM_LITE_IF_REPLICATE_PARAMS(mmio64_sink)
        )
      mmio64_sink_skid();

    assign mmio64_sink_skid.clk = mmio64_sink.clk;
    assign mmio64_sink_skid.reset_n = mmio64_sink.reset_n;
    assign mmio64_sink_skid.instance_number = mmio64_sink.instance_number;

    ofs_plat_axi_mem_lite_if_skid afu_mmio_skid
       (
        .mem_source(mmio64_sink_skid),
        .mem_sink(mmio64_sink)
        );


    //
    // With the above transformations, the MMIO protocol is relatively simple.
    // Write requests arrive with AW and W together. Read and write requests
    // never fire in the same cycle. Because of the skid buffers, ready signals
    // are independent of valid signals. Once a channel is ready, it will remain
    // ready at least until a new message is passed.
    //

    logic mmio_rsp_valid;
    logic [63:0] mmio_rsp_data;
    logic [mmio64_source.USER_WIDTH + mmio64_source.RID_WIDTH - 1 : 0] mmio_rsp_tid;
    logic mmio_rsp_en;

    // Address in 64 bit space (drop low 3 bits)
    localparam MMIO64_ADDR_WIDTH = mmio64_source.ADDR_WIDTH - 3;

    logic is_vtp_mmio;

    assign mmio64_source_sync.awready = mmio64_sink_skid.awready && mmio64_sink_skid.wready &&
                                        mmio64_source_sync.bready;
    assign mmio64_source_sync.wready = mmio64_source_sync.awready;
    assign mmio64_source_sync.arready = mmio64_sink_skid.arready;

    // MPF-supplied MPF/VTP CSR manager
    mpf_vtp_svc_mmio
      #(
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .DFH_MMIO_NEXT_ADDR(DFH_MMIO_NEXT_ADDR),
        .MMIO64_TID_WIDTH(mmio64_source.USER_WIDTH + mmio64_source.RID_WIDTH)
        )
      mmio
       (
        .clk,
        .reset(!reset_n),

        // Only one of arvalid and awvalid will be set
        .csr_addr(mmio64_source_sync.arvalid ? mmio64_source_sync.ar.addr[3 +: MMIO64_ADDR_WIDTH] :
                                               mmio64_source_sync.aw.addr[3 +: MMIO64_ADDR_WIDTH]),

        // awready and wready are identical
        .write_req(mmio64_source_sync.awvalid && mmio64_source_sync.awready),
        .write_data(mmio64_source_sync.w.data),

        .read_req(mmio64_source_sync.arvalid && mmio64_source_sync.arready),
        .read_tid_in({ mmio64_source_sync.ar.user, mmio64_source_sync.ar.id }),
        .read_rsp(mmio_rsp_valid),
        .read_tid_out(mmio_rsp_tid),
        .read_data(mmio_rsp_data),
        .read_deq(mmio_rsp_en),

        .is_vtp_mmio,

        .vtp_csrs
        );

    // Forward non-VTP MMIO traffic to the AFU.
    always_comb
    begin
        // The aw and w channels are synchronized above
        mmio64_sink_skid.awvalid = mmio64_source_sync.awvalid && mmio64_source_sync.awready &&
                                   !is_vtp_mmio;
        mmio64_sink_skid.aw = mmio64_source_sync.aw;
        mmio64_sink_skid.wvalid = mmio64_sink_skid.awvalid;
        mmio64_sink_skid.w = mmio64_source_sync.w;

        mmio64_sink_skid.arvalid = mmio64_source_sync.arvalid && mmio64_source_sync.arready &&
                                  !is_vtp_mmio;
        mmio64_sink_skid.ar = mmio64_source_sync.ar;
    end

    // Write response, either from VTP or the AFU. AFU responses are blocked
    // when a new write is being processed.
    assign mmio64_sink_skid.bready = mmio64_source_sync.bready && !is_vtp_mmio;
    assign mmio64_source_sync.bvalid =
        (mmio64_sink_skid.bvalid && !is_vtp_mmio) ||
        (mmio64_source_sync.awvalid && mmio64_source_sync.awready && is_vtp_mmio);

    always_comb
    begin
        // Pick a source of write response tags, depending on whether a
        // VTP MMIO write response might be processed.
        if (is_vtp_mmio)
        begin
            mmio64_source_sync.b = '0;
            mmio64_source_sync.b.id = mmio64_source_sync.aw.id;
        end
        else
        begin
            // AFU responses
            mmio64_source_sync.b = mmio64_sink_skid.b;
        end
    end

    // Forward read responses to host, either generated locally or from
    // the AFU. Favor VTP MMIO read responses.
    assign mmio_rsp_en = mmio_rsp_valid && mmio64_source_sync.rready;
    assign mmio64_source_sync.rvalid = mmio_rsp_valid || mmio64_sink_skid.rvalid;
    assign mmio64_sink_skid.rready = mmio64_source_sync.rready && !mmio_rsp_valid;

    always_comb
    begin
        if (mmio_rsp_valid)
        begin
            // VTP MMIO read response
            mmio64_source_sync.r = '0;
            mmio64_source_sync.r.data = mmio_rsp_data;
            { mmio64_source_sync.r.user, mmio64_source_sync.r.id } = mmio_rsp_tid;
        end
        else
        begin
            // AFU MMIO read response
            mmio64_source_sync.r = mmio64_sink_skid.r;
        end
    end

endmodule // mpf_vtp_svc_ofs_axi_mem
