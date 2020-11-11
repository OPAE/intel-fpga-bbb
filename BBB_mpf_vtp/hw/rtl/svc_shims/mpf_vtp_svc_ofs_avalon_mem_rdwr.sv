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
// Instantiate a VTP service connected to an OFS Avalon host channel
// interface. The service is a transparent shim on the Avalon split-bus
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

module mpf_vtp_svc_ofs_avalon_mem_rdwr
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

    // Index of the user field's bit to use as a tag to flag DMA page
    // table traffic. User field is an OFS extension of the Avalon
    // interface. User fields passed with requests are returned, unmodified,
    // with responses.
    parameter USER_TAG_IDX,

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
    ofs_plat_avalon_mem_rdwr_if.to_source mem_source,
    ofs_plat_avalon_mem_rdwr_if.to_sink mem_sink,

    // The service also must act as an MMIO shim in order to manage the
    // VTP CSR space. An MMIO space with 64 bit data is required.
    ofs_plat_avalon_mem_if.to_source mmio64_source,
    ofs_plat_avalon_mem_if.to_sink mmio64_sink,

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

    ofs_plat_avalon_mem_rdwr_if
      #(
        `OFS_PLAT_AVALON_MEM_RDWR_IF_REPLICATE_PARAMS(mem_source)
        )
      mem_source_skid();

    assign mem_source_skid.clk = mem_source.clk;
    assign mem_source_skid.reset_n = mem_source.reset_n;
    assign mem_source_skid.instance_number = mem_source.instance_number;

    ofs_plat_avalon_mem_rdwr_if_skid
      #(
        .REG_RSP(0)
        )
      afu_mem_skid
       (
        .mem_source,
        .mem_sink(mem_source_skid)
        );


    // ====================================================================
    //
    //  Inject page table reads
    //
    // ====================================================================

    // Reads flow through undisturbed except for the need to inject reads
    // requested by the page table walker here.

    // When injecting a DMA request, the walker tags page table requests
    // by setting the bit at USER_TAG_IDX in mem_source the user extension
    // field. The page table walker may have multiple reads outstanding.
    // They are tagged with pt_fim.readReqTag, of type t_cci_mpf_shim_mdata_value.
    // Those tags are stored the user field just after the PIM's user
    // flags. The USER_TAG_IDX must be large enough to leave space for
    // a t_cci_mpf_shim_mdata_value between HC_AVALON_UFLAG_MAX and USER_TAG_IDX.
    localparam PT_REQ_TAG_BIT_IDX = ofs_plat_host_chan_avalon_mem_pkg::HC_AVALON_UFLAG_MAX + 1;

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
            pt_walk_read_addr <= pt_fim.readAddr;
            pt_walk_read_req_tag <= pt_fim.readReqTag;
        end
    end

    // Emit the read for PT walk if a request is outstanding.
    assign pt_walk_emit_req = pt_walk_read_req && !mem_sink.rd_waitrequest;
    assign mem_source_skid.rd_waitrequest = pt_walk_read_req || mem_sink.rd_waitrequest;

    //
    // Forward read requests
    //
    always_comb
    begin
        `OFS_PLAT_AVALON_MEM_RDWR_IF_RD_FROM_SOURCE_TO_SINK_COMB(mem_sink, mem_source_skid);
        // Normal AFU reads have the USER_TAG_IDX bit clear
        mem_sink.rd_user[USER_TAG_IDX] = 1'b0;

        // Is there a page table read pending?
        if (pt_walk_read_req)
        begin
            mem_sink.rd_read = 1'b1;
            mem_sink.rd_burstcount = 1;
            mem_sink.rd_byteenable = '0;
            mem_sink.rd_byteenable = ~mem_sink.rd_byteenable;
            mem_sink.rd_address = pt_walk_read_addr;

            mem_sink.rd_user = '0;
            // Tag read request as a page table read
            mem_sink.rd_user[USER_TAG_IDX] = 1'b1;
            // Record the page table read tag (multiple reads may be outstanding)
            mem_sink.rd_user[PT_REQ_TAG_BIT_IDX +: $bits(pt_walk_read_req_tag)] = pt_walk_read_req_tag;
        end
    end

    // Is the read response for the page table walker?
    logic is_pt_rd_rsp;
    assign is_pt_rd_rsp = mem_sink.rd_readresponseuser[USER_TAG_IDX];

    // Forward responses to page table reader
    always_ff @(posedge clk)
    begin
        pt_fim.readDataEn <= mem_sink.rd_readdatavalid && is_pt_rd_rsp;
        pt_fim.readData <= mem_sink.rd_readdata;
        pt_fim.readRspTag <= mem_sink.rd_readresponseuser[PT_REQ_TAG_BIT_IDX +: $bits(pt_walk_read_req_tag)];
    end

    // Forward non-page table read responses to AFU
    always_ff @(posedge clk)
    begin
        mem_source_skid.rd_readdatavalid <= mem_sink.rd_readdatavalid && !is_pt_rd_rsp;
        mem_source_skid.rd_readdata <= mem_sink.rd_readdata;
        mem_source_skid.rd_response <= mem_sink.rd_response;
        mem_source_skid.rd_readresponseuser <= mem_sink.rd_readresponseuser;
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
            pt_mgr_write_addr <= pt_fim.writeAddr;
            pt_mgr_write_data <= pt_fim.writeData;
        end
    end

    // Track multi-line AFU writes so we don't inject a write in the middle of
    // a packet.
    logic afu_wr_is_sop;

    ofs_plat_prim_burstcount1_sop_tracker
      #(
        .BURST_CNT_WIDTH(mem_source.BURST_CNT_WIDTH)
        )
      afu_sop_track
       (
        .clk,
        .reset_n,
        .flit_valid(mem_source_skid.wr_write && !mem_source_skid.wr_waitrequest),
        .burstcount(mem_source_skid.wr_burstcount),
        .sop(afu_wr_is_sop),
        .eop()
        );

    // Emit the write for PT manager if a request is outstanding.
    assign pt_mgr_emit_req = pt_mgr_write_req && afu_wr_is_sop &&
                             !mem_sink.wr_waitrequest;
    assign mem_source_skid.wr_waitrequest = (pt_mgr_write_req && afu_wr_is_sop) ||
                                            mem_sink.wr_waitrequest;

    //
    // Forward write requests
    //
    always_comb
    begin
        `OFS_PLAT_AVALON_MEM_RDWR_IF_WR_FROM_SOURCE_TO_SINK_COMB(mem_sink, mem_source_skid);
        // Normal AFU writes have the USER_TAG_IDX bit clear
        mem_sink.wr_user[USER_TAG_IDX] = 1'b0;

        // Is there a page table manager write pending?
        if (pt_mgr_write_req)
        begin
            mem_sink.wr_write = 1'b1;
            mem_sink.wr_burstcount = 1;
            mem_sink.wr_byteenable = '0;
            mem_sink.wr_byteenable = ~mem_sink.wr_byteenable;
            mem_sink.wr_address = pt_mgr_write_addr;
            mem_sink.wr_writedata = { '0, pt_mgr_write_data };

            mem_sink.wr_user = '0;
            // Tag write request as a page table manager write
            mem_sink.wr_user[USER_TAG_IDX] = 1'b1;
        end
    end

    // Is the write response for the page table walker?
    logic is_pt_wr_rsp;
    assign is_pt_wr_rsp = mem_sink.wr_writeresponseuser[USER_TAG_IDX];

    // Forward non-page table write responses to AFU
    always_ff @(posedge clk)
    begin
        mem_source_skid.wr_writeresponsevalid <= mem_sink.wr_writeresponsevalid && !is_pt_wr_rsp;
        mem_source_skid.wr_response <= mem_sink.wr_response;
        mem_source_skid.wr_writeresponseuser <= mem_sink.wr_writeresponseuser;
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

            if ((PT_REQ_TAG_BIT_IDX + $bits(t_cci_mpf_shim_mdata_value)) > USER_TAG_IDX)
            begin
                error <= 1'b1;

                // synthesis translate_off
                // If this fires, either the Avalon interface's USER_WIDTH must be larger
                // or USER_TAG_IDX must point to a higher bit in the user field.
                $fatal(2, "** ERROR ** %m: Not enough space for a t_cci_mpf_shim_mdata_value between PT_REQ_TAG_BIT_IDX (%0d), tag bits (%0d) and USER_TAG_IDX (%0d)",
                       PT_REQ_TAG_BIT_IDX, $bits(t_cci_mpf_shim_mdata_value), USER_TAG_IDX);
                // synthesis translate_on
            end
        end
    end


    // ====================================================================
    //
    //  Handle VTP MMIO requests
    //
    // ====================================================================

    logic mmio_rsp_valid;
    logic [63:0] mmio_rsp_data;
    logic [mmio64_source.USER_WIDTH-1 : 0] mmio_rsp_user;
    logic mmio_rsp_en;

    logic is_vtp_mmio;

    assign mmio64_source.waitrequest = mmio64_sink.waitrequest;

    // MPF-supplied MPF/VTP CSR manager
    mpf_vtp_svc_mmio
      #(
        .MPF_INSTANCE_ID(MPF_INSTANCE_ID),
        .DFH_MMIO_BASE_ADDR(DFH_MMIO_BASE_ADDR),
        .DFH_MMIO_NEXT_ADDR(DFH_MMIO_NEXT_ADDR),
        .MMIO64_TID_WIDTH(mmio64_source.USER_WIDTH)
        )
      mmio
       (
        .clk,
        .reset(!reset_n),

        .csr_addr(mmio64_source.address),

        .write_req(mmio64_source.write && !mmio64_source.waitrequest),
        .write_data(mmio64_source.writedata),

        .read_req(mmio64_source.read && !mmio64_source.waitrequest),
        .read_tid_in(mmio64_source.user),
        .read_rsp(mmio_rsp_valid),
        .read_tid_out(mmio_rsp_user),
        .read_data(mmio_rsp_data),
        .read_deq(mmio_rsp_en),

        .is_vtp_mmio,

        .vtp_csrs
        );

    // Forward non-VTP MMIO traffic to the AFU
    always_comb
    begin
        `OFS_PLAT_AVALON_MEM_IF_FROM_SOURCE_TO_SINK_COMB(mmio64_sink, mmio64_source);

        mmio64_sink.write = mmio64_source.write && !is_vtp_mmio;
        mmio64_sink.read = mmio64_source.read && !is_vtp_mmio;
    end

    // Forward responses to host, either generated locally or from
    // the AFU.
    assign mmio_rsp_en = mmio_rsp_valid && !mmio64_sink.readdatavalid;

    always_ff @(posedge clk)
    begin
        if (mmio_rsp_en)
        begin
            // VTP MMIO read response
            mmio64_source.readdatavalid <= 1'b1;
            mmio64_source.readdata <= mmio_rsp_data;
            mmio64_source.response <= '0;
            mmio64_source.readresponseuser <= mmio_rsp_user;
        end
        else
        begin
            // AFU MMIO read response
            mmio64_source.readdatavalid <= mmio64_sink.readdatavalid;
            mmio64_source.readdata <= mmio64_sink.readdata;
            mmio64_source.response <= mmio64_sink.response;
            mmio64_source.readresponseuser <= mmio64_sink.readresponseuser;
        end

        mmio64_source.writeresponsevalid <= mmio64_sink.writeresponsevalid;
        mmio64_source.writeresponse <= mmio64_sink.writeresponse;
        mmio64_source.writeresponseuser <= mmio64_sink.writeresponseuser;
    end

endmodule // mpf_vtp_svc_ofs_avalon_mem_rdwr
