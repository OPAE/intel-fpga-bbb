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
// The VTP CSR interface exports a simple mpf_services_gen_csr_if to the AFU.
// The generic interface is just a vector of same-size read/write ports.
// The code here maps I/O on the vector to behavior inside VTP.
//
// Connecting the generic CSR read/write interface to MMIO operations is the
// responsibility of logic outside the VTP service.
//

`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

// Convert a CSR byte offset to a local 64-bit index
`define VTP_CSR_IDX(byte_offset) LOCAL_ADDR_BITS'(byte_offset >> 3)

// Group of generic event counters. This macro differs from MPF_CSR_STAT_ACCUM
// only in the naming of the incoming event port.
`define VTP_CSR_STAT_ACCUM_GROUP(N_BITS, GROUP, NAME) \
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
                .incr_by(N_BITS'(events.``GROUP``.NAME)), \
                .value(``GROUP``_``NAME``_accum) \
                ); \
        end \
    endgenerate

module mpf_vtp_csr
  #(
    parameter ENABLE_VTP = 0
    )
   (
    input  clk,
    input  reset,

    // Public, generic interface. The AFU will map this into MMIO space.
    mpf_services_gen_csr_if.to_master gen_csr_if,

    // VTP's private, internal CSR space.
    mpf_vtp_csrs_if.csr csrs,
    mpf_vtp_csrs_if.csr_events events
    );

    import mpf_vtp_pkg::*;

    localparam MPF_ENABLE_SHIM = ENABLE_VTP;
    localparam LOCAL_ADDR_BITS = $bits(gen_csr_if.csr_req_idx);

    // synthesis translate_off
    initial
    begin
        // VTP CSR region size size (bytes) should match the number of bits
        // in the address index. (Each index represents a 64 bit entry.)
        assert((CCI_MPF_VTP_CSR_SIZE / 8) == (1 << LOCAL_ADDR_BITS)) else
          $fatal("** ERROR ** %m: CCI_MPF_VTP_CSR_SIZE (%0d) doesn't match CSR index size (%0d bits)",
                 CCI_MPF_VTP_CSR_SIZE, LOCAL_ADDR_BITS);
    end
    // synthesis translate_on

    logic [127:0] shim_uuid;
    assign shim_uuid = (ENABLE_VTP ? 128'hc8a2982f_ff96_42bf_a705_45727f501901 :
                                     128'b0);

    // Event counters
    `VTP_CSR_STAT_ACCUM_GROUP(54, vtp_tlb_events, hit_4kb);
    `VTP_CSR_STAT_ACCUM_GROUP(54, vtp_tlb_events, miss_4kb);
    `VTP_CSR_STAT_ACCUM_GROUP(54, vtp_tlb_events, hit_2mb);
    `VTP_CSR_STAT_ACCUM_GROUP(54, vtp_tlb_events, miss_2mb);
    `VTP_CSR_STAT_ACCUM_GROUP(54, vtp_pt_walk_events, busy);
    `VTP_CSR_STAT_ACCUM_GROUP(54, vtp_pt_walk_events, failed_translation);

    // Select a register to read
    always_ff @(posedge clk)
    begin
        gen_csr_if.rd_rsp_valid <= gen_csr_if.rd_req_en;

        case (gen_csr_if.csr_req_idx)
            // DFH
          LOCAL_ADDR_BITS'(0):
            // Master sets the DFH value since only it knows the MMIO addresses
            gen_csr_if.rd_data <= gen_csr_if.dfh_value;

            // BBB ID
          LOCAL_ADDR_BITS'(1):
            gen_csr_if.rd_data <= shim_uuid[63:0];
          LOCAL_ADDR_BITS'(2):
            gen_csr_if.rd_data <= shim_uuid[127:64];

            // CSRs
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_MODE):
            gen_csr_if.rd_data <= 64'(csrs.vtp_out_mode);
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_STAT_4KB_TLB_NUM_HITS):
            gen_csr_if.rd_data <= 64'(vtp_tlb_events_hit_4kb_accum);
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_STAT_4KB_TLB_NUM_MISSES):
            gen_csr_if.rd_data <= 64'(vtp_tlb_events_miss_4kb_accum);
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_STAT_2MB_TLB_NUM_HITS):
            gen_csr_if.rd_data <= 64'(vtp_tlb_events_hit_2mb_accum);
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_STAT_2MB_TLB_NUM_MISSES):
            gen_csr_if.rd_data <= 64'(vtp_tlb_events_miss_2mb_accum);
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_STAT_PT_WALK_BUSY_CYCLES):
            gen_csr_if.rd_data <= 64'(vtp_pt_walk_events_busy_accum);
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_STAT_FAILED_TRANSLATIONS):
            gen_csr_if.rd_data <= 64'(vtp_pt_walk_events_failed_translation_accum);
          `VTP_CSR_IDX(CCI_MPF_VTP_CSR_STAT_PT_WALK_LAST_VADDR):
            gen_csr_if.rd_data <= 64'(events.vtp_pt_walk_events.last_vaddr);

          default:
            gen_csr_if.rd_data <= 64'b0;
        endcase
    end


    //
    // CSR writes
    //

    // Address computation and buffering for CSR writes
    logic wr_req_en_q;
    logic [$bits(gen_csr_if.wr_data)-1 : 0] wr_data_q;
    logic [LOCAL_ADDR_BITS-1 : 0] wr_idx_q;

    always_ff @(posedge clk)
    begin
        wr_req_en_q <= gen_csr_if.wr_req_en;
        wr_data_q <= gen_csr_if.wr_data;
        wr_idx_q <= gen_csr_if.csr_req_idx;
    end

    always_ff @(posedge clk)
    begin
        if (wr_req_en_q &&
            (wr_idx_q == `VTP_CSR_IDX(CCI_MPF_VTP_CSR_MODE)))
        begin
            csrs.vtp_ctrl.in_mode <= t_mpf_vtp_csr_in_mode'(wr_data_q);
        end
        else
        begin
            // Invalidate page table held only one cycle
            csrs.vtp_ctrl.in_mode.inval_translation_cache <= 1'b0;
        end

        if (wr_req_en_q &&
            (wr_idx_q == `VTP_CSR_IDX(CCI_MPF_VTP_CSR_PAGE_TABLE_PADDR)))
        begin
            csrs.vtp_ctrl.page_table_base <= t_cci_clAddr'(wr_data_q);
            csrs.vtp_ctrl.page_table_base_valid <= 1'b1;
        end

        // Inval page held only one cycle
        csrs.vtp_ctrl.inval_page <= t_cci_clAddr'(wr_data_q);
        csrs.vtp_ctrl.inval_page_valid <=
            wr_req_en_q &&
            (wr_idx_q == `VTP_CSR_IDX(CCI_MPF_VTP_CSR_INVAL_PAGE_VADDR));

        // Page translation service ring buffer (held only one cycle)
        csrs.vtp_ctrl.page_translation_buf_paddr <= t_cci_clAddr'(wr_data_q);
        csrs.vtp_ctrl.page_translation_buf_paddr_valid <=
            wr_req_en_q &&
            (wr_idx_q == `VTP_CSR_IDX(CCI_MPF_VTP_CSR_PAGE_TRANSLATION_BUF_PADDR));

        // Page translation response (held only one cycle)
        csrs.vtp_ctrl.page_translation_rsp <= t_cci_clAddr'(wr_data_q);
        csrs.vtp_ctrl.page_translation_rsp_valid <=
            wr_req_en_q &&
            (wr_idx_q == `VTP_CSR_IDX(CCI_MPF_VTP_CSR_PAGE_TRANSLATION_RSP));

        if (reset)
        begin
            csrs.vtp_ctrl.in_mode <= t_mpf_vtp_csr_in_mode'(0);
            csrs.vtp_ctrl.page_table_base_valid <= 1'b0;
            csrs.vtp_ctrl.inval_page_valid <= 1'b0;
            csrs.vtp_ctrl.page_translation_buf_paddr_valid <= 1'b0;
            csrs.vtp_ctrl.page_translation_rsp_valid <= 1'b0;
        end
    end

endmodule // mpf_vtp_csr
