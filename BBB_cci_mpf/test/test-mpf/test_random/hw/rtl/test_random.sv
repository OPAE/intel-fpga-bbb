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

`include "cci_mpf_test_conf_default.vh"
`include "cci_mpf_if.vh"
`include "cci_test_csrs.vh"

// Generated from the AFU JSON file by afu_json_mgr
`include "afu_json_info.vh"


module test_afu
   (
    input  logic clk,

    // Connection toward the QA platform.  Reset comes in here.
    cci_mpf_if.to_fiu fiu,

    // CSR connections
    test_csrs.test csrs,

    input  logic c0NotEmpty,
    input  logic c1NotEmpty
    );

    localparam string PARTIAL_WRITE_MODE = `MPF_CONF_PARTIAL_WRITE_MODE;

    logic reset = 1'b1;
    always @(posedge clk)
    begin
        reset <= fiu.reset;
    end

    logic chk_rdy;


    //
    // State machine
    //
    typedef enum logic [1:0]
    {
        STATE_IDLE,
        STATE_RUN,
        STATE_TERMINATE,
        STATE_ERROR
    }
    t_state;

    t_state state;
    logic raise_error;

    logic chk_ram_rdy;
    logic chk_fifo_full;


    // ====================================================================
    //
    // Random address generation function maps N_RAND_ADDR_BITS into a
    // line address.  Some input bits wind up in low address bits and some
    // wind up in higher bits that are on different pages.  This lets us
    // use a small enough working address space that it can be mapped to
    // block RAM for verification while also testing various MPF features.
    //
    // ====================================================================

    typedef logic [31:0] t_random;

    // Size of the allocated memory address region
`ifndef CFG_N_MEM_REGION_BITS
  `define CFG_N_MEM_REGION_BITS 26
`endif
    localparam N_MEM_REGION_BITS = `CFG_N_MEM_REGION_BITS;

    // Size of the checker region.  If this is smaller than N_MEM_REGION_BITS
    // then a subset of references are checked.
`ifndef CFG_N_CHECKED_ADDR_BITS
  `define CFG_N_CHECKED_ADDR_BITS 14
`endif
    localparam N_CHECKED_ADDR_BITS = `CFG_N_CHECKED_ADDR_BITS;
    typedef logic [N_CHECKED_ADDR_BITS-1 : 0] t_checked_addr_idx;

    // The checked address space is a mapping from the larger memory region,
    // taking mostly low address bits from the memory region but including
    // a few high bits so that multiple virtual pages are checked.  References
    // are checked only when the unmapped middle address bits are zero.

`ifndef CFG_N_CHECKED_LOW_ADDR_BITS
  `define CFG_N_CHECKED_LOW_ADDR_BITS 9
`endif
    localparam N_CHECKED_LOW_ADDR_BITS = `CFG_N_CHECKED_LOW_ADDR_BITS;

    typedef struct packed {
        logic [N_CHECKED_ADDR_BITS-N_CHECKED_LOW_ADDR_BITS-1 : 0] checked_high;
        logic [N_MEM_REGION_BITS-N_CHECKED_ADDR_BITS-1 : 0] unchecked_middle;
        logic [N_CHECKED_LOW_ADDR_BITS-1 : 0] checked_low;
    }
    t_mapped_addr_bits;


    // Random address type from a 32 bit LFSR
    function automatic t_mapped_addr_bits randAddrInFromLFSR(t_random r,
                                                             t_cci_clAddr mask);
        return t_mapped_addr_bits'(r) & t_mapped_addr_bits'(mask);
    endfunction

    // Random cache line address from a mapped address
    function automatic t_cci_clAddr randAddr(t_cci_clAddr base,
                                             t_mapped_addr_bits m);
        return base + t_cci_clAddr'(m);
    endfunction

    // Is an index checked?  Only a subset of references have a corresponding
    // block RAM check value.
    function automatic logic addrIsChecked(t_mapped_addr_bits m);
        // Check only if the unchecked middle bits are all zero.  Any
        // single state of the unchecked middle bits would work.
        return (|(m.unchecked_middle) == 1'b0);
    endfunction

    // Map full random address space to the checked space
    function automatic t_checked_addr_idx checkedAddr(t_mapped_addr_bits m);
        return {m.checked_high, m.checked_low};
    endfunction


    // ====================================================================
    //
    //   Almost full tracker
    //
    // ====================================================================

    // An AFU may continue to send up to CCI_TX_ALMOST_FULL_THRESHOLD
    // requests after the almost full signal is raised.  Use the maximum
    // so it is tested.

    logic c0TxAlmFull_vec[1 : CCI_TX_ALMOST_FULL_THRESHOLD-1];
    logic c0TxAlmFull;

    logic c1TxAlmFull_vec[1 : CCI_TX_ALMOST_FULL_THRESHOLD-1];
    logic c1TxAlmFull;

    assign c0TxAlmFull = c0TxAlmFull_vec[1] && fiu.c0TxAlmFull;
    assign c1TxAlmFull = c1TxAlmFull_vec[1] && fiu.c1TxAlmFull;

    always_ff @(posedge clk)
    begin
        c0TxAlmFull_vec[CCI_TX_ALMOST_FULL_THRESHOLD-1] <= fiu.c0TxAlmFull;
        c0TxAlmFull_vec[1 : CCI_TX_ALMOST_FULL_THRESHOLD-2] <=
            c0TxAlmFull_vec[2 : CCI_TX_ALMOST_FULL_THRESHOLD-1];

        c1TxAlmFull_vec[CCI_TX_ALMOST_FULL_THRESHOLD-1] <= fiu.c1TxAlmFull;
        c1TxAlmFull_vec[1 : CCI_TX_ALMOST_FULL_THRESHOLD-2] <=
            c1TxAlmFull_vec[2 : CCI_TX_ALMOST_FULL_THRESHOLD-1];

        if (reset)
        begin
            for (int i = 1; i < CCI_TX_ALMOST_FULL_THRESHOLD; i = i + 1)
            begin
                c0TxAlmFull_vec[i] <= 1'b1;
                c1TxAlmFull_vec[i] <= 1'b1;
            end
        end
    end


    // ====================================================================
    //
    //  CSRs
    //
    // ====================================================================

    typedef logic [39 : 0] t_counter;

    t_cci_clAddr dsm;
    t_cci_clAddr mem;
    t_cci_clAddr memMask;

    //
    // Read CSR from host
    //
    t_counter cnt_rd_rsp;
    t_counter cnt_wr_rsp;
    t_counter cnt_checked_rd;

    // Return these through a CSR in order to preserve the entire response,
    // making the dependence on CCI more realistic.
    logic c0Rx_xor;
    logic c1Rx_xor;

    logic [63:0] csr_state;
    always_ff @(posedge clk)
    begin
        csr_state <= { c0Rx_xor, c1Rx_xor,
                       46'(0),
                       8'(state),
                       1'(0),
                       c1NotEmpty,
                       c0NotEmpty,
                       chk_ram_rdy,
                       chk_fifo_full,
                       raise_error,
                       fiu.c1TxAlmFull,
                       fiu.c0TxAlmFull };
    end

    always_comb
    begin
        csrs.afu_id = `AFU_ACCEL_UUID;

        // Default
        for (int i = 0; i < NUM_TEST_CSRS; i = i + 1)
        begin
            csrs.cpu_rd_csrs[i].data = 64'(0);
        end

        // CSR 0 returns random address mapping details so the host can
        // compute the memory size.
        csrs.cpu_rd_csrs[0].data = { 32'(0),
                                     16'(N_CHECKED_ADDR_BITS),
                                     16'(N_MEM_REGION_BITS) };

        csrs.cpu_rd_csrs[1].data = 64'(dsm);
        csrs.cpu_rd_csrs[2].data = 64'(mem);

        // Number of reads responses
        csrs.cpu_rd_csrs[4].data = 64'(cnt_rd_rsp);

        // Number of completed writes
        csrs.cpu_rd_csrs[5].data = 64'(cnt_wr_rsp);

        // Number of checked reads
        csrs.cpu_rd_csrs[6].data = 64'(cnt_checked_rd);

        // Various state
        csrs.cpu_rd_csrs[7].data = csr_state;
    end

    //
    // Incoming configuration
    //
    t_counter cycles_rem;

    logic cl_beats_random;
    t_cci_clNum cl_beats;

    logic enable_writes;
    logic enable_reads;

    logic enable_wro;
    logic enable_checker;
    logic enable_rw_conflicts;

    logic enable_partial_writes;
    logic enable_partial_writes_all;

    logic rdline_mode_s;
    logic [1:0] wrline_req_type;

    logic cmd_start_en;
    logic [63:0] cmd_start;

    logic reset_chk_ram;

    //
    // Consume configuration CSR writes
    //
    always_ff @(posedge clk)
    begin
        cmd_start_en <= csrs.cpu_wr_csrs[0].en;
        cmd_start <= csrs.cpu_wr_csrs[0].data;

        if (csrs.cpu_wr_csrs[1].en)
        begin
            dsm <= csrs.cpu_wr_csrs[1].data;
            if (! reset) $display("DSM: 0x%x", csrs.cpu_wr_csrs[1].data);
        end

        if (csrs.cpu_wr_csrs[2].en)
        begin
            mem <= csrs.cpu_wr_csrs[2].data;
            if (! reset) $display("MEM: 0x%x", csrs.cpu_wr_csrs[2].data);
        end

        if (csrs.cpu_wr_csrs[3].en)
        begin
            memMask <= csrs.cpu_wr_csrs[3].data;
            if (! reset) $display("MEM MASK: 0x%x", csrs.cpu_wr_csrs[3].data);
        end

        // Any write to CSR 4 resets the checker RAM.
        reset_chk_ram <= csrs.cpu_wr_csrs[4].en;
    end

    //
    // Count cycles to run.
    //
    always_ff @(posedge clk)
    begin
        // Normal case: decrement cycle counter
        if (cycles_rem != t_counter'(0))
        begin
            cycles_rem <= cycles_rem - t_counter'(1);
        end

        // Execution cycle count update from the host?
        if (cmd_start_en)
        begin
            { cycles_rem,
              cl_beats_random,
              cl_beats,
              wrline_req_type,
              rdline_mode_s,
              enable_partial_writes_all,
              enable_partial_writes,
              enable_rw_conflicts,
              enable_checker,
              enable_wro,
              enable_writes,
              enable_reads } <= cmd_start;
        end

        if (reset)
        begin
            cycles_rem <= t_counter'(0);
            cl_beats_random <= 1'b0;
            cl_beats <= t_cci_clLen'(0);
            wrline_req_type <= 2'b0;
            rdline_mode_s <= 1'b0;
            enable_writes <= 1'b0;
            enable_reads <= 1'b0;
            enable_wro <= 1'b0;
            enable_checker <= 1'b0;
            enable_rw_conflicts <= 1'b0;
            enable_partial_writes <= 1'b0;
            enable_partial_writes_all <= 1'b0;
        end
    end


    logic start_new_run;
    t_cci_clNum wr_beat_num;

    always_ff @(posedge clk)
    begin
        start_new_run <= cmd_start_en;

        case (state)
          STATE_IDLE:
            begin
                // New run requested
                if (start_new_run)
                begin
                    state <= STATE_RUN;
                    $display("Starting test...");
                end
            end

          STATE_RUN:
            begin
                // Finished ?
                if (cycles_rem == t_counter'(0))
                begin
                    state <= STATE_TERMINATE;
                    $display("Ending test...");
                end

                if (raise_error)
                begin
                    state <= STATE_ERROR;
                end
            end

          default:
            begin
                // Various signalling states terminate when a write is allowed
                if (! c1TxAlmFull && (wr_beat_num == t_cci_clNum'(0)))
                begin
                    state <= STATE_IDLE;
                    $display("Test done.");
                end
            end
        endcase

        if (reset)
        begin
            start_new_run <= 1'b0;
            state <= STATE_IDLE;
        end
    end


    // ====================================================================
    //
    //   Random multi-line size generator
    //
    // ====================================================================

    t_cci_clLen rand_rd_beats;
    t_cci_clLen rand_wr_beats;

    logic [11:0] ml_lfsr;

    function automatic t_cci_clLen randomMultiLineLen(logic [3:0] r);
        t_cci_clLen cl;

        case (r) inside
            [4'd0:4'd5]:  cl = eCL_LEN_1;
            [4'd6:4'd10]: cl = eCL_LEN_2;
            default:      cl = eCL_LEN_4;
        endcase

        return cl;
    endfunction

    assign rand_rd_beats = randomMultiLineLen(ml_lfsr[3:0]);
    assign rand_wr_beats = randomMultiLineLen(ml_lfsr[7:4]);

    cci_mpf_prim_lfsr12
      #(
        .INITIAL_VALUE(12'(513))
        )
      pwm_lfsr
       (
        .clk,
        .reset,
        .en(1'b1),
        .value(ml_lfsr)
        );


    // ====================================================================
    //
    //   Reads
    //
    // ====================================================================

    t_cci_mpf_ReqMemHdrParams rd_params;
    always_comb
    begin
        rd_params = cci_mpf_defaultReqHdrParams();
        rd_params.checkLoadStoreOrder = enable_wro;
        rd_params.vc_sel = eVC_VA;
        rd_params.mapVAtoPhysChannel = 1'b1;
    end

    //
    // Random address
    //
    t_random rd_lfsr_val;
    cci_mpf_prim_lfsr32
      #(
        .INITIAL_VALUE(32'h2721)
        )
      rd_lfsr
       (
        .clk,
        .reset,
        .en(1'b1),
        .value(rd_lfsr_val)
        );

    t_mapped_addr_bits rd_addr_rand_idx;
    always_comb
    begin
        rd_addr_rand_idx = randAddrInFromLFSR(rd_lfsr_val, memMask);

        // If read/write conflicts aren't allowed then force an address bit
        // to zero.  The corresponding bit for writes will be forced to one.
        if (! enable_rw_conflicts)
        begin
            rd_addr_rand_idx.checked_low[2] = 1'b0;
        end
    end

    t_cci_clAddr rd_rand_addr;

    t_cci_clLen rd_addr_num_beats;
    t_cci_clNum rd_addr_chk_beat;

    logic rd_addr_is_checked;
    t_checked_addr_idx rd_addr_chk_idx;
    t_checked_addr_idx rd_addr_chk_idx_q;

    // Read needs to know a little about writes
    t_checked_addr_idx wr_addr_chk_idx;

    t_cci_clLen rd_beats;
    always_ff @(posedge clk)
    begin
        rd_beats <= cl_beats_random ? rand_rd_beats : t_cci_clLen'(cl_beats);
    end

    // Generate a mask of low bits that must be zero in order to align
    // the address to the number of beats requested.
    t_cci_clNum rd_beats_mask;
    assign rd_beats_mask = ~rd_beats;

    // Map the random address index to the address space
    always_ff @(posedge clk)
    begin
        rd_rand_addr <= randAddr(mem, rd_addr_rand_idx);
        // Align address to number of beats
        rd_rand_addr[0 +: $bits(t_cci_clNum)] <=
            t_cci_clLen'(rd_addr_rand_idx) & rd_beats_mask;

        rd_addr_num_beats <= rd_beats;
        // Only one random beat will be checked.  Pick it based on the
        // low bits of the chosen random address.
        rd_addr_chk_beat <= t_cci_clLen'(rd_addr_rand_idx) & rd_beats;

        rd_addr_is_checked <= addrIsChecked(rd_addr_rand_idx);
        rd_addr_chk_idx <= checkedAddr(rd_addr_rand_idx);
        rd_addr_chk_idx_q <= rd_addr_chk_idx;

        if (reset)
        begin
            rd_addr_chk_idx <= t_checked_addr_idx'(0);
        end
    end


    t_cci_mpf_c0_ReqMemHdr rd_hdr;
    always_comb
    begin
        // Avoid a race in multi-beat writes.  In MPF the write is treated
        // atomically and fires with its last beat.  In the test here the
        // check BRAM is updated with each beat, making the early beats appear
        // to be updated in the checker BRAM but not yet updated in MPF.
        // We "solve" this by avoiding conflicting addresses in this window.
        logic chk_rd;
        chk_rd = rd_addr_is_checked &&
                 ((rd_addr_chk_idx[$bits(t_cci_clNum)-1 : 0] >= 
                   (wr_addr_chk_idx[$bits(t_cci_clNum)-1 : 0] | wr_beat_num)) ||
                  (rd_addr_chk_idx[N_CHECKED_ADDR_BITS-1 : $bits(t_cci_clNum)] !=
                   wr_addr_chk_idx[N_CHECKED_ADDR_BITS-1 : $bits(t_cci_clNum)]));

        rd_hdr = cci_mpf_c0_genReqHdr(
                     (rdline_mode_s ? eREQ_RDLINE_S : eREQ_RDLINE_I),
                     rd_rand_addr,
                     // Indicate in mdata whether requested address is checked
                     t_cci_mdata'({ rd_addr_chk_beat, chk_rd }),
                     rd_params);

        rd_hdr.base.cl_len = rd_addr_num_beats;
    end

    always_ff @(posedge clk)
    begin
        // Request a read when the state is STATE_RUN and the request
        // pipeline has space.
        fiu.c0Tx <=
            cci_mpf_genC0TxReadReq(rd_hdr,
                                   (state == STATE_RUN) &&
                                   enable_reads &&
                                   chk_rdy &&
                                   ! c0TxAlmFull);

        if (reset)
        begin
            fiu.c0Tx.valid <= 1'b0;
        end
    end

    logic c0Rx_is_read_rsp;

    always_ff @(posedge clk)
    begin
        c0Rx_is_read_rsp <= cci_c0Rx_isReadRsp(fiu.c0Rx);
        if (c0Rx_is_read_rsp)
        begin
            cnt_rd_rsp <= cnt_rd_rsp + t_counter'(1);
        end

        if (reset || start_new_run)
        begin
            cnt_rd_rsp <= t_counter'(0);
            c0Rx_is_read_rsp <= 1'b0;
        end
    end

    //
    // Force preservation of the entire c0Rx response in order to be more
    // realistic.
    //
    t_if_cci_c0_Rx c0Rx;
    logic [7:0] c0Rx_xor_v;
    logic c0Rx_xor_t;

    always_ff @(posedge clk)
    begin
        c0Rx <= fiu.c0Rx;

        // Two stage XOR reduction of c0Rx
        if (cci_c0Rx_isValid(c0Rx))
        begin
            for (int i = 0; i < 8; i = i + 1)
            begin
                c0Rx_xor_v[i] <= ^(c0Rx[i * ($bits(c0Rx) / 8) +: ($bits(c0Rx) / 8)]);
            end
        end

        c0Rx_xor_t <= ^c0Rx_xor_v;
        c0Rx_xor <= c0Rx_xor_t;

        if (reset)
        begin
            c0Rx_xor <= '0;
            c0Rx_xor_v <= '0;
            c0Rx_xor_t <= 1'b0;
        end
    end

    assign fiu.c2Tx.mmioRdValid = 1'b0;


    // ====================================================================
    //
    //   Writes
    //
    // ====================================================================

    t_cci_mpf_ReqMemHdrParams wr_params;
    always_comb
    begin
        wr_params = cci_mpf_defaultReqHdrParams();
        wr_params.checkLoadStoreOrder = enable_wro;
        wr_params.vc_sel = eVC_VA;
        wr_params.mapVAtoPhysChannel = 1'b1;
    end

    //
    // Random address
    //
    t_random wr_lfsr_val;
    cci_mpf_prim_lfsr32
      #(
        .INITIAL_VALUE(32'h8520)
        )
      wr_lfsr
       (
        .clk,
        .reset,
        .en(1'b1),
        .value(wr_lfsr_val)
        );

    t_mapped_addr_bits wr_addr_rand_idx;
    always_comb
    begin
        wr_addr_rand_idx = randAddrInFromLFSR(wr_lfsr_val, memMask);

        // If read/write conflicts aren't allowed then force an address bit
        // to one.  The corresponding bit for reads will be forced to zero.
        if (! enable_rw_conflicts)
        begin
            wr_addr_rand_idx.checked_low[2] = 1'b1;
        end
    end

    t_cci_clAddr wr_rand_addr;
    logic wr_addr_is_checked;
    t_checked_addr_idx wr_addr_chk_idx_q;

    t_cci_clLen wr_beats;
    logic wr_beat_last;

    t_cci_clLen wr_beats_next;
    always_ff @(posedge clk)
    begin
        wr_beats_next <= cl_beats_random ? rand_wr_beats : t_cci_clLen'(cl_beats);
    end

    t_cci_clNum wr_beats_mask;
    assign wr_beats_mask = ~wr_beats_next;

    // Map the random address index to the address space
    always_ff @(posedge clk)
    begin
        if (wr_beat_last || start_new_run)
        begin
            // Pick a new random address
            wr_rand_addr <= randAddr(mem, wr_addr_rand_idx);
            // Align address to number of beats
            wr_rand_addr[0 +: $bits(t_cci_clNum)] <=
                t_cci_clLen'(wr_addr_rand_idx) & wr_beats_mask;

            wr_addr_is_checked <= addrIsChecked(wr_addr_rand_idx);
            wr_addr_chk_idx <= checkedAddr(wr_addr_rand_idx);
            wr_addr_chk_idx[0 +: $bits(t_cci_clNum)] <=
                t_cci_clLen'(wr_addr_rand_idx) & wr_beats_mask;

            wr_beats <= wr_beats_next;
        end

        wr_addr_chk_idx_q <= wr_addr_chk_idx;
        wr_addr_chk_idx_q[0 +: $bits(t_cci_clNum)] <=
            wr_addr_chk_idx | wr_beat_num;

        if (reset)
        begin
            wr_beats <= eCL_LEN_2;
            wr_addr_chk_idx <= t_checked_addr_idx'(0);
        end
    end


    //
    // Random partial write control
    //
    t_cci_mpf_c1_PartialWriteHdr pwh, pwh_q;
`ifdef CCIP_ENCODING_HAS_BYTE_WR
    t_ccip_mem_access_mode pw_mode;
    t_ccip_clByteIdx pw_byte_start, pw_byte_len;
`endif

    test_gen_pwrite_hdr
      gen_pwrite_hdr
       (
        .clk,
        .reset,
        .enable_partial_writes,
        .enable_partial_writes_all,
        .write_is_single_line(wr_beats == t_cci_clNum'(0)),

`ifdef CCIP_ENCODING_HAS_BYTE_WR
        .pw_mode,
        .pw_byte_start,
        .pw_byte_len,
`endif
        .pwh
        );

    always_ff @(posedge clk)
    begin
        pwh_q <= pwh;
    end


    //
    // Write request header
    //
    t_cci_mpf_c1_ReqMemHdr wr_hdr;

    always_comb
    begin
        wr_hdr = cci_mpf_c1_genReqHdr(t_cci_c1_req'(wrline_req_type),
                                      wr_rand_addr,
                                      t_cci_mdata'(0),
                                      wr_params);

        // Get the low bits of the address right
        wr_hdr.base.sop = (wr_beat_num == t_cci_clNum'(0));
        wr_hdr.base.cl_len = wr_beats;
        wr_hdr.base.address[0 +: $bits(t_cci_clNum)] =
            wr_hdr.base.address[0 +: $bits(t_cci_clNum)] | wr_beat_num;

`ifdef CCIP_ENCODING_HAS_BYTE_WR
        wr_hdr.base.mode = pw_mode;
        wr_hdr.base.byte_start = pw_byte_start;
        wr_hdr.base.byte_len = pw_byte_len;
`endif
        if (PARTIAL_WRITE_MODE == "BYTE_MASK")
        begin
            wr_hdr.pwrite = pwh;
        end
    end

    //
    // Random data
    //
    t_cci_clData wr_rand_data;

    test_gen_write_data
      gen_write_data
       (
        .clk,
        .reset,
        .wr_rand_data
        );


    //
    // Generate write requests
    //
    logic chk_wr_valid_q;

    t_cci_clNum wr_beat_num_next;
    always_comb
    begin
        wr_beat_last = (t_cci_clLen'(wr_beat_num) == wr_beats);

        if (wr_beat_last)
        begin
            wr_beat_num_next = t_cci_clNum'(0);
        end
        else
        begin
            wr_beat_num_next = wr_beat_num + t_cci_clNum'(1);
        end
    end

    always_ff @(posedge clk)
    begin
        chk_wr_valid_q <= 1'b0;
        fiu.c1Tx <= cci_mpf_genC1TxWriteReq(wr_hdr,
                                            t_cci_clData'(wr_rand_data),
                                            1'b0);

        if (wr_beat_num != t_cci_clNum'(0))
        begin
            // Don't stop in the middle of a multi-beat write
            fiu.c1Tx.valid <= 1'b1;
            chk_wr_valid_q <= wr_addr_is_checked;
            wr_beat_num <= wr_beat_num_next;
        end
        else if (! c1TxAlmFull)
        begin
            // Normal running state
            if (state == STATE_RUN)
            begin
                fiu.c1Tx.valid <= chk_rdy && enable_writes;
                chk_wr_valid_q <= chk_rdy && enable_writes && wr_addr_is_checked;

                // Update beat number
                if (chk_rdy && enable_writes)
                begin
                    wr_beat_num <= wr_beat_num_next;
                end
            end

            // Normal termination: signal done by writing to status memory
            if (state == STATE_TERMINATE)
            begin
                fiu.c1Tx.valid <= 1'b1;
                fiu.c1Tx.hdr.base.req_type <= eREQ_WRLINE_I;
                fiu.c1Tx.hdr.base.address <= dsm;
                fiu.c1Tx.hdr.base.sop <= 1'b1;
                fiu.c1Tx.hdr.base.cl_len <= eCL_LEN_1;
`ifdef CCIP_ENCODING_HAS_BYTE_WR
                fiu.c1Tx.hdr.base.mode <= eMOD_CL;
                fiu.c1Tx.hdr.base.byte_start <= t_ccip_clByteIdx'(0);
                fiu.c1Tx.hdr.base.byte_len <= t_ccip_clByteIdx'(0);
`endif
                fiu.c1Tx.hdr.pwrite.isPartialWrite <= 1'b0;
                fiu.c1Tx.data[63:0] <= t_cci_clData'(1);
            end

            // Error termination: signal error in status memory
            if (state == STATE_ERROR)
            begin
                fiu.c1Tx.valid <= 1'b1;
                fiu.c1Tx.hdr.base.req_type <= eREQ_WRLINE_I;
                fiu.c1Tx.hdr.base.address <= dsm;
                fiu.c1Tx.hdr.base.sop <= 1'b1;
                fiu.c1Tx.hdr.base.cl_len <= eCL_LEN_1;
`ifdef CCIP_ENCODING_HAS_BYTE_WR
                fiu.c1Tx.hdr.base.mode <= eMOD_CL;
                fiu.c1Tx.hdr.base.byte_start <= t_ccip_clByteIdx'(0);
                fiu.c1Tx.hdr.base.byte_len <= t_ccip_clByteIdx'(0);
`endif
                fiu.c1Tx.hdr.pwrite.isPartialWrite <= 1'b0;
                fiu.c1Tx.data[63:0] <= t_cci_clData'(2);
            end
        end

        if (reset)
        begin
            fiu.c1Tx.valid <= 1'b0;
            wr_beat_num <= t_cci_clNum'(0);
        end
    end

    logic c1Rx_is_write_rsp;
    t_cci_clNum c1Rx_cl_num;

    always_ff @(posedge clk)
    begin
        c1Rx_is_write_rsp <= cci_c1Rx_isWriteRsp(fiu.c1Rx);
        c1Rx_cl_num <= fiu.c1Rx.hdr.cl_num;

        if (c1Rx_is_write_rsp)
        begin
            // Count beats so multi-line writes get credit for all data
            cnt_wr_rsp <= cnt_wr_rsp + t_counter'(1) + t_counter'(c1Rx_cl_num);
        end

        if (reset || start_new_run)
        begin
            cnt_wr_rsp <= t_counter'(0);
            c1Rx_is_write_rsp <= 1'b0;
        end
    end

    //
    // Force preservation of the entire c1Rx response in order to be more
    // realistic.
    //
    t_if_cci_c1_Rx c1Rx;
    logic [7:0] c1Rx_xor_v;
    logic c1Rx_xor_t;

    always_ff @(posedge clk)
    begin
        c1Rx <= fiu.c1Rx;

        // Two stage XOR reduction of c1Rx
        if (cci_c1Rx_isValid(c1Rx))
        begin
            for (int i = 0; i < 8; i = i + 1)
            begin
                c1Rx_xor_v[i] <= ^(c1Rx[i * ($bits(c1Rx) / 8) +: ($bits(c1Rx) / 8)]);
            end
        end

        c1Rx_xor_t <= ^c1Rx_xor_v;
        c1Rx_xor <= c1Rx_xor_t;

        if (reset)
        begin
            c1Rx_xor <= '0;
            c1Rx_xor_v <= '0;
            c1Rx_xor_t <= 1'b0;
        end
    end


    // ====================================================================
    //
    //   Checker
    //
    // ====================================================================

    // Map one line to a tag. We will use one tag bit per data byte.
    typedef logic [(CCI_CLDATA_WIDTH / 8) - 1 : 0] t_mem_tag;
    // With one bit per byte in t_mem_tag, the mask of tag data is
    // the same size.
    typedef logic [(CCI_CLDATA_WIDTH / 8) - 1 : 0] t_mem_tag_mask;

    // The mapping function from a line of data to tags is a simple XOR
    // in each byte. We could do something smarter, but the point is to
    // detect errors. Do enough reads and writes and this will eventually
    // be good enough.
    function automatic t_mem_tag lineToTag(t_cci_clData v);
        t_mem_tag tag;

        for (int i = 0; i < $bits(t_mem_tag); i = i + 1)
        begin
            // XOR each byte into tag bits
            tag[i] = (^(v[(8 * i) +: 8]));
        end

        return tag;
    endfunction

    // Generate the write mask.  Partial writes don't update all bytes.
    // The tag's mask bits must correspond to the bytes checked in lineToTag().
    function automatic t_mem_tag_mask lineToTagMask(t_cci_mpf_c1_PartialWriteHdr h);
        t_mem_tag_mask m;

        for (int i = 0; i < $bits(t_mem_tag_mask); i = i + 1)
        begin
            m[i] = h.mask[i]  || ! h.isPartialWrite;
        end

        return m;
    endfunction

    //
    // Block RAM holding tags representing memory state
    //
    t_mem_tag wr_chk_data;
    assign wr_chk_data = lineToTag(fiu.c1Tx.data);
    t_mem_tag_mask wr_chk_mask;
    assign wr_chk_mask = lineToTagMask(pwh_q);

    t_mem_tag rd_chk_data;
    t_mem_tag chk_ram_rdy_all;

    always_ff @(posedge clk)
    begin
        chk_ram_rdy <= (&(chk_ram_rdy_all));

        chk_rdy <= chk_ram_rdy && ! chk_fifo_full;
        if (reset || reset_chk_ram)
        begin
            chk_rdy <= 1'b0;
        end
    end

    genvar b;
    generate
        for (b = 0; b < $bits(t_mem_tag); b = b + 1)
        begin : tb
            cci_mpf_prim_ram_simple_init
              #(
                .N_ENTRIES(1 << N_CHECKED_ADDR_BITS),
                .N_DATA_BITS(1),
                .N_OUTPUT_REG_STAGES(2),
                .REGISTER_WRITES(1),
                .BYPASS_REGISTERED_WRITES(1)
                )
              chk_ram
               (
                .clk(clk),
                .reset(reset || reset_chk_ram),
                .rdy(chk_ram_rdy_all[b]),

                // Update RAM with written data
                .waddr(wr_addr_chk_idx_q),
                .wen(chk_wr_valid_q && wr_chk_mask[b]),
                .wdata(wr_chk_data[b]),

                // Reads match CCI read requests
                .raddr(rd_addr_chk_idx_q),
                .rdata(rd_chk_data[b])
                );
        end
    endgenerate

    // Forward block RAM reads to a FIFO.  The block RAM reads will be matched
    // with CCI read responses.
    logic chk_rd_q;
    logic chk_rd_qq;
    logic chk_rd_qqq;

    t_cci_clAddr chk_rd_addr_q;
    t_cci_clAddr chk_rd_addr_qq;
    t_cci_clAddr chk_rd_addr_qqq;

    always_ff @(posedge clk)
    begin
        // mdata[0] indicates whether the read is checked
        chk_rd_q <= fiu.c0Tx.valid && fiu.c0Tx.hdr.base.mdata[0];
        chk_rd_qq <= chk_rd_q;
        chk_rd_qqq <= chk_rd_qq;

        chk_rd_addr_q <= fiu.c0Tx.hdr.base.address;
        // mdata indicates which beat is checked
        chk_rd_addr_q[0 +: $bits(t_cci_clNum)] <=
            fiu.c0Tx.hdr.base.address[0 +: $bits(t_cci_clNum)] |
            fiu.c0Tx.hdr.base.mdata[1 +: $bits(t_cci_clNum)];

        chk_rd_addr_qq <= chk_rd_addr_q;
        chk_rd_addr_qqq <= chk_rd_addr_qq;

        if (reset)
        begin
            chk_rd_q <= 1'b0;
            chk_rd_qq <= 1'b0;
            chk_rd_qqq <= 1'b0;
        end
    end

    t_mem_tag chk_first;
    t_cci_clAddr chk_first_addr;

    //
    // Much of the data flowing through the FIFOs is consumed only by
    // $display() and will be dropped by HW synthesis.
    //

    logic chk_notEmpty;
    logic rsp_notEmpty;

    logic fifo_deq;
    assign fifo_deq = chk_notEmpty && rsp_notEmpty;

    cci_mpf_prim_fifo_bram
      #(
        .N_DATA_BITS($bits(t_mem_tag) + $bits(t_cci_clAddr)),
        .N_ENTRIES(1024),
        .THRESHOLD(8)
        )
      chk_fifo
       (
        .clk,
        .reset,

        .enq_data({rd_chk_data, chk_rd_addr_qqq}),
        .enq_en(chk_rd_qqq),
        .notFull(),
        .almostFull(chk_fifo_full),

        .first({chk_first, chk_first_addr}),
        .deq_en(fifo_deq),
        .notEmpty(chk_notEmpty)
        );


    t_mem_tag c0Rx_tag;
    t_cci_clData c0Rx_data;

    cci_mpf_prim_fifo_bram
      #(
        .N_DATA_BITS($bits(t_mem_tag) + $bits(t_cci_clData)),
        .N_ENTRIES(1024)
        )
      rsp_fifo
       (
        .clk,
        .reset,

        .enq_data({lineToTag(c0Rx.data), c0Rx.data}),
        // mdata[0] indicates whether the read is checked
        .enq_en(cci_c0Rx_isReadRsp(c0Rx) &&
                c0Rx.hdr.mdata[0] &&
                (c0Rx.hdr.cl_num == c0Rx.hdr.mdata[1 +: $bits(t_cci_clNum)])),
        .notFull(),
        .almostFull(),

        .first({c0Rx_tag, c0Rx_data}),
        .deq_en(fifo_deq),
        .notEmpty(rsp_notEmpty)
        );

    //
    // Compare checker to CCI read responses.
    //
    always_ff @(posedge clk)
    begin
        if (state == STATE_RUN)
        begin
            if (fifo_deq)
            begin
                cnt_checked_rd <= cnt_checked_rd + t_counter'(enable_checker);

                if (c0Rx_tag != chk_first)
                begin
                    raise_error <= enable_checker;

                    if (! reset)
                    begin
                        $display("ERROR: Addr 0x%x, expected 0x%x, got 0x%x, line 0x%x",
                                 chk_first_addr,
                                 chk_first, c0Rx_tag,
                                 c0Rx_data);
                    end
                end
            end
        end

        if (reset || start_new_run)
        begin
            raise_error <= 1'b0;
            cnt_checked_rd <= t_counter'(0);
        end
    end


endmodule // test_afu


//
// Generate random write data.
//
module test_gen_write_data
   (
    input  logic clk,
    input  logic reset,

    output t_cci_clData wr_rand_data
    );

    logic [(CCI_CLDATA_WIDTH / 32)-1 : 0][31:0] wr_data;
    assign wr_rand_data = wr_data;

    genvar r;
    generate
        for (r = 0; r < CCI_CLDATA_WIDTH / 32; r = r + 1)
        begin : d
            cci_mpf_prim_lfsr32
              #(
                .INITIAL_VALUE(32'(r+1))
                )
              wr_lfsr
               (
                .clk,
                .reset,
                .en(1'b1),
                .value(wr_data[r])
                );
        end
    endgenerate

endmodule // test_gen_write_data


//
// Generate partial write headers, including the decision of whether a
// write should be full or partial.
//
module test_gen_pwrite_hdr
   (
    input  logic clk,
    input  logic reset,
    input  logic enable_partial_writes,
    input  logic enable_partial_writes_all,
    // Is current write, generated this cycle, a single line write?
    input  logic write_is_single_line,

`ifdef CCIP_ENCODING_HAS_BYTE_WR
    output t_ccip_mem_access_mode pw_mode,
    output t_ccip_clByteIdx pw_byte_start,
    output t_ccip_clByteIdx pw_byte_len,
`endif
    output t_cci_mpf_c1_PartialWriteHdr pwh
    );

    localparam string PARTIAL_WRITE_MODE = `MPF_CONF_PARTIAL_WRITE_MODE;
    localparam PWRITE_USE_BYTE_RANGE = (PARTIAL_WRITE_MODE == "BYTE_RANGE");

    // Decide whether write is full or partial using an LFSR
    logic [11:0] pw_lfsr;

    cci_mpf_prim_lfsr12
      #(
        .INITIAL_VALUE(12'(15))
        )
      pwm_lfsr
       (
        .clk,
        .reset,
        .en(1'b1),
        .value(pw_lfsr)
        );

`ifdef CCIP_ENCODING_HAS_BYTE_WR
    //
    // Generate a mask selecting all bytes in a line above and including start_idx.
    //
    function automatic t_cci_mpf_clDataByteMask decodeMaskStart(t_ccip_clByteIdx start_idx);
        t_cci_mpf_clDataByteMask masks[CCIP_CLDATA_BYTE_WIDTH];

        // Build a lookup table, with 1's in all bits idx and higher.
        masks[0] = ~t_cci_mpf_clDataByteMask'(0);
        for (int i = 1; i < CCIP_CLDATA_BYTE_WIDTH; i = i + 1)
        begin
            // Shift in another 0
            masks[i] = masks[i-1] << 1;
        end

        return masks[start_idx];
    endfunction

    //
    // Generate a mask selecting all bytes in a line below and including end_idx.
    //
    function automatic t_cci_mpf_clDataByteMask decodeMaskEnd(t_ccip_clByteIdx end_idx);
        t_cci_mpf_clDataByteMask masks[CCIP_CLDATA_BYTE_WIDTH];

        // Build a lookup table, with 0's in all bits above idx.
        masks[0] = 1;
        for (int i = 1; i < CCIP_CLDATA_BYTE_WIDTH; i = i + 1)
        begin
            // Shift in another 1
            masks[i] = (masks[i-1] << 1) | 1'b1;
        end

        return masks[end_idx];
    endfunction
`endif

    genvar r;
    generate
`ifdef CCIP_ENCODING_HAS_BYTE_WR
        if (PWRITE_USE_BYTE_RANGE)
        begin : br
            //
            // Use byte ranges (the CCI-P native encoding).
            //

            //
            // The random byte range generator produces a stream of random ranges,
            // some of which are used and some are dropped. This makes it easy
            // to pipeline the generator without dealing with back-pressure.
            //
            logic [31:0] rand_value;

            cci_mpf_prim_lfsr32
              #(
                .INITIAL_VALUE(32'(1001))
                )
              pwm_lfsr
               (
                .clk,
                .reset,
                .en(1'b1),
                .value(rand_value)
                );

            // Sort the random start/end positions given the rand_value.
            t_ccip_clByteIdx rand_idx[2];
            assign {rand_idx[1], rand_idx[0]} = rand_value;

            t_ccip_clByteIdx rand_start, rand_end;

            always_ff @(posedge clk)
            begin
                if (rand_idx[0] < rand_idx[1])
                begin
                    rand_start <= rand_idx[0];
                    rand_end <= rand_idx[1];
                end
                else
                begin
                    rand_start <= rand_idx[1];
                    rand_end <= rand_idx[0];
                end
            end

            //
            // Now we can turn the rand_idx range and turn it into a start
            // and length. The vector entries are pipeline stages.
            //
            t_ccip_clByteIdx byte_start[2], byte_len[2];

            // byte_end is used for making a bit mask for the same range, used
            // by the test verification logic.
            t_ccip_clByteIdx byte_end;

            always_ff @(posedge clk)
            begin
                byte_start[0] <= rand_start;

                if ((rand_start == t_ccip_clByteIdx'(0)) &&
                    (rand_end == ~t_ccip_clByteIdx'(0)))
                begin
                    // Can't encode writing the whole line. Pick a different
                    // length.
                    byte_len[0] <= ~t_ccip_clByteIdx'(0);
                    byte_end <= ~t_ccip_clByteIdx'(0) - t_ccip_clByteIdx'(1);
                end
                else
                begin
                    byte_len[0] <= rand_end - rand_start + t_ccip_clByteIdx'(1);
                    byte_end <= rand_end;
                end
            end

            t_cci_mpf_clDataByteMask byte_mask;

            always_ff @(posedge clk)
            begin
                byte_start[1] <= byte_start[0];
                byte_len[1] <= byte_len[0];

                byte_mask <= decodeMaskStart(byte_start[0]) & decodeMaskEnd(byte_end);
            end

            //
            // Generate outbound state. We still encode the bit mask and set
            // isPartialWrite, but that is only for the benefit of the comparison
            // logic in this test. MPF will force isPartialWrite off when in
            // BYTE_RANGE mode as requests arrive. It will only honor the CCI-P
            // byte range encoding.
            //
            always_comb
            begin
                if (write_is_single_line &&
                    (enable_partial_writes_all ||
                     ((6'(pw_lfsr) == 6'(0)) && enable_partial_writes)))
                begin
                    pw_mode = eMOD_BYTE;
                    pw_byte_start = byte_start[1];
                    pw_byte_len = byte_len[1];
                    pwh.isPartialWrite = 1'b1;
                end
                else
                begin
                    pw_mode = eMOD_CL;
                    pw_byte_start = t_ccip_clByteIdx'(0);
                    pw_byte_len = t_ccip_clByteIdx'(0);
                    pwh.isPartialWrite = 1'b0;
                end

                pwh.mask = byte_mask;
            end
        end
        else
`endif
        begin : mask
            //
            // Use MPF-only mode: random partial write mask. This mode is always
            // emulated in MPF as read-modify-write.
            //
            logic [($bits(t_cci_mpf_clDataByteMask) / 32)-1 : 0][31:0] pw_rand_mask;
            for (r = 0; r < $bits(t_cci_mpf_clDataByteMask) / 32; r = r + 1)
            begin : pwm
                cci_mpf_prim_lfsr32
                  #(
                    .INITIAL_VALUE(32'(r+1001))
                    )
                  pwm_lfsr
                   (
                    .clk,
                    .reset,
                    .en(1'b1),
                    .value(pw_rand_mask[r])
                    );
            end

            //
            // Generate the header
            //
            always_ff @(posedge clk)
            begin
                pwh.mask <= pw_rand_mask;

                // Most writes are not partial
                pwh.isPartialWrite <= ((6'(pw_lfsr) == 6'(0)) && enable_partial_writes) ||
                                      enable_partial_writes_all;
            end

            //
            // Tie off CCI-P byte-range signals
            //
`ifdef CCIP_ENCODING_HAS_BYTE_WR
            always_comb
            begin
                pw_mode = eMOD_CL;
                pw_byte_start = t_ccip_clByteIdx'(0);
                pw_byte_len = t_ccip_clByteIdx'(0);
            end
`endif
        end
    endgenerate

endmodule // test_gen_pwrite_hdr
