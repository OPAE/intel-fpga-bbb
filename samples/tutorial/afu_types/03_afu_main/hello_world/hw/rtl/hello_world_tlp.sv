// Copyright 2022 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

//
// A very simple implemenation of hello world on PCIe SS TLP encoded AXI
// streams. The implementation here is not pipelined and generates only
// very short data writes. It demonstrates the mechanics of the minimally
// required transactions to receive a command that triggers a request
// from the FPGA.
//

`include "afu_json_info.vh"

module hello_world_tlp
  #(
    parameter pcie_ss_hdr_pkg::ReqHdr_pf_num_t PF_ID,
    parameter pcie_ss_hdr_pkg::ReqHdr_vf_num_t VF_ID,
    parameter logic VF_ACTIVE
    )  
   (
    input  logic clk,
    input  logic rst_n,

    pcie_ss_axis_if.sink   i_rx_if,
    pcie_ss_axis_if.source o_tx_if,

    // These ports will be tied off and not used
    pcie_ss_axis_if.sink   i_rx_b_if,
    pcie_ss_axis_if.source o_tx_b_if
    );

    // Register the PCIe ports for timing. Not pipelined, so low throughput.
    pcie_ss_axis_if rx_st(clk, rst_n);
    pcie_ss_axis_if tx_st(clk, rst_n);

    assign i_rx_if.tready = ~rx_st.tvalid;

    always_ff @(posedge clk)
    begin
        if (rx_st.tvalid && rx_st.tready)
        begin
            rx_st.tvalid <= 1'b0;
        end
        if (i_rx_if.tready)
        begin
            rx_st.tvalid <= i_rx_if.tvalid;
            rx_st.tlast <= i_rx_if.tlast;
            rx_st.tdata <= i_rx_if.tdata;
            rx_st.tkeep <= i_rx_if.tkeep;
            rx_st.tuser_vendor <= i_rx_if.tuser_vendor;
        end

        if (!rst_n)
        begin
            rx_st.tvalid <= 1'b0;
        end
    end

    assign tx_st.tready = ~o_tx_if.tvalid;

    always_ff @(posedge clk)
    begin
        if (o_tx_if.tvalid && o_tx_if.tready)
        begin
            o_tx_if.tvalid <= 1'b0;
        end
        if (tx_st.tready)
        begin
            o_tx_if.tvalid <= tx_st.tvalid;
            o_tx_if.tlast <= tx_st.tlast;
            o_tx_if.tdata <= tx_st.tdata;
            o_tx_if.tkeep <= tx_st.tkeep;
            o_tx_if.tuser_vendor <= tx_st.tuser_vendor;
        end

        if (!rst_n)
        begin
            o_tx_if.tvalid <= 1'b0;
        end
    end


    //
    // Watch for MMIO read requests on the RX stream.
    //

    pcie_ss_hdr_pkg::PCIe_PUReqHdr_t rx_hdr;
    logic [255:0] rx_data;
    logic rx_hdr_valid;
    logic rx_sop;

    assign rx_st.tready = !rx_hdr_valid;

    // Incoming MMIO read?
    always_ff @(posedge clk)
    begin
        if (rx_st.tready)
        begin
            rx_hdr_valid <= 1'b0;

            if (rx_st.tvalid)
            begin
                rx_sop <= rx_st.tlast;

                // Only power user mode requests are detected. CSR requests
                // from the host will always be PU encoded.
                if (rx_sop && pcie_ss_hdr_pkg::func_hdr_is_pu_mode(rx_st.tuser_vendor))
                begin
                    {rx_data, rx_hdr} <= rx_st.tdata;
                    rx_hdr_valid <= 1'b1;
                end
            end
        end
        else if (tx_st.tready)
        begin
            // If a request was present, it was consumed
            rx_hdr_valid <= 1'b0;
        end

        if (!rst_n)
        begin
            rx_hdr_valid <= 1'b0;
            rx_sop <= 1'b1;
        end
    end

    // Construct MMIO completion in response to RX read request
    pcie_ss_hdr_pkg::PCIe_PUCplHdr_t tx_cpl_hdr;
    localparam TX_CPL_HDR_BYTES = $bits(pcie_ss_hdr_pkg::PCIe_PUCplHdr_t) / 8;

    always_comb
    begin
        // Build the header -- always the same for any address
        tx_cpl_hdr = '0;
        tx_cpl_hdr.fmt_type = pcie_ss_hdr_pkg::ReqHdr_FmtType_e'(pcie_ss_hdr_pkg::PCIE_FMTTYPE_CPLD);
        tx_cpl_hdr.length = rx_hdr.length;
        tx_cpl_hdr.req_id = rx_hdr.req_id;
        tx_cpl_hdr.tag_h = rx_hdr.tag_h;
        tx_cpl_hdr.tag_m = rx_hdr.tag_m;
        tx_cpl_hdr.tag_l = rx_hdr.tag_l;
        tx_cpl_hdr.TC = rx_hdr.TC;
        tx_cpl_hdr.byte_count = rx_hdr.length << 2;
        tx_cpl_hdr.low_addr[6:2] =
            pcie_ss_hdr_pkg::func_is_addr64(rx_hdr.fmt_type) ?
                rx_hdr.host_addr_l[4:0] : rx_hdr.host_addr_h[6:2];

        tx_cpl_hdr.comp_id = { VF_ID, VF_ACTIVE, PF_ID };
        tx_cpl_hdr.pf_num = PF_ID;
        tx_cpl_hdr.vf_num = VF_ID;
        tx_cpl_hdr.vf_active = VF_ACTIVE;
    end

    logic [63:0] cpl_data;
    logic [127:0] afu_id = `AFU_ACCEL_UUID;

    // Completion data. There is minimal address decoding here to keep
    // it simple. Location 0 needs a device feature header and an AFU
    // ID is set.
    always_comb
    begin
        case (tx_cpl_hdr.low_addr[6:3])
            // AFU DFH
            4'h0:
                begin
                    cpl_data[63:0] = '0;
                    // Feature type is AFU
                    cpl_data[63:60] = 4'h1;
                    // End of list
                    cpl_data[40] = 1'b1;
                end

            // AFU_ID_L
            4'h1: cpl_data[63:0] = afu_id[63:0];

            // AFU_ID_H
            4'h2: cpl_data[63:0] = afu_id[127:64];

            default: cpl_data[63:0] = '0;
        endcase

        // Was the request short, asking for the high 32 bits of the 64 bit register?
        if (tx_cpl_hdr.low_addr[2])
        begin
            cpl_data[31:0] = cpl_data[63:32];
        end
    end


    //
    // Generate a DMA write with the string "Hello world TLP!" in response to a
    // CSR write to any address. The payload of the CSR write holds the line offset
    // to which the string should be written.
    //
    // Of course a real AFU would have to decode the address of the CSR write
    // if it has more than 1 CSR.
    //
    wire gen_dma_write = rx_hdr_valid && pcie_ss_hdr_pkg::func_is_mwr_req(rx_hdr.fmt_type);
    pcie_ss_hdr_pkg::PCIe_ReqHdr_t tx_wr_hdr;

    // Data mover write request header to the address that just arrived in the
    // payload of an incoming CSR write.
    always_comb
    begin
        tx_wr_hdr = '0;
        tx_wr_hdr.fmt_type = pcie_ss_hdr_pkg::DM_WR;
        tx_wr_hdr.pf_num = PF_ID;
        tx_wr_hdr.vf_num = VF_ID;
        tx_wr_hdr.vf_active = VF_ACTIVE;
        {tx_wr_hdr.length_h, tx_wr_hdr.length_m, tx_wr_hdr.length_l} = 20; // Bytes
        // The incoming address is the offset of 512 bit lines. Shift it left
        // because DM encoding expects a byte address.
        {tx_wr_hdr.host_addr_h, tx_wr_hdr.host_addr_m, tx_wr_hdr.host_addr_l} =
            {rx_data[57:0], 6'b0};
    end


    // Generate traffic toward the host for CSR read response and writing
    // the hello world message.
    always_comb
    begin
        tx_st.tvalid = (rx_hdr_valid &&
                        pcie_ss_hdr_pkg::func_is_mrd_req(rx_hdr.fmt_type)) || gen_dma_write;
        if (!gen_dma_write)
        begin
            //
            // CSR read response
            //

            tx_st.tdata = { '0, cpl_data, tx_cpl_hdr };
            tx_st.tlast = 1'b1;
            tx_st.tuser_vendor = '0;
            // Keep matches the data: either 8 or 4 bytes of data and the header
            tx_st.tkeep = { '0, {4{(rx_hdr.length > 1)}}, {4{1'b1}}, {TX_CPL_HDR_BYTES{1'b1}} };
        end
        else
        begin
            //
            // DMA write with "Hello world TLP!" payload. The payload and header
            // fit in a single message, which simplifies the logic here.
            //

            // "Hello world TLP!", ASCII encoded and backwards
            tx_st.tdata = { '0, 160'h0021504c5420646c726f77206f6c6c6548, tx_wr_hdr };
            tx_st.tlast = 1'b1;
            tx_st.tuser_vendor = 1;	// Data mover encoding
            tx_st.tkeep = { '0, {20{1'b1}}, {TX_CPL_HDR_BYTES{1'b1}} };
        end
    end

    // Tie off the B ports
    assign i_rx_b_if.tready = 1'b1;
    assign o_tx_b_if.tvalid = 1'b0;

endmodule
