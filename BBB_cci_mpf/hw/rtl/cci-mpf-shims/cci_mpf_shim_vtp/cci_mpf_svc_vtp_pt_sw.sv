//
// Copyright (c) 2019, Intel Corporation
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
`include "cci_mpf_csrs.vh"

`include "cci_mpf_shim_vtp.vh"


//
// Page translation service that uses software to translate virtual to
// physical addresses.
//

module cci_mpf_svc_vtp_pt_sw
  #(
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Primary interface
    cci_mpf_shim_vtp_pt_walk_if.server pt_walk,

    // FIM interface for host I/O
    cci_mpf_shim_vtp_pt_fim_if.pt_walk pt_fim,

    // CSRs
    cci_mpf_csrs.vtp csrs,

    // Events
    cci_mpf_csrs.vtp_events_pt_walk events
    );

    logic pt_sw_rdy;

    // Page translation request buffer's physical address.
    t_cci_clAddr pt_req_buf_pa;
    logic initialized;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            initialized <= 1'b0;
            pt_sw_rdy <= 1'b0;
        end
        else
        begin
            if (csrs.vtp_in_page_translation_buf_paddr_valid)
            begin
                initialized <= 1'b1;
                pt_req_buf_pa <= csrs.vtp_in_page_translation_buf_paddr;
            end

            // Send requests only when the request buffer is initialized
            // and VTP is enabled.
            pt_sw_rdy <= initialized && csrs.vtp_in_mode.enabled;
        end
    end


    // ====================================================================
    //
    //   Handle incoming requests.
    //
    // ====================================================================

    //
    // Incoming requests first go in a register. The protocol can accept
    // a new request at most every other cycle, which is plenty for a
    // service that will send its requests to software.
    //
    logic req_valid;
    logic send_req;
    t_tlb_4kb_va_page_idx req_va;
    t_cci_mpf_shim_vtp_pt_walk_meta req_meta;
    t_cci_mpf_shim_vtp_req_tag req_tag;

    assign pt_walk.reqRdy = ~req_valid;

    always_ff @(posedge clk)
    begin
        if (pt_walk.reqEn)
        begin
            req_valid <= 1'b1;
            req_va <= pt_walk.reqVA;
            req_meta <= pt_walk.reqMeta;
            req_tag <= pt_walk.reqTag;
        end

        if (reset || send_req)
        begin
            req_valid <= 1'b0;
        end
    end


    //
    // Requests will be processed FIFO. Store request metadata in a FIFO
    // to avoid sending it to the host. This FIFO also serves as a rate
    // limiter on the use of the request ring buffer. It ensures that
    // few enough requests are in flight to avoid overwriting requests
    // in the ring buffer.
    //

    logic req_not_full;
    logic req_not_empty;

    logic rsp_en;
    t_tlb_4kb_va_page_idx rsp_va;
    t_cci_mpf_shim_vtp_pt_walk_meta rsp_meta;
    t_cci_mpf_shim_vtp_req_tag rsp_tag;

    assign send_req = req_valid && req_not_full &&
                      pt_sw_rdy && pt_fim.writeRdy;

    cci_mpf_prim_fifo_lutram
      #(
        .N_DATA_BITS($bits(t_tlb_4kb_va_page_idx) +
                     $bits(t_cci_mpf_shim_vtp_pt_walk_meta) +
                     $bits(t_cci_mpf_shim_vtp_req_tag)),
        .N_ENTRIES(8),
        .REGISTER_OUTPUT(1)
        )
       req_fifo
        (
         .clk,
         .reset,

         .enq_data({ req_va, req_meta, req_tag }),
         .enq_en(send_req),
         .notFull(req_not_full),
         .almostFull(),

         .first({ rsp_va, rsp_meta, rsp_tag }),
         .deq_en(rsp_en),
         .notEmpty(req_not_empty)
         );


    // ====================================================================
    //
    //  Send requests to the host.
    //
    // ====================================================================

    //
    // Requests are written to the first 64 bit word in a single 4KB page
    // ring buffer. The req_fifo above limits the number of outstanding
    // requests to avoid overwriting active requests.
    //

    // Line index in the request ring buffer
    logic [5:0] req_ring_idx;

    assign pt_fim.readEn = 1'b0;

    always_ff @(posedge clk)
    begin
        pt_fim.writeEn <= send_req;

        // The ring buffer address must be page-aligned, so just replace
        // the low bits with the ring entry index.
        pt_fim.writeAddr <= pt_req_buf_pa;
        pt_fim.writeAddr[5:0] <= req_ring_idx;

        // Send the request as a standard virtual address. The low
        // bit is forced to one in case a NULL pointer is sent.
        // Of course NULL will result in an error, but this way it
        // will be detected.
        pt_fim.writeData <=
            { req_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b1 };

        if (send_req)
        begin
            req_ring_idx <= req_ring_idx + 6'b1;
        end

        // Clear the counter on reset and when the request buffer address
        // changes.
        if (reset || csrs.vtp_in_page_translation_buf_paddr_valid)
        begin
            req_ring_idx <= 6'b0;
        end
    end


    // ====================================================================
    //
    //  Forward responses from the host.
    //
    // ====================================================================

    logic rsp_valid;
    t_tlb_4kb_pa_page_idx rsp_pa;
    logic rsp_not_present;
    logic rsp_is_big_page;

    assign rsp_en = rsp_valid && req_not_empty;

    always_ff @(posedge clk)
    begin
        rsp_valid <= csrs.vtp_in_page_translation_rsp_valid;
        rsp_pa <= vtp4kbPageIdxFromPA(csrs.vtp_in_page_translation_rsp);

        // Encode failed translation in bit 0
        rsp_not_present <= csrs.vtp_in_page_translation_rsp[0] &&
                           csrs.vtp_in_page_translation_rsp_valid;

        // Encode page size in bit 1
        rsp_is_big_page <= csrs.vtp_in_page_translation_rsp[1];

        if (reset)
        begin
            rsp_valid <= 1'b0;
        end
    end

    always_ff @(posedge clk)
    begin
        pt_walk.rspEn <= rsp_en;
        pt_walk.rspVA <= rsp_va;
        pt_walk.rspPA <= rsp_pa;
        pt_walk.rspMeta <= rsp_meta;
        pt_walk.rspTag <= rsp_tag;
        pt_walk.rspIsBigPage <= rsp_is_big_page;
        pt_walk.rspNotPresent <= rsp_not_present;
    end

    // Statistics and events
    always_ff @(posedge clk)
    begin
        events.vtp_out_event_pt_walk_busy <= req_not_empty;
        events.vtp_out_event_failed_translation <= rsp_not_present && rsp_en;

        if (send_req)
        begin
            events.vtp_out_pt_walk_last_vaddr <= { req_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0) };
        end

        if (reset)
        begin
            events.vtp_out_pt_walk_last_vaddr <= 0;
        end
    end


    // ====================================================================
    //
    //  Debugging
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        if (! reset && DEBUG_MESSAGES)
        begin
            // synthesis translate_off
            if (send_req)
            begin
                $display("VTP PT WALK %0t: New REQ translate VA 0x%x (line 0x%x), tag (%0d, %0d)",
                         $time,
                         { req_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0 },
                         { req_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0) },
                         req_meta, req_tag);
            end

            if (rsp_en)
            begin
                $display("VTP PT WALK %0t: Completed RESP PA 0x%x (line 0x%x), VA 0x%x (line 0x%x), tag (%0d, %0d), %0s",
                         $time,
                         { rsp_pa, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0 },
                         { rsp_pa, CCI_PT_4KB_PAGE_OFFSET_BITS'(0) },
                         { rsp_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0 },
                         { rsp_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0) },
                         rsp_meta, rsp_tag,
                         (rsp_is_big_page ? "2MB" : "4KB"));
            end
            // synthesis translate_on
        end
    end

endmodule // cci_mpf_svc_vtp_pt_sw

