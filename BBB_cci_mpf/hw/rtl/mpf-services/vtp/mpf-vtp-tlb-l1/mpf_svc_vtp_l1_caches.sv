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
// VTP level 1 private cache. This module implements just the cache array
// lookup and update.
//

`include "mpf_vtp.vh"

module mpf_svc_vtp_l1_caches
  #(
    parameter N_LOCAL_4KB_CACHE_ENTRIES = 512,
    parameter N_LOCAL_2MB_CACHE_ENTRIES = 512,
    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Lookup address.  The incoming address is the index of a 4KB page.
    // Larger page size lookups will just drop low address bits.
    input  t_tlb_4kb_va_page_idx lookupVA,
    output logic T3_hit_4kb,
    output logic T3_hit_2mb,
    // Or of all size-specific hits
    output logic T3_hit,
    output t_tlb_4kb_pa_page_idx T3_hitPA,

    // Insert translation in cache.  Like lookupVA, these addresses are
    // transformed internally for page sizes larger than 4KB.
    input  t_tlb_4kb_va_page_idx insertVA,
    input  t_tlb_4kb_pa_page_idx insertPA,
    input  en_insert_4kb,
    input  en_insert_2mb,

    // CSRs
    mpf_vtp_csrs_if.vtp csrs
    );

    //
    // The local cache is direct mapped.  Break a VA into cache index
    // and tag.
    //
    typedef logic [$clog2(N_LOCAL_4KB_CACHE_ENTRIES)-1 : 0] t_vtp_tlb_4kb_cache_idx;
    typedef logic [$bits(t_tlb_4kb_va_page_idx)-$bits(t_vtp_tlb_4kb_cache_idx)-1 : 0]
        t_vtp_tlb_4kb_cache_tag;

    typedef logic [$clog2(N_LOCAL_2MB_CACHE_ENTRIES)-1 : 0] t_vtp_tlb_2mb_cache_idx;
    typedef logic [$bits(t_tlb_2mb_va_page_idx)-$bits(t_vtp_tlb_2mb_cache_idx)-1 : 0]
        t_vtp_tlb_2mb_cache_tag;


    //
    // Functions to extract cache index and tag from a 4KB virtual page address
    //
    function automatic t_vtp_tlb_4kb_cache_idx cacheIdx4KB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_4kb_cache_tag tag;
        t_vtp_tlb_4kb_cache_idx idx;
        {tag, idx} = va;
        return idx;
    endfunction

    function automatic t_vtp_tlb_4kb_cache_tag cacheTag4KB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_4kb_cache_tag tag;
        t_vtp_tlb_4kb_cache_idx idx;
        {tag, idx} = va;
        return tag;
    endfunction

    function automatic t_vtp_tlb_2mb_cache_idx cacheIdx2MB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_2mb_cache_tag tag;
        t_vtp_tlb_2mb_cache_idx idx;
        {tag, idx} = vtp4kbTo2mbVA(va);
        return idx;
    endfunction

    function automatic t_vtp_tlb_2mb_cache_tag cacheTag2MB(t_tlb_4kb_va_page_idx va);
        t_vtp_tlb_2mb_cache_tag tag;
        t_vtp_tlb_2mb_cache_idx idx;
        {tag, idx} = vtp4kbTo2mbVA(va);
        return tag;
    endfunction


    // ====================================================================
    //
    // Reset (invalidate) the TLB when requested by SW.
    // inval_translation_cache is held for only one cycle.
    //
    // ====================================================================

    logic vtp_enabled;
    logic n_reset_tlb, n_reset_tlb_q;
    always @(posedge clk)
    begin
        vtp_enabled <= csrs.vtp_ctrl.in_mode.enabled;
        n_reset_tlb <= ~csrs.vtp_ctrl.in_mode.inval_translation_cache;
        n_reset_tlb_q <= n_reset_tlb;

        if (reset)
        begin
            vtp_enabled <= 1'b0;
            n_reset_tlb <= 1'b0;
            n_reset_tlb_q <= 1'b0;
        end
    end


    // ====================================================================
    //
    //  Lookup state pipeline
    //
    // ====================================================================

    t_tlb_4kb_va_page_idx lookup_va[1:2];

    // The pipeline runs whether or not the underlying cache is ready.
    // Record whether a lookup may be valid.
    logic lookup_valid[1:2];
    logic rdy;

    always_ff @(posedge clk)
    begin
        lookup_va[1] <= lookupVA;
        lookup_va[2] <= lookup_va[1];

        lookup_valid[1] <= rdy && n_reset_tlb && n_reset_tlb_q && vtp_enabled;
        lookup_valid[2] <= lookup_valid[1];
    end


    // ====================================================================
    //
    //  Local L1 cache of 4KB page translations.
    //
    // ====================================================================

    logic cache_4kb_rdy;
    t_tlb_4kb_pa_page_idx cache_4kb_pa, T3_cache_4kb_pa;
    t_vtp_tlb_4kb_cache_tag cache_4kb_tag;
    logic cache_4kb_valid;

    logic wen_4kb;

    t_tlb_4kb_va_page_idx insert_va;
    t_tlb_4kb_pa_page_idx insert_pa;
    logic insert_addr_is_valid;

    cci_mpf_prim_ram_simple_init
      #(
        .N_ENTRIES(N_LOCAL_4KB_CACHE_ENTRIES),
        .N_DATA_BITS($bits(t_tlb_4kb_pa_page_idx) + $bits(t_vtp_tlb_4kb_cache_tag) + 1),
        .INIT_VALUE({ t_tlb_4kb_pa_page_idx'('x), t_vtp_tlb_4kb_cache_tag'('x), 1'b0 }),
        .N_OUTPUT_REG_STAGES(1)
        )
      cache4kb
       (
        .clk,
        .reset(~n_reset_tlb_q),
        .rdy(cache_4kb_rdy),

        .wen(wen_4kb),
        .waddr(cacheIdx4KB(insert_va)),
        .wdata({ insert_pa, cacheTag4KB(insert_va), insert_addr_is_valid }),

        // Cache read is initiated in pipeline cycle 0
        .raddr(cacheIdx4KB(lookupVA)),
        .rdata({ cache_4kb_pa, cache_4kb_tag, cache_4kb_valid })
        );

    // Cache read data arrives in cycle 2
    always_ff @(posedge clk)
    begin
        T3_hit_4kb <= (cacheTag4KB(lookup_va[2]) == cache_4kb_tag) &&
                      cache_4kb_valid &&
                      lookup_valid[2];
        T3_cache_4kb_pa <= cache_4kb_pa;
    end


    // ====================================================================
    //
    //  Local L1 cache of 2MB page translations.
    //
    // ====================================================================

    logic cache_2mb_rdy;
    t_tlb_2mb_pa_page_idx cache_2mb_pa, T3_cache_2mb_pa;
    t_vtp_tlb_2mb_cache_tag cache_2mb_tag;
    logic cache_2mb_valid;

    logic wen_2mb;

    cci_mpf_prim_ram_simple_init
      #(
        .N_ENTRIES(N_LOCAL_2MB_CACHE_ENTRIES),
        .N_DATA_BITS($bits(t_tlb_2mb_pa_page_idx) + $bits(t_vtp_tlb_2mb_cache_tag) + 1),
        .INIT_VALUE({ t_tlb_2mb_pa_page_idx'('x), t_vtp_tlb_2mb_cache_tag'('x), 1'b0 }),
        .N_OUTPUT_REG_STAGES(1)
        )
      cache2mb
       (
        .clk,
        .reset(~n_reset_tlb_q),
        .rdy(cache_2mb_rdy),

        .wen(wen_2mb),
        .waddr(cacheIdx2MB(insert_va)),
        .wdata({ vtp4kbTo2mbPA(insert_pa), cacheTag2MB(insert_va), insert_addr_is_valid }),

        // Cache read is initiated in pipeline cycle 0
        .raddr(cacheIdx2MB(lookupVA)),
        .rdata({ cache_2mb_pa, cache_2mb_tag, cache_2mb_valid })
        );

    // Cache read data arrives in cycle 2
    always_ff @(posedge clk)
    begin
        T3_hit_2mb <= (cacheTag2MB(lookup_va[2]) == cache_2mb_tag) &&
                      cache_2mb_valid &&
                      lookup_valid[2];
        T3_cache_2mb_pa <= cache_2mb_pa;
    end


    // ====================================================================
    //
    //  Merged lookup response
    //
    // ====================================================================

    always_comb
    begin
        T3_hit = T3_hit_4kb || T3_hit_2mb;

        if (T3_hit_4kb)
        begin
            T3_hitPA = T3_cache_4kb_pa;
        end
        else
        begin
            T3_hitPA = vtp2mbTo4kbPAx(T3_cache_2mb_pa);
        end
    end

    always_ff @(posedge clk)
    begin
        rdy <= cache_4kb_rdy && cache_2mb_rdy;
        if (reset)
        begin
            rdy <= 1'b0;
        end
    end


    // ====================================================================
    //
    //  Set values for updating the local cache.
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        insert_addr_is_valid <= 1'b1;
        insert_va <= insertVA;
        insert_pa <= insertPA;

        //
        // Invalidation requested by host? Invalidation has higher priority
        // than TLB fill. It's ok to drop a normal fill request since the
        // address can just go through translation again.
        //
        if (csrs.vtp_ctrl.inval_page_valid)
        begin
            insert_addr_is_valid <= 1'b0;
            insert_va <= vtp4kbPageIdxFromVA(csrs.vtp_ctrl.inval_page);
        end

        wen_4kb <= en_insert_4kb || csrs.vtp_ctrl.inval_page_valid;
        wen_2mb <= en_insert_2mb || csrs.vtp_ctrl.inval_page_valid;

        if (reset)
        begin
            wen_4kb <= 1'b0;
            wen_2mb <= 1'b0;
        end
    end


    // ====================================================================
    //
    //  Debug
    //
    // ====================================================================

    always_ff @(posedge clk)
    begin
        if (DEBUG_MESSAGES && ! reset)
        begin
            if (wen_4kb)
            begin
                if (insert_addr_is_valid)
                begin
                    $display("%m VTP: %0t 4KB: Insert idx %0d, VA 0x%x, PA 0x%x",
                             $time,
                             cacheIdx4KB(insert_va),
                             {insert_va, VTP_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0},
                             {insert_pa, VTP_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
                end
                else
                begin
                    $display("%m VTP: %0t 4KB: Remove idx %0d", $time, cacheIdx4KB(insert_va));
                end
            end

            if (wen_2mb)
            begin
                if (insert_addr_is_valid)
                begin
                    $display("%m VTP: %0t 2MB: Insert idx %0d, VA 0x%x, PA 0x%x",
                             $time,
                             cacheIdx2MB(insert_va),
                             {vtp4kbTo2mbVA(insert_va), VTP_PT_2MB_PAGE_OFFSET_BITS'(0), 6'b0},
                             {insert_pa, VTP_PT_4KB_PAGE_OFFSET_BITS'(0), 6'b0});
                end
                else
                begin
                    $display("%m VTP: %0t 2MB: Remove idx %0d", $time, cacheIdx2MB(insert_va));
                end
            end
        end
    end

endmodule // mpf_svc_vtp_port_l1_caches.sv
