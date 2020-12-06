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
// Protocol-independent wrapper for mapping MMIO requests to VTP server
// CSR I/O.
//

`include "ofs_plat_if.vh"
`include "cci_mpf_csrs.vh"

module mpf_vtp_svc_mmio
  #(
    // Instance ID reported in feature IDs of all device feature
    // headers instantiated under this instance of MPF.
    parameter MPF_INSTANCE_ID = 1,

    // MMIO base address (byte level) allocated to VTP for feature lists
    // and CSRs.
    parameter DFH_MMIO_BASE_ADDR = 0,

    // Address of the next device feature header outside VTP.
    parameter DFH_MMIO_NEXT_ADDR = 0,

    // Address width of MMIO when addressing 64 bit objects. (The usual
    // CCI-P address space is 32 bit objects.)
    parameter MMIO64_ADDR_WIDTH = CCIP_MMIOADDR_WIDTH - 1,

    parameter MMIO64_TID_WIDTH = $bits(t_ccip_tid)
    )
   (
    input  logic clk,
    input  logic reset,

    // Incoming MMIO write and read requests for 64 bit CSRs
    input  logic [MMIO64_ADDR_WIDTH-1 : 0] csr_addr,

    input  logic write_req,
    input  logic [63:0] write_data,

    input  logic read_req,
    input  logic [MMIO64_TID_WIDTH-1 : 0] read_tid_in,
    output logic read_rsp,
    output logic [MMIO64_TID_WIDTH-1 : 0] read_tid_out,
    output logic [63:0] read_data,
    // Read responses sit in an output FIFO until read_deq is set
    input  logic read_deq,

    // The is_vtp_mmio flag is set in the same cycle that read_req or
    // write_req is set and the csr_addr is inside the MMIO address
    // range managed by VTP. The flag can be used to prevent forwarding
    // of the request to other MMIO handlers.
    output logic is_vtp_mmio,

    // Connection to VTP server's internal CSR manager
    mpf_services_gen_csr_if.to_slave vtp_csrs
    );

    // Address of a VTP csr index in 64 bit data space
    typedef logic [$clog2(CCI_MPF_VTP_CSR_SIZE >> 3)-1 : 0] t_vtp_mmio_idx;

    localparam DFH_VTP_END_ADDR = DFH_MMIO_BASE_ADDR + CCI_MPF_VTP_CSR_SIZE;

    logic [MMIO64_ADDR_WIDTH-1 : 0] csr_addr_q;
    t_vtp_mmio_idx csr_idx_qq;

    logic write_req_q, write_req_qq;
    logic [63:0] write_data_q, write_data_qq;
    logic read_req_q, read_req_qq;
    logic [MMIO64_TID_WIDTH-1 : 0] read_tid_in_q, read_tid_in_qq, read_tid_in_qqq;

    always_ff @(posedge clk)
    begin
        // First stage -- just register
        csr_addr_q <= csr_addr;
        write_req_q <= write_req;
        write_data_q <= write_data;
        read_req_q <= read_req;
        read_tid_in_q <= read_tid_in;

        // Second stage splits out the MMIO address so 0 is DFH_MMIO_BASE_ADDR.
        // The address is also reduced to indexing only the MPF CSR region in
        // 64 bit chunks.
        write_data_qq <= write_data_q;
        read_tid_in_qq <= read_tid_in_q;
        csr_idx_qq <= 
            t_vtp_mmio_idx'(csr_addr_q - t_ccip_mmioAddr'(DFH_MMIO_BASE_ADDR >> 3));
        // If requested address is outside VTP's CSR region ignore it.
        // MMIO addresses drop the low 3 bits since the address is to 64
        // bit objects.
        write_req_qq <= write_req_q;
        read_req_qq <= read_req_q;
        if ((csr_addr_q < t_ccip_mmioAddr'(DFH_MMIO_BASE_ADDR >> 3)) ||
            (csr_addr_q >= t_ccip_mmioAddr'(DFH_VTP_END_ADDR >> 3)))
        begin
            write_req_qq <= 1'b0;
            read_req_qq <= 1'b0;
        end

        read_tid_in_qqq <= read_tid_in_qq;
    end

    // Is the request to the VTP region?
    assign is_vtp_mmio =
        (write_req || read_req) &&
        ((csr_addr >= t_ccip_mmioAddr'(DFH_MMIO_BASE_ADDR >> 3)) &&
         (csr_addr < t_ccip_mmioAddr'(DFH_VTP_END_ADDR >> 3)));

    // The DFH is generated here since the code here knows the MMIO address
    // space layout and VTP does not.
    assign vtp_csrs.dfh_value =
        ccip_dfh_genDFH(DFH_MMIO_NEXT_ADDR - DFH_MMIO_BASE_ADDR,
                        MPF_INSTANCE_ID,
                        DFH_MMIO_NEXT_ADDR == 0);

    // Connect requests to the VTP CSR service
    assign vtp_csrs.csr_req_idx = csr_idx_qq;
    assign vtp_csrs.rd_req_en = read_req_qq;
    assign vtp_csrs.wr_req_en = write_req_qq;
    assign vtp_csrs.wr_data = write_data_qq;

    // Push read responses into a FIFO so they can be merged with other MMIO
    // read responses coming from the AFU.
    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS(MMIO64_TID_WIDTH + 64),
        .N_ENTRIES(64),
        .REGISTER_OUTPUT(1)
        )
      mmio_rsp_fifo
        (
         .clk,
         .reset,
         .enq_data({ read_tid_in_qqq, vtp_csrs.rd_data }),
         .enq_en(vtp_csrs.rd_rsp_valid),
         .notFull(),
         .almostFull(),
         .first({ read_tid_out, read_data }),
         .deq_en(read_deq),
         .notEmpty(read_rsp)
         );

endmodule // mpf_vtp_svc_mmio
