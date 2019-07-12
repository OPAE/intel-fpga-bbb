//
// Copyright (c) 2016, Intel Corporation
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

`include "cci_mpf_config.vh"

`include "cci_mpf_shim_vtp.vh"
`include "cci_mpf_prim_hash.vh"


//
// Page table walker for handling virtual to physical TLB misses.
//
// The walker receives requests from the TLB when a translation is not present
// in the TLB.
//
// The table being walked is constructed by software.  The format is
// is described in SW/src/cci_mpf_shim_vtp_pt.cpp.
//


// Hierarchical page table is composed of 4KB pages, each with 512
// 64 bit pointers either to the translated PA or to the next page
// in the page table.  Each index is thus 9 bits.
localparam CCI_MPF_PT_PAGE_IDX_WIDTH = 9;
typedef logic [CCI_MPF_PT_PAGE_IDX_WIDTH-1 : 0] t_cci_mpf_pt_page_idx;

// Maximum depth (levels of indirection) in the page table.
localparam CCI_MPF_PT_MAX_DEPTH = 4;
typedef logic [$clog2(CCI_MPF_PT_MAX_DEPTH)-1 : 0] t_cci_mpf_pt_walk_depth;

// Vector of page indices, representing the set of indices used in a
// hierarchical page table walk.
typedef t_cci_mpf_pt_page_idx [CCI_MPF_PT_MAX_DEPTH-1 : 0] t_cci_mpf_pt_page_idx_vec;


//
// Status bits in the low bits of a page table entry.
//
typedef struct packed
{
    // Translation error (no translation found)
    logic error;

    // Terminal entry found (the translation)
    logic terminal;
}
t_cci_mpf_pt_walk_status;

function automatic t_cci_mpf_pt_walk_status cci_mpf_ptWalkWordToStatus(logic [63:0] w);
    t_cci_mpf_pt_walk_status s;

    // The SW initializes entries to ~0.  Check bit 3 as a proxy for
    // the entire entry being invalid.  Bits 0-2 are used as flags.
    s.error = w[3];

    // Bit 0 in the response word indicates a successful translation.
    s.terminal = w[0];

    return s;
endfunction


module cci_mpf_svc_vtp_pt_walk
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

    initial begin
        // Confirm that the VA size specified in VTP matches CCI.  The CCI
        // version is line addresses, so the units must be converted.
        assert (CCI_MPF_CLADDR_WIDTH + $clog2(CCI_CLDATA_WIDTH >> 3) ==
                48) else
            $fatal("cci_mpf_svc_vtp_pt_walk.sv: VA address size mismatch!");
    end

    // Root address of the page table
    t_tlb_4kb_pa_page_idx page_table_root;
    assign page_table_root = vtp4kbPageIdxFromPA(csrs.vtp_in_page_table_base);

    logic initialized;
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            initialized <= 1'b0;
        end
        else
        begin
            initialized <= csrs.vtp_in_page_table_base_valid;
        end
    end


    // ====================================================================
    //
    //   Page table properties.
    //
    // ====================================================================

    // Page index components: line address and word within line
    localparam PT_WORDS_PER_LINE = CCI_CLDATA_WIDTH / 64;
    localparam PT_LINE_WORD_IDX_WIDTH = $clog2(PT_WORDS_PER_LINE);
    typedef logic [PT_LINE_WORD_IDX_WIDTH-1 : 0] t_pt_line_word_idx;

    localparam PT_PAGE_LINE_IDX_WIDTH = CCI_MPF_PT_PAGE_IDX_WIDTH - PT_LINE_WORD_IDX_WIDTH;
    typedef logic [PT_PAGE_LINE_IDX_WIDTH-1 : 0] t_pt_page_line_idx;

    typedef struct packed
    {
        // Index of a line within a 4KB page table
        t_pt_page_line_idx line_idx;
        // Index of a word within the line
        t_pt_line_word_idx word_idx;
    }
    t_pt_page_idx;

    function automatic t_pt_page_line_idx ptPageLineIdx(
        t_cci_mpf_pt_page_idx_vec pidx_vec
        );

        t_pt_page_idx pidx = pidx_vec[0];
        return pidx.line_idx;
    endfunction

    function automatic t_pt_line_word_idx ptLineWordIdx(
        t_cci_mpf_pt_page_idx_vec pidx_vec
        );

        t_pt_page_idx pidx = pidx_vec[0];
        return pidx.word_idx;
    endfunction


    // ====================================================================
    //
    //   FIM page table read interface.
    //
    // ====================================================================

    // A sub-module manages access to the page table read interface.
    // It includes a simple prefetch engine that reduces latency on
    // serial accesses to 4KB pages.

    cci_mpf_shim_vtp_pt_fim_if pt_walk_reader();

    cci_mpf_svc_vtp_pt_walk_reader
      #(
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      rd_with_prefetch
       (
        .clk,
        .reset,
        .pt_walk_reader,
        .pt_fim,
        .csrs
        );


    // ====================================================================
    //
    //   Page walker state machine.
    //
    // ====================================================================

    typedef enum logic [3:0]
    {
        STATE_PT_WALK_IDLE,
        STATE_PT_WALK_READ_CACHE_REQ,
        STATE_PT_WALK_READ_CACHE_RSP,
        STATE_PT_WALK_READ_CACHE_RETRY,
        STATE_PT_WALK_READ_REQ,
        STATE_PT_WALK_READ_WAIT_RSP,
        STATE_PT_WALK_READ_RSP,
        STATE_PT_WALK_DONE,
        STATE_PT_WALK_ERROR,
        STATE_PT_WALK_SPEC_ERROR,
        STATE_PT_WALK_HALT
    }
    t_state_pt_walk;

    t_state_pt_walk state;

    // Single-bit registers corresponding to states. Using these helps
    // some critical timing paths.
    logic state_is_walk_idle;

    logic rsp_en;

    //
    // The miss handler supports processing only one request at a time.
    //
    assign pt_walk.reqRdy = initialized && state_is_walk_idle;

    // Base address of current page being accessed.  During a walk pt_cur_page
    // points to pages in the page table.  When translation is complete it
    // points to the translated physical page.
    t_tlb_4kb_pa_page_idx pt_walk_cur_page;
    t_tlb_4kb_pa_page_idx pt_walk_next_page;

    t_cci_mpf_pt_walk_status pt_walk_cur_status;

    // Selected word within the response line
    logic [63 : 0] pt_read_rsp_word;

    // VA being translated
    t_tlb_4kb_va_page_idx translate_va;

    // Metadata associated with translation request
    t_cci_mpf_shim_vtp_pt_walk_meta req_meta;
    logic req_isSpeculative;
    t_cci_mpf_shim_vtp_req_tag req_tag;

    // During translation the VA is broken down into 9 bit indices during
    // the tree-based page walk.  This register is shifted as each level
    // is traversed, leaving the next index in the high bits.
    t_cci_mpf_pt_page_idx_vec translate_va_idx_vec;
    t_cci_mpf_pt_page_idx_vec translate_va_lower_idx_vec;
    
    // High bits of the requested VA are the page table indices
    t_cci_mpf_pt_page_idx_vec req_va_as_idx_vec;
    assign req_va_as_idx_vec = pt_walk.reqVA[($bits(pt_walk.reqVA)-1) -:
                                             $bits(t_cci_mpf_pt_page_idx_vec)];


    // Track the depth while walking the table.  This is one way of detecting
    // a malformed table or missing entry.
    t_cci_mpf_pt_walk_depth translate_depth;

    //
    // Add a register stage to incoming read responses to relax timing.
    //
    t_cci_clData ptReadData_q;
    logic [63 : 0] ptReadData_qq;    // Line reduced to a word
    logic ptReadDataEn_q, ptReadDataEn_qq;

    cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value ptReadDataTag_q, ptReadDataTag_qq;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            ptReadDataEn_q <= 1'b0;
            ptReadDataEn_qq <= 1'b0;
        end
        else
        begin
            ptReadDataEn_q <= pt_walk_reader.readDataEn;
            ptReadDataEn_qq <= ptReadDataEn_q;
        end

        ptReadData_q <= pt_walk_reader.readData;
        // pt_read_rsp_word is the word needed from ptReadData_q
        ptReadData_qq <= pt_read_rsp_word;

        ptReadDataTag_q <= pt_walk_reader.readRspTag;
        ptReadDataTag_qq <= ptReadDataTag_qq;
    end

    //
    // Cache of previous page table reads.  We don't rely on the small
    // QPI cache.  Instead, a small cache of recent page table lines is
    // maintained.
    //
    logic ptReadCacheRdy;
    logic ptReadCacheMissRsp;
    logic ptReadCacheHitRsp;
    t_tlb_4kb_pa_page_idx ptReadCachePage;
    t_cci_mpf_pt_walk_status ptReadCacheStatus;

    t_tlb_4kb_pa_page_idx pt_walk_cache_page;
    logic pt_walk_page_from_cache;

    cci_mpf_svc_vtp_pt_walk_cache
      #(
        .DEBUG_MESSAGES(DEBUG_MESSAGES)
        )
      cache
       (
        .clk,
        .reset,
        .csrs,

        .rdy(ptReadCacheRdy),

        // Request lookup
        .reqEn(ptReadCacheRdy && (state == STATE_PT_WALK_READ_CACHE_REQ)),
        .reqPageIdxVec(translate_va_idx_vec),
        .reqWalkDepth(translate_depth),

        // Lookup response
        .rspMiss(ptReadCacheMissRsp),
        .rspHit(ptReadCacheHitRsp),
        .rspPageAddr(ptReadCachePage),
        .rspStatus(ptReadCacheStatus),

        // Insert a new line in the cache
        .insertEn(ptReadDataEn_q),
        .insertData(ptReadData_q),
        .insertPageIdxVec(translate_va_idx_vec),
        .insertWalkDepth(translate_depth)
        );


    //
    // State transition.  One request is processed at a time.
    //
    always_ff @(posedge clk)
    begin
        case (state)
          STATE_PT_WALK_IDLE:
            begin
                // New request arrived and not already doing a walk
                if (pt_walk.reqEn)
                begin
                    state <= STATE_PT_WALK_READ_CACHE_REQ;
                    state_is_walk_idle <= 1'b0;

                    translate_va <= pt_walk.reqVA;
                    req_meta <= pt_walk.reqMeta;
                    req_isSpeculative <= pt_walk.reqIsSpeculative;
                    req_tag <= pt_walk.reqTag;
                end

                // New request: start by searching the local page table
                // cache (depth first).
                translate_va_idx_vec <= req_va_as_idx_vec;
                translate_depth <=
                    t_cci_mpf_pt_walk_depth'(CCI_MPF_PT_MAX_DEPTH - 1);

                pt_walk_cur_page <= page_table_root;
                rsp_en <= 1'b0;
            end

          STATE_PT_WALK_READ_CACHE_REQ:
            begin
                // Wait until a PT cache read request can fire
                if (ptReadCacheRdy)
                begin
                    state <= STATE_PT_WALK_READ_CACHE_RSP;
                end
            end

          STATE_PT_WALK_READ_CACHE_RSP:
            begin
                if (ptReadCacheMissRsp)
                begin
                    // Not in cache.
                    if (translate_depth != t_cci_mpf_pt_walk_depth'(0))
                    begin
                        // Try higher up in the page table hierarchy.
                        state <= STATE_PT_WALK_READ_CACHE_RETRY;
                    end
                    else
                    begin
                        // Reached the root of the table without finding
                        // the entry.  Read the from page table instead.
                        state <= STATE_PT_WALK_READ_REQ;
                    end
                end
                else if (ptReadCacheHitRsp)
                begin
                    // Hit!  No need to read from host memory.
                    state <= STATE_PT_WALK_READ_RSP;

                    pt_walk_cur_status <= ptReadCacheStatus;

                    pt_walk_page_from_cache <= 1'b1;
                    pt_walk_cache_page <= ptReadCachePage;
                end
            end

          STATE_PT_WALK_READ_CACHE_RETRY:
            begin
                // Shift to look higher up in the page table hierarchy.
                state <= STATE_PT_WALK_READ_CACHE_REQ;
                translate_depth <= translate_depth -
                                   t_cci_mpf_pt_walk_depth'(1);

                // Shift the page table index vector to represent
                // a higher level.
                for (int i = 0; i < CCI_MPF_PT_MAX_DEPTH-1; i = i + 1)
                begin
                    translate_va_idx_vec[i] <=
                        translate_va_idx_vec[i + 1];
                    translate_va_lower_idx_vec[i] <=
                        translate_va_lower_idx_vec[i + 1];
                end

                translate_va_idx_vec[CCI_MPF_PT_MAX_DEPTH-1] <=
                    t_cci_mpf_pt_page_idx'(0);

                // "Lower" vector holds indices only relevant to
                // the hierarchy below the current search depth.
                translate_va_lower_idx_vec[CCI_MPF_PT_MAX_DEPTH-1] <=
                    translate_va_idx_vec[0];
            end

          STATE_PT_WALK_READ_REQ:
            begin
                // Wait until a PT read request can fire
                if (pt_walk_reader.readEn)
                begin
                    state <= STATE_PT_WALK_READ_WAIT_RSP;
                end
            end

          STATE_PT_WALK_READ_WAIT_RSP:
            begin
                // Wait for PT read response
                if (ptReadDataEn_qq)
                begin
                    state <= STATE_PT_WALK_READ_RSP;

                    pt_walk_cur_status <= cci_mpf_ptWalkWordToStatus(ptReadData_qq);

                    // Extract the address of a line from the entry.
                    pt_walk_page_from_cache <= 1'b0;
                    pt_walk_next_page <=
                        vtp4kbPageIdxFromPA(ptReadData_qq[$clog2(CCI_CLDATA_WIDTH / 8) +:
                                                          CCI_CLADDR_WIDTH]);
                end
            end

          STATE_PT_WALK_READ_RSP:
            begin
                // The update of pt_walk_cur_page could logically have been
                // in earlier states.  Putting the MUX here is better
                // for timing.
                pt_walk_cur_page <= pt_walk_page_from_cache ?
                                    pt_walk_cache_page : pt_walk_next_page;

                if (pt_walk_cur_status.terminal)
                begin
                    // Found the translation
                    state <= STATE_PT_WALK_DONE;
                end
                else
                begin
                    // Continue the walk
                    state <= STATE_PT_WALK_READ_REQ;
                    translate_depth <= translate_depth + t_cci_mpf_pt_walk_depth'(1);
                end

                // Raise an error if the maximum walk depth is reached without
                // finding the entry.
                if (pt_walk_cur_status.error || 
                    ! pt_walk_cur_status.terminal && (&(translate_depth) == 1'b1))
                begin
                    state <= STATE_PT_WALK_ERROR;
                end

                // Shift to move to the index of the next level.
                for (int i = 0; i < CCI_MPF_PT_MAX_DEPTH-1; i = i + 1)
                begin
                    translate_va_idx_vec[i + 1] <= translate_va_idx_vec[i];
                    translate_va_lower_idx_vec[i + 1] <= translate_va_lower_idx_vec[i];
                end
                translate_va_idx_vec[0] <= translate_va_lower_idx_vec[CCI_MPF_PT_MAX_DEPTH-1];
            end

          STATE_PT_WALK_DONE:
            begin
                // Current request is complete
                state <= STATE_PT_WALK_IDLE;
                state_is_walk_idle <= 1'b1;
                rsp_en <= 1'b1;
            end

          STATE_PT_WALK_ERROR:
            begin
                if (req_isSpeculative)
                begin
                    // Speculative translation failure.
                    state <= STATE_PT_WALK_SPEC_ERROR;
                end
                else
                begin
                    // Non speculative fatal error. Terminal state.
                    state <= STATE_PT_WALK_HALT;

                    if (! reset)
                    begin
                        $fatal("VTP PT WALK: No translation found for VA 0x%x",
                               { translate_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0 });
                    end
                end

                rsp_en <= 1'b1;
            end

          STATE_PT_WALK_SPEC_ERROR:
            begin
                state <= STATE_PT_WALK_IDLE;
                state_is_walk_idle <= 1'b1;
                rsp_en <= 1'b0;
            end

          STATE_PT_WALK_HALT:
            begin
                rsp_en <= 1'b0;
            end
        endcase

        if (reset)
        begin
            state <= STATE_PT_WALK_IDLE;
            state_is_walk_idle <= 1'b1;
            rsp_en <= 1'b0;
            translate_va <= t_tlb_4kb_va_page_idx'(0);
        end
    end


    // ====================================================================
    //
    //   Generate page table read requests.
    //
    // ====================================================================

    // Enable a read request?
    assign pt_walk_reader.readEn = (state == STATE_PT_WALK_READ_REQ) && pt_walk_reader.readRdy;
    assign pt_walk_reader.writeEn = 1'b0;
    assign pt_walk_reader.readReqTag = 'x;  // Not used here

    // Address of read request
    always_comb
    begin
        pt_walk_reader.readAddr = t_cci_clAddr'(0);

        // Current page in table
        pt_walk_reader.readAddr[CCI_PT_4KB_PAGE_OFFSET_BITS +: CCI_PT_4KB_PA_PAGE_INDEX_BITS] =
            pt_walk_cur_page;

        // Select the proper line in this level of the table, based on the
        // portion of the VA corresponding to the level.
        pt_walk_reader.readAddr[PT_PAGE_LINE_IDX_WIDTH-1 : 0] = ptPageLineIdx(translate_va_idx_vec);
    end


    // ====================================================================
    //
    //   Consume page table read responses.
    //
    // ====================================================================

    // Break a read response line into 64 bit words
    logic [(CCI_CLDATA_WIDTH / 64)-1 : 0][63 : 0] pt_read_rsp_word_vec;

    always_comb
    begin
        pt_read_rsp_word_vec = ptReadData_q;
        pt_read_rsp_word = pt_read_rsp_word_vec[ptLineWordIdx(translate_va_idx_vec) +: 2];
    end


    always_ff @(posedge clk)
    begin
        if (! reset && DEBUG_MESSAGES)
        begin
            // synthesis translate_off
            if (pt_walk.rspEn)
            begin
                $display("VTP PT WALK %0t: Response PA 0x%x, size %s",
                         $time,
                         {pt_walk_cur_page, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         (pt_walk.rspIsBigPage ? "2MB" : "4KB"));
            end

            if (pt_walk.reqEn && (state == STATE_PT_WALK_IDLE))
            begin
                $display("VTP PT WALK %0t: New req translate line 0x%x (VA 0x%x)",
                         $time,
                         { pt_walk.reqVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0) },
                         { pt_walk.reqVA, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0 });
            end

            if ((state == STATE_PT_WALK_READ_CACHE_REQ) && ptReadCacheRdy)
            begin
                $display("VTP PT WALK %0t: Cache read [0x%x 0x%x 0x%x 0x%x] depth 0x%x",
                         $time,
                         translate_va_idx_vec[3],
                         translate_va_idx_vec[2],
                         translate_va_idx_vec[1],
                         translate_va_idx_vec[0],
                         translate_depth);
            end

            if ((state == STATE_PT_WALK_READ_CACHE_RSP) && ptReadCacheMissRsp)
            begin
                $display("VTP PT WALK %0t: Cache miss", $time);
            end

            if ((state == STATE_PT_WALK_READ_CACHE_RSP) && ptReadCacheHitRsp)
            begin
                $display("VTP PT WALK %0t: Cache hit PA 0x%x (terminal %0d, error %0d)",
                         $time,
                         {ptReadCachePage, CCI_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                         ptReadCacheStatus.terminal,
                         ptReadCacheStatus.error);
            end

            if (pt_walk_reader.readEn)
            begin
                $display("VTP PT WALK %0t: PTE read addr 0x%x (PA 0x%x) (line 0x%x, word 0x%x)",
                         $time,
                         pt_walk_reader.readAddr, {pt_walk_reader.readAddr, 6'b0},
                         ptPageLineIdx(translate_va_idx_vec),
                         ptLineWordIdx(translate_va_idx_vec));
            end

            if (ptReadDataEn_q)
            begin
                $display("VTP PT WALK %0t: Line (tag 0x%x) arrived 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x",
                         $time,
                         ptReadDataTag_q,
                         pt_read_rsp_word_vec[7],
                         pt_read_rsp_word_vec[6],
                         pt_read_rsp_word_vec[5],
                         pt_read_rsp_word_vec[4],
                         pt_read_rsp_word_vec[3],
                         pt_read_rsp_word_vec[2],
                         pt_read_rsp_word_vec[1],
                         pt_read_rsp_word_vec[0]);

                $display("VTP PT WALK %0t: Cache insert [0x%x 0x%x 0x%x 0x%x] depth 0x%x",
                         $time,
                         translate_va_idx_vec[3],
                         translate_va_idx_vec[2],
                         translate_va_idx_vec[1],
                         translate_va_idx_vec[0],
                         translate_depth);
            end
            // synthesis translate_on
        end
    end


    // ====================================================================
    //
    //   Return page walk result.
    //
    // ====================================================================

    // Current lookup becomes uncacheable if there is a TLB invalidation
    // during the walk.
    logic rsp_is_cacheable;
    always_ff @(posedge clk)
    begin
        if (pt_walk.reqEn && (state == STATE_PT_WALK_IDLE))
        begin
            rsp_is_cacheable <= 1'b1;
        end

        if (reset || csrs.vtp_in_inval_page_valid)
        begin
            rsp_is_cacheable <= 1'b0;
        end
    end

    always_ff @(posedge clk)
    begin
        pt_walk.rspEn <= rsp_en;
        pt_walk.rspVA <= translate_va;
        pt_walk.rspPA <= pt_walk_cur_page;
        pt_walk.rspMeta <= req_meta;
        pt_walk.rspIsSpeculative <= req_isSpeculative;
        pt_walk.rspTag <= req_tag;

        // Use just bit 0 of translate_depth, which is either 2 for a 2MB page
        // or 3 for a 4KB page.
        pt_walk.rspIsBigPage <= ~(translate_depth[0]);
        pt_walk.rspIsCacheable <= rsp_is_cacheable;
        pt_walk.rspNotPresent <= rsp_en &&
                                 ((state == STATE_PT_WALK_SPEC_ERROR) ||
                                  (state == STATE_PT_WALK_HALT));
    end

    // Statistics and events
    always_ff @(posedge clk)
    begin
        events.vtp_out_event_pt_walk_busy <= ! state_is_walk_idle;
        events.vtp_out_pt_walk_last_vaddr <= { translate_va, CCI_PT_4KB_PAGE_OFFSET_BITS'(0) };
        events.vtp_out_event_failed_translation <= pt_walk.rspNotPresent && pt_walk.rspEn;
    end

endmodule // cci_mpf_svc_vtp_pt_walk


//
// Small cache of previously read lines in the page table.
//
module cci_mpf_svc_vtp_pt_walk_cache
  #(
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // CSRs
    cci_mpf_csrs.vtp csrs,

    // Ready for new request?
    output logic rdy,

    // Look up line/word
    input  logic reqEn,
    input  t_cci_mpf_pt_page_idx_vec reqPageIdxVec,
    input  t_cci_mpf_pt_walk_depth reqWalkDepth,

    // Response
    output logic rspMiss,
    output logic rspHit,
    output t_tlb_4kb_pa_page_idx rspPageAddr,
    output t_cci_mpf_pt_walk_status rspStatus,

    // Insert data in the cache
    input  logic insertEn,
    input  t_cci_clData insertData,
    input  t_cci_mpf_pt_page_idx_vec insertPageIdxVec,
    input  t_cci_mpf_pt_walk_depth insertWalkDepth
    );

    // Number of cache entries.  Each entry has one tag and
    // PT_WORDS_PER_LINE words.
    localparam PT_CACHE_ENTRIES = 128;
    typedef logic [$clog2(PT_CACHE_ENTRIES)-1 : 0] t_pt_cache_idx;

    //
    // Break the page index vector into two components:
    //   - The majority is a tag.
    //   - The low few bits are the index of a word within a CCI line.
    //     This is what makes the cache useful, since multiple
    //     page table entries are fetched with each line.
    //
    localparam PT_WORDS_PER_LINE = CCI_CLDATA_WIDTH / 64;
    localparam PT_LINE_WORD_IDX_WIDTH = $clog2(PT_WORDS_PER_LINE);
    typedef logic [PT_LINE_WORD_IDX_WIDTH-1 : 0] t_pt_line_word_idx;

    // t_cci_mpf_pt_page_idx_vec without the low t_pt_line_word_idx bits
    typedef logic [$bits(t_cci_mpf_pt_page_idx_vec) - PT_LINE_WORD_IDX_WIDTH - 1 : 0]
        t_pt_entry_tag;

    //
    // Cache tag from index vector.  The vector represents the offsets within
    // each page table, so the set of indices uniquely identifies a page
    // table entry.  The tag represents a full line so it ignores the low
    // word index bits.
    //
    function automatic t_pt_entry_tag cacheTag(t_cci_mpf_pt_page_idx_vec idxVec);
        // Ignore the low (word index) bits of the page index vector
        t_pt_entry_tag tag;
        t_pt_line_word_idx w_idx;
        {tag, w_idx} = idxVec;

        return tag;
    endfunction

    //
    // Compute the cache index given a page index vector and the depth
    // in the page table walk.  Each depth gets its own region in the
    // address space.
    //
    function automatic t_pt_cache_idx cacheIdx(t_cci_mpf_pt_page_idx_vec idxVec,
                                               t_cci_mpf_pt_walk_depth depth);
        // Hash the tag and include the depth
        return t_pt_cache_idx'({ hash32(32'(cacheTag(idxVec))), depth });
    endfunction


    logic tag_rdy;
    logic insert_pending;
    assign rdy = tag_rdy && ! insert_pending;


    // ====================================================================
    //
    //  Storage
    //
    // ====================================================================

    //
    // Tag memory
    //
    logic ins_cache_en;
    logic ins_tag_en;
    t_pt_cache_idx ins_idx;
    t_pt_entry_tag ins_tag;

    t_pt_cache_idx lookup_idx;
    assign lookup_idx = cacheIdx(reqPageIdxVec, reqWalkDepth);
    t_pt_entry_tag lookup_tag;
    logic lookup_tag_valid;

    logic n_reset_tlb[0:1];
    always @(posedge clk)
    begin
        n_reset_tlb[1] <= ~csrs.vtp_in_mode.inval_translation_cache &&
                          // Reset the page table cache when any page is
                          // invalidated.  The cost isn't that high and the
                          // protocol for invalidating a single entry is
                          // complicated.
                          ~csrs.vtp_in_inval_page_valid;

        n_reset_tlb[0] <= n_reset_tlb[1];

        if (reset)
        begin
            n_reset_tlb[1] <= 1'b0;
            n_reset_tlb[0] <= 1'b0;
        end
    end

    always_ff @(posedge clk)
    begin
        if (! reset && DEBUG_MESSAGES)
        begin
            if (~n_reset_tlb[0])
            begin
                $display("VTP PT WALK %0t: Invalidate PT cache", $time);
            end
        end
    end

    cci_mpf_prim_ram_simple_init
      #(
        .N_ENTRIES(PT_CACHE_ENTRIES),
        .N_DATA_BITS(1 + $bits(t_pt_entry_tag)),
        .INIT_VALUE({ 1'b0, t_pt_entry_tag'('x) }),
        .REGISTER_WRITES(1),
        .BYPASS_REGISTERED_WRITES(0),
        .N_OUTPUT_REG_STAGES(1)
        )
      tag
       (
        .clk,
        .reset(~n_reset_tlb[0]),
        .rdy(tag_rdy),

        // The tag entry is written on every beat that data is written to
        // the entry. The tag is marked invalid (ins_tag_en == 0) until the
        // last beat.
        .waddr(ins_idx),
        .wen(ins_cache_en),
        .wdata({ ins_tag_en, ins_tag }),

        .raddr(lookup_idx),
        .rdata({ lookup_tag_valid, lookup_tag })
        );

    //
    // Data memory
    //
    t_pt_line_word_idx ins_word_idx;
    t_tlb_4kb_pa_page_idx ins_data_word;
    t_cci_mpf_pt_walk_status ins_data_status;

    t_tlb_4kb_pa_page_idx rsp_page_addr;
    t_cci_mpf_pt_walk_status rsp_status;

    cci_mpf_prim_ram_simple
      #(
        .N_ENTRIES(PT_CACHE_ENTRIES * PT_WORDS_PER_LINE),
        .N_DATA_BITS(CCI_PT_4KB_PA_PAGE_INDEX_BITS +
                     $bits(t_cci_mpf_pt_walk_status)),
        .REGISTER_WRITES(1),
        .BYPASS_REGISTERED_WRITES(0),
        .N_OUTPUT_REG_STAGES(1)
        )
      data
       (
        .clk,

        .waddr({ ins_idx, ins_word_idx }),
        .wen(ins_cache_en),
        .wdata({ ins_data_word, ins_data_status }),

        .raddr({ lookup_idx, t_pt_line_word_idx'(reqPageIdxVec) }),
        .rdata({ rsp_page_addr, rsp_status })
        );


    // ====================================================================
    //
    //  Lookup pipeline
    //
    // ====================================================================

    logic lookup_q;
    logic lookup_qq;
    t_pt_entry_tag lookup_tgt_tag_q;
    t_pt_entry_tag lookup_tgt_tag_qq;

    logic lookup_hit;
    assign lookup_hit = lookup_tag_valid &&
                        (lookup_tgt_tag_qq == lookup_tag) &&
                        ! rsp_status.error;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            lookup_q <= 1'b0;
            lookup_qq <= 1'b0;

            rspMiss <= 1'b0;
            rspHit <= 1'b0;
        end
        else
        begin
            lookup_q <= reqEn;
            lookup_qq <= lookup_q;

            rspMiss <= lookup_qq && ! lookup_hit;
            rspHit <= lookup_qq && lookup_hit;
        end

        lookup_tgt_tag_q <= cacheTag(reqPageIdxVec);
        lookup_tgt_tag_qq <= lookup_tgt_tag_q;

        rspPageAddr <= rsp_page_addr;
        rspStatus <= rsp_status;
    end


    // ====================================================================
    //
    //  Insertion state machine
    //
    // ====================================================================

    //
    // Inserting takes multiple cycles since each word in a line is stored
    // in a separate index.
    //

    // Break a line into 64 bit words
    logic [PT_WORDS_PER_LINE-1 : 0][63 : 0] ins_line_words;
    logic insert_busy;

    always_ff @(posedge clk)
    begin
        // insert_pending is cleared one cycle after insert_busy because the
        // tag and data RAMs have a one cycle write delay.
        insert_pending <= insert_busy;

        if (insertEn && tag_rdy)
        begin
            // New line to insert.  The rdy bit guarantees no insert is
            // happening when insertEn is triggered.
            insert_busy <= 1'b1;
            insert_pending <= 1'b1;

            ins_idx <= cacheIdx(insertPageIdxVec, insertWalkDepth);
            ins_tag <= cacheTag(insertPageIdxVec);
            ins_line_words <= insertData;
        end
        else if (insert_busy)
        begin
            // Last word?
            if (ins_tag_en)
            begin
                insert_busy <= 1'b0;
            end

            ins_word_idx <= ins_word_idx + t_pt_line_word_idx'(1);

            // Shift line as words are written to the memory
            for (int w = 0; w < PT_WORDS_PER_LINE-1; w = w + 1)
            begin
                ins_line_words[w] <= ins_line_words[w + 1];
            end
        end

        if (reset)
        begin
            insert_busy <= 1'b0;
            ins_word_idx <= t_pt_line_word_idx'(0);
        end
    end

    // Write the tag when the last word in the line is saved to the cache
    assign ins_tag_en = (&(ins_word_idx) == 1'b1);
    assign ins_cache_en = insert_busy;

    assign ins_data_word =
        vtp4kbPageIdxFromPA(ins_line_words[0][$clog2(CCI_CLDATA_WIDTH / 8) +:
                                              CCI_CLADDR_WIDTH]);
    assign ins_data_status = cci_mpf_ptWalkWordToStatus(ins_line_words[0]);

endmodule // cci_mpf_svc_vtp_pt_walk_cache


//
// Forward page table read requests to the FIM. In addition to reads demanded
// by the page table walker this module also generates prefetches of nearby
// lines in the page table since the latency of reading page table entries
// of 4KB pages is sometimes a problem.
//
module cci_mpf_svc_vtp_pt_walk_reader
  #(
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Command interface from PT walker
    cci_mpf_shim_vtp_pt_fim_if.to_fim pt_walk_reader,

    // FIM interface for host I/O
    cci_mpf_shim_vtp_pt_fim_if.pt_walk pt_fim,

    // CSRs
    cci_mpf_csrs.vtp csrs
    );

    // Don't allow back-to-back requests to the FIM. The readRdy flag
    // isn't updated properly because of register delay.
    logic pt_fim_rdy;
    assign pt_fim_rdy = pt_fim.readRdy && ! pt_fim.readEn;

    //
    // Register incoming requests.
    //
    logic new_read_en;
    t_cci_clAddr new_read_addr;
    logic new_read_pref_hit;

    always_ff @(posedge clk)
    begin
        // If there is an existing read request it is processed as long as
        // the FIM isn't busy.
        if (pt_fim_rdy || new_read_pref_hit)
        begin
            new_read_en <= 1'b0;
        end

        if (pt_walk_reader.readEn)
        begin
            new_read_en <= 1'b1;
            new_read_addr <= pt_walk_reader.readAddr;
        end

        if (reset)
        begin
            new_read_en <= 1'b0;
        end
    end


    logic pt_prefetch_addr_valid;
    t_cci_clAddr pt_prefetch_addr;

    // PT walker does no writes to host memory
    assign pt_fim.writeEn = 1'b0;

    // New requests allowed as long as the slot is available and no
    // prefetch may be scheduled.
    assign pt_walk_reader.readRdy = ! pt_prefetch_addr_valid && ! new_read_en;


    // pt_walk_reader.readData as a vector of 64 bit page table entries
    logic [(CCI_CLDATA_WIDTH / 64)-1 : 0][63 : 0] pt_walk_read_data_word_vec;
    assign pt_walk_read_data_word_vec = pt_walk_reader.readData;


    // ====================================================================
    //
    //  Record possible prefetch addresses in lines following read
    //  requests.
    //
    // ====================================================================

    // Construct a type that is the index of lines within a single page in the
    // page table. For 4KB pages and 64 byte lines, the line index is 6 bits.
    localparam PT_WORDS_PER_LINE = CCI_CLDATA_WIDTH / 64;
    localparam PT_LINE_WORD_IDX_WIDTH = $clog2(PT_WORDS_PER_LINE);
    localparam PT_PAGE_LINE_IDX_WIDTH = CCI_MPF_PT_PAGE_IDX_WIDTH - PT_LINE_WORD_IDX_WIDTH;
    typedef logic [PT_PAGE_LINE_IDX_WIDTH-1 : 0] t_pt_page_line_idx;

    always_ff @(posedge clk)
    begin
        if (new_read_en)
        begin
            // The address following a new readAddr may be prefetched as
            // long as the line is on the same page as the readAddr. As
            // long as the line index portion of the address on the page
            // isn't all 1's it will work.
            pt_prefetch_addr_valid <= ~(&(t_pt_page_line_idx'(new_read_addr)));

            // No need to worry about overflow out of the line index, so build
            // a smaller adder.
            pt_prefetch_addr <= new_read_addr;
            pt_prefetch_addr[PT_PAGE_LINE_IDX_WIDTH-1 : 0] <=
                t_pt_page_line_idx'(new_read_addr) + t_pt_page_line_idx'(1);
        end

        // Clear the address on the cycle when a read is returned to the
        // walker. During this cycle the prefetch engine below will decide whether
        // to emit a prefetch. Also clear it any cycle that an invalidation
        // is raised.
        if (pt_walk_reader.readDataEn ||
            csrs.vtp_in_mode.inval_translation_cache ||
            csrs.vtp_in_inval_page_valid)
        begin
            pt_prefetch_addr_valid <= 1'b0;
        end

        if (reset)
        begin
            pt_prefetch_addr_valid <= 1'b0;
        end
    end


    // ====================================================================
    //
    //  Data structure and accessor functions for tagging page table
    //  reads and prefetch requests.
    //
    // ====================================================================

    // Number of slots for holding prefetched entries. On most systems
    // this is configurable (by overriding the default set in cci_mpf_config.vh.
    // On Broadwell integrated parts, only 4 buckets are defined in
    // order to aid timing closure.
    localparam NUM_PREFETCH_BUCKETS =
        (MPF_PLATFORM != "INTG_BDX") ? `VTP_N_PT_WALK_PREFETCH_BUCKETS : 4;

    typedef logic [$clog2(NUM_PREFETCH_BUCKETS)-1 : 0] t_pref_idx;
    typedef logic [NUM_PREFETCH_BUCKETS-1 : 0] t_pref_vec;

    typedef enum logic [0:0] {
        RD_TYPE_PT_NORMAL,
        RD_TYPE_PT_PREF
    }
    t_rd_type;

    // This struct is passed in readReqTag and returned in readRspTag.
    typedef struct packed
    {
        t_rd_type rd_type;
        t_pref_idx bucket_idx;
    }
    t_pt_read_mdata;

    // Request info to metadata tag
    function automatic cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value setPtReadMdata(
        t_rd_type rd_type,
        t_pref_idx bucket_idx
        );

        t_pt_read_mdata m;
        m.rd_type = rd_type;
        m.bucket_idx = bucket_idx;

        return cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value'(m);
    endfunction

    function automatic t_rd_type getPtReadMdataType(
        cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value v
        );

        t_pt_read_mdata m = t_pt_read_mdata'(v);
        return m.rd_type;
    endfunction

    function automatic t_pref_idx getPtReadMdataIdx(
        cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value v
        );

        t_pt_read_mdata m = t_pt_read_mdata'(v);
        return m.bucket_idx;
    endfunction


    // ====================================================================
    //
    //  Prefetch engine and state
    //
    // ====================================================================

    // Bucket state
    struct
    {
        t_pref_vec valid;             // Bucket has valid data
        t_pref_vec busy;              // Waiting for read response
        t_pref_vec not_poison;        // Invalidated while waiting for read?

        t_cci_clAddr tag[NUM_PREFETCH_BUCKETS];
    }
    pref_state;

    // Prefetch responses have tag bit 2 set and the bucket index
    // in bits [1:0].
    logic pref_resp_valid;
    t_pref_idx pref_resp_idx;
    assign pref_resp_valid = (pt_fim.readDataEn &&
                              (getPtReadMdataType(pt_fim.readRspTag) == RD_TYPE_PT_PREF));
    assign pref_resp_idx = getPtReadMdataIdx(pt_fim.readRspTag);

    //
    // Prefetch read data container
    //
    t_pref_idx pref_rd_idx;
    t_cci_clData pref_rd_data;

    cci_mpf_prim_lutram
      #(
        .N_ENTRIES(NUM_PREFETCH_BUCKETS),
        .N_DATA_BITS(CCI_CLDATA_WIDTH)
        )
      pref_data
       (
        .clk,
        .reset,

        .raddr(pref_rd_idx),
        .rdata(pref_rd_data),

        .waddr(pref_resp_idx),
        .wen(pref_resp_valid),
        .wdata(pt_fim.readData)
        );


    // Pick a bucket to use for the next prefetch
    logic bucket_available;
    t_pref_idx next_pref_idx;
    logic do_pt_prefetch;

    // Picking is an arbitration problem. This arbiter always returns the
    // choice in grantIdx, even when enable is false. Setting enable updates
    // the round-robin history.
    t_pref_idx next_pref_arb_idx;
    cci_mpf_prim_arb_rr
      #(
        .NUM_CLIENTS(NUM_PREFETCH_BUCKETS)
        )
      pick_rr
       (
        .clk,
        .reset,

        .ena(do_pt_prefetch),
        .request(~pref_state.busy),

        .grant(),
        .grantIdx(next_pref_arb_idx)
        );

    // Register the arbitration result for timing. The complication from
    // the register is that there is a vulnerable cycle when busy has been
    // set but net yet visible from the arbiter. The solution here is
    // simple: don't allow back-to-back prefetches.
    always_ff @(posedge clk)
    begin
        // Prefetch is possible as long as some bucket isn't busy
        bucket_available <= ~(&(pref_state.busy)) && ! do_pt_prefetch;
        next_pref_idx <= next_pref_arb_idx;
    end


    // Would prefetch be legal?
    logic could_prefetch;
    assign could_prefetch = bucket_available && pt_prefetch_addr_valid &&
                            pt_walk_reader.readDataEn &&
                            ! new_read_en &&
                            pt_fim_rdy;

    // Is prefetching a good idea? It's likely a waste of time on sparse data,
    // so only prefetch if both the first and last entries are valid, terminal
    // entries.
    t_cci_mpf_pt_walk_status ws0, ws7;
    assign ws0 = cci_mpf_ptWalkWordToStatus(pt_walk_read_data_word_vec[0]);
    assign ws7 = cci_mpf_ptWalkWordToStatus(pt_walk_read_data_word_vec[7]);

    assign do_pt_prefetch = could_prefetch &&
                            ws0.terminal && ! ws0.error &&
                            ws7.terminal && ! ws7.error;

    always_ff @(posedge clk)
    begin
        for (int i = 0; i < NUM_PREFETCH_BUCKETS; i = i + 1)
        begin
            if (do_pt_prefetch && (next_pref_idx == t_pref_idx'(i)))
            begin
                // Prefetch read generated this cycle. Initialize the
                // bucket's state, indicating read data is pending.
                pref_state.valid[i] <= 1'b0;
                pref_state.busy[i] <= 1'b1;
                pref_state.not_poison[i] <= 1'b1;
                pref_state.tag[i] <= pt_prefetch_addr;
            end
            else if (pref_resp_valid && (pref_resp_idx == t_pref_idx'(i)))
            begin
                // Read data arrived. The value is now valid unless it
                // has been poisoned by a page invalidation during the
                // read.
                pref_state.valid[i] <= pref_state.not_poison[i];
                pref_state.busy[i] <= 1'b0;
            end
        end

        // Poison all outstanding requests on invalidation
        if (csrs.vtp_in_mode.inval_translation_cache ||
            csrs.vtp_in_inval_page_valid)
        begin
            pref_state.valid <= t_pref_vec'(0);
            pref_state.not_poison <= t_pref_vec'(0);
        end

        if (reset)
        begin
            pref_state.valid <= t_pref_vec'(0);
            pref_state.busy <= t_pref_vec'(0);
            pref_state.not_poison <= t_pref_vec'(0);
        end
    end

    //
    // Compare the incoming address to prefetched buckets.
    //
    logic new_read_pref_match;
    t_pref_idx new_read_pref_hit_idx;

    // These intermediate values are combination during the cycle
    // pt_walk_reader.readEn is asserted.
    t_pref_vec read_addr_hit_vec;
    t_pref_idx read_addr_hit_idx;

    // Generate a bit vector of readAddr comparisons to prefetch buckets
    always_comb
    begin
        for (int i = 0; i < NUM_PREFETCH_BUCKETS; i = i + 1)
        begin
            read_addr_hit_vec[i] = (pt_walk_reader.readAddr === pref_state.tag[i]);
        end
    end

    // Pick a bucket index from the readAddr comparison vector
    always_comb
    begin
        read_addr_hit_idx = t_pref_idx'(0);

        for (int i = 1; i < NUM_PREFETCH_BUCKETS; i = i + 1)
        begin
            if (read_addr_hit_vec[i])
            begin
                read_addr_hit_idx = t_pref_idx'(i);
            end
        end
    end

    // Register the pt_walk_reader.readAddr to bucket tag comparison
    always_ff @(posedge clk)
    begin
        if (! new_read_en)
        begin
            new_read_pref_match <= (|(read_addr_hit_vec));
            new_read_pref_hit_idx <= read_addr_hit_idx;
        end
    end

    // Service a new request with a prefetch?
    assign pref_rd_idx = new_read_pref_hit_idx;
    assign new_read_pref_hit = new_read_en && new_read_pref_match &&
                               pref_state.valid[new_read_pref_hit_idx];


    // ====================================================================
    //
    //  Send either a normal read or prefetch to the FIM.
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        pt_fim.readEn <= (new_read_en && pt_fim_rdy && !new_read_pref_hit) ||
                         do_pt_prefetch;

        if (do_pt_prefetch)
        begin
            // Page table line prefetch
            pt_fim.readAddr <= pt_prefetch_addr;
            pt_fim.readReqTag <= setPtReadMdata(RD_TYPE_PT_PREF, next_pref_idx);
        end
        else
        begin
            // Normal read request
            pt_fim.readAddr <= new_read_addr;
            pt_fim.readReqTag <= setPtReadMdata(RD_TYPE_PT_NORMAL, 0);
        end
    end


    // ====================================================================
    //
    //  Respond either from the prefetch buffer or the FIM
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        pt_walk_reader.readDataEn <= (pt_fim.readDataEn &&
                                      (getPtReadMdataType(pt_fim.readRspTag) == RD_TYPE_PT_NORMAL)) ||
                                     new_read_pref_hit;
        pt_walk_reader.readData <= (new_read_pref_hit ? pref_rd_data : pt_fim.readData);

        // Set the source of the response in the readRspTag. This is unlikely
        // to be useful to the client, though it is valuable for debugging.
        pt_walk_reader.readRspTag <=
            setPtReadMdata((new_read_pref_hit ? RD_TYPE_PT_PREF : RD_TYPE_PT_NORMAL),
                           new_read_pref_hit_idx);
    end


    // ====================================================================
    //
    //  Debug
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        if (! reset && DEBUG_MESSAGES)
        begin
            // synthesis translate_off
            if (pt_fim.readEn && (getPtReadMdataType(pt_fim.readReqTag) == RD_TYPE_PT_NORMAL))
            begin
                $display("VTP PT WALK RD %0t: PTE normal read addr 0x%x (PA 0x%x)",
                         $time,
                         pt_fim.readAddr, {pt_fim.readAddr, 6'b0});
            end

            if (pt_fim.readEn && (getPtReadMdataType(pt_fim.readReqTag) == RD_TYPE_PT_PREF))
            begin
                $display("VTP PT WALK RD %0t: PTE prefetch read addr 0x%x (PA 0x%x), bucket %0d",
                         $time,
                         pt_fim.readAddr, {pt_fim.readAddr, 6'b0},
                         getPtReadMdataIdx(pt_fim.readReqTag));
            end

            if (could_prefetch && ! do_pt_prefetch)
            begin
                $display("VTP PT WALK RD %0t: Skipped sparse prefetch",
                         $time);
            end

            if (pt_walk_reader.readDataEn && (getPtReadMdataType(pt_walk_reader.readRspTag) == RD_TYPE_PT_NORMAL))
            begin
                $display("VTP PT WALK RD %0t: PTE normal response 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x",
                         $time,
                         pt_walk_read_data_word_vec[7],
                         pt_walk_read_data_word_vec[6],
                         pt_walk_read_data_word_vec[5],
                         pt_walk_read_data_word_vec[4],
                         pt_walk_read_data_word_vec[3],
                         pt_walk_read_data_word_vec[2],
                         pt_walk_read_data_word_vec[1],
                         pt_walk_read_data_word_vec[0]);
            end

            if (pt_walk_reader.readDataEn && (getPtReadMdataType(pt_walk_reader.readRspTag) == RD_TYPE_PT_PREF))
            begin
                $display("VTP PT WALK RD %0t: PTE prefetch hit (bucket %0d) 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x 0x%x",
                         $time,
                         getPtReadMdataIdx(pt_walk_reader.readRspTag),
                         pt_walk_read_data_word_vec[7],
                         pt_walk_read_data_word_vec[6],
                         pt_walk_read_data_word_vec[5],
                         pt_walk_read_data_word_vec[4],
                         pt_walk_read_data_word_vec[3],
                         pt_walk_read_data_word_vec[2],
                         pt_walk_read_data_word_vec[1],
                         pt_walk_read_data_word_vec[0]);
            end

            if (pref_resp_valid)
            begin
                $display("VTP PT WALK RD %0t: PTE prefetch resp arrived, bucket %0d",
                         $time,
                         pref_resp_idx);
            end
            // synthesis translate_on
        end
    end

endmodule // cci_mpf_svc_vtp_pt_walk_reader
