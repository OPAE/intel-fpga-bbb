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

`include "platform_if.vh"
`include "cci_mpf_if.vh"
`include "cci_test_csrs.vh"

// Generated from the AFU JSON file by afu_json_mgr
`include "afu_json_info.vh"

module test_afu
   (
    input  logic clk,

    // Connection toward the host.  Reset comes in here.
    cci_mpf_if.to_fiu fiu,

    // CSR connections
    test_csrs.test csrs,

    // MPF tracks outstanding requests.  These will be true as long as
    // reads or unacknowledged writes are still in flight.
    input  logic c0NotEmpty,
    input  logic c1NotEmpty
    );

    // Local reset to reduce fan-out
    logic reset = 1'b1;
    always @(posedge clk)
    begin
        reset <= fiu.reset;
    end


    localparam MAX_RD_ENGINES = 8;
    typedef logic [$clog2(MAX_RD_ENGINES)-1 : 0] t_rd_engine_idx;

    typedef logic [31:0] t_hash;


    //
    // Convert between byte addresses and line addresses.  The conversion
    // is simple: adding or removing low zero bits.
    //

    localparam CL_BYTE_IDX_BITS = 6;
    typedef logic [$bits(t_cci_clAddr) + CL_BYTE_IDX_BITS - 1 : 0] t_byteAddr;

    function automatic t_cci_clAddr byteAddrToClAddr(t_byteAddr addr);
        return addr[CL_BYTE_IDX_BITS +: $bits(t_cci_clAddr)];
    endfunction

    function automatic t_byteAddr clAddrToByteAddr(t_cci_clAddr addr);
        return {addr, CL_BYTE_IDX_BITS'(0)};
    endfunction


    // ====================================================================
    //
    //  CSRs (simple connections to the external CSR management engine)
    //
    // ====================================================================

    typedef logic [39:0] t_counter;

    //
    // Configuration state, set by host.
    //

    // Index of the engine to access through CSRs. This indirection reduces
    // the number of CSR addresses required.
    t_rd_engine_idx cur_rd_engine_csr_idx;

    // Index of the last active read engine
    t_rd_engine_idx last_rd_engine_idx;

    // Read engine descriptor
    typedef struct packed {
        // Base address of the engine's buffer
        t_cci_clAddr base_addr;

        // Expected hash value of the buffer's data
        t_hash expected_hash;
    }
    t_rd_engine_cfg;

    t_rd_engine_cfg rd_engine_cfg[MAX_RD_ENGINES];
    logic [MAX_RD_ENGINES-1 : 0] rd_engine_error;

    typedef struct packed {
        t_hash last_hash;
        t_counter trips;
        t_counter dropped_reads;
        t_counter spec_errors;
    }
    t_rd_engine_data;

    t_rd_engine_data rd_engine_data[MAX_RD_ENGINES];
    t_rd_engine_data cur_rd_engine_data;

    logic enabled;
    logic [47:0] test_cycles;

    always_ff @(posedge clk)
    begin
        cur_rd_engine_data <= rd_engine_data[cur_rd_engine_csr_idx];
    end

    always_comb
    begin
        // The AFU ID is a unique ID for a given program.  Here we generated
        // one with the "uuidgen" program and stored it in the AFU's JSON file.
        // ASE and synthesis setup scripts automatically invoke afu_json_mgr
        // to extract the UUID into afu_json_info.vh.
        csrs.afu_id = `AFU_ACCEL_UUID;

        // Default
        for (int i = 0; i < NUM_TEST_CSRS; i = i + 1)
        begin
            csrs.cpu_rd_csrs[i].data = 64'(0);
        end

        // Status
        csrs.cpu_rd_csrs[0].data = 64'({8'(MAX_RD_ENGINES), 6'b0, c1NotEmpty, c0NotEmpty});
        csrs.cpu_rd_csrs[1].data = 64'(test_cycles);
        csrs.cpu_rd_csrs[2].data = 64'(rd_engine_error);
        csrs.cpu_rd_csrs[3].data = 64'(cur_rd_engine_data.trips);
        csrs.cpu_rd_csrs[4].data = 64'(cur_rd_engine_data.last_hash);
        csrs.cpu_rd_csrs[5].data = 64'(cur_rd_engine_data.dropped_reads);
        csrs.cpu_rd_csrs[6].data = 64'(cur_rd_engine_data.spec_errors);
    end


    //
    // Consume configuration CSR writes
    //

    // Memory address to which this AFU will write the result
    t_ccip_clAddr result_addr;

    always_ff @(posedge clk)
    begin
        // Enable/disable the test with bit 0 of CSR 0
        if (csrs.cpu_wr_csrs[0].en)
        begin
            enabled <= csrs.cpu_wr_csrs[0].data[0];
        end

        // CSR 1: base address of the result buffer
        if (csrs.cpu_wr_csrs[1].en)
        begin
            result_addr <= byteAddrToClAddr(csrs.cpu_wr_csrs[1].data);
        end

        // CSR 2: How many engines are active?
        if (csrs.cpu_wr_csrs[2].en)
        begin
            last_rd_engine_idx <= t_rd_engine_idx'(csrs.cpu_wr_csrs[2].data);
        end

        // CSR 3: Set the index of the current engine to configure or read
        if (csrs.cpu_wr_csrs[3].en)
        begin
            cur_rd_engine_csr_idx <= t_rd_engine_idx'(csrs.cpu_wr_csrs[3].data);
        end

        // CSR 4: Set engine base address
        if (csrs.cpu_wr_csrs[4].en)
        begin
            rd_engine_cfg[cur_rd_engine_csr_idx].base_addr <=
                byteAddrToClAddr(csrs.cpu_wr_csrs[4].data);
        end

        // CSR 5: Expected hash
        if (csrs.cpu_wr_csrs[5].en)
        begin
            rd_engine_cfg[cur_rd_engine_csr_idx].expected_hash <= t_hash'(csrs.cpu_wr_csrs[5].data);
        end

        if (reset)
        begin
            enabled <= 1'b0;
        end
    end


    // =========================================================================
    //
    //   State machine
    //
    // =========================================================================

    typedef enum logic [2:0]
    {
        STATE_IDLE,
        STATE_START,
        STATE_RUN,
        STATE_END,
        STATE_WRITE_RESULT,
        STATE_HALT
    }
    t_state;

    t_state state;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            state <= STATE_IDLE;
        end
        else
        begin
            case (state)
              STATE_IDLE:
                begin
                    if (enabled && ! (|(rd_engine_error)))
                    begin
                        state <= STATE_START;
                        $display("AFU starting engines...");
                    end
                end

              STATE_START:
                begin
                    state <= STATE_RUN;
                end

              STATE_RUN:
                begin
                    if (! enabled)
                    begin
                        state <= STATE_END;
                        $display("AFU stopping engines...");
                    end
                    else if (|(rd_engine_error))
                    begin
                        state <= STATE_END;
                        $display("AFU stopping engines due to error...");
                    end
                end

              STATE_END:
                begin
                    if (! c0NotEmpty)
                    begin
                        state <= STATE_WRITE_RESULT;
                        $display("AFU write result to 0x%x", clAddrToByteAddr(result_addr));
                    end
                end

              STATE_WRITE_RESULT:
                begin
                    if (! fiu.c1TxAlmFull)
                    begin
                        if (|(rd_engine_error))
                        begin
                            state <= STATE_HALT;
                            $display("AFU halting due to error");
                        end
                        else
                        begin
                            state <= STATE_IDLE;
                            $display("AFU done");
                        end
                    end
                end

              STATE_END:
                begin
                end
            endcase
        end
    end

    always_ff @(posedge clk)
    begin
        if (state == STATE_RUN)
        begin
            test_cycles <= test_cycles + 1;
        end

        if (reset)
        begin
            test_cycles <= 0;
        end
    end


    // ====================================================================
    //
    //   Random multi-line size generator
    //
    // ====================================================================

    logic [11:0] ml_lfsr;
    logic [$bits(t_cci_clLen) : 0] rand_rd_lines;
    t_cci_clLen rand_rd_cl_len;
    logic do_read;

    function automatic t_cci_clLen randomMultiLineLen(logic [3:0] r);
        t_cci_clLen cl;

        case (r) inside
            [4'd0:4'd5]:  cl = eCL_LEN_1;
            [4'd6:4'd10]: cl = eCL_LEN_2;
            default:      cl = eCL_LEN_4;
        endcase

        return cl;
    endfunction

    always_ff @(posedge clk)
    begin
        if (do_read || (state == STATE_START))
        begin
            rand_rd_cl_len <= randomMultiLineLen(ml_lfsr[3:0]);
        end
    end

    cci_mpf_prim_lfsr12
      #(
        .INITIAL_VALUE(12'(513))
        )
      pwm_lfsr
       (
        .clk,
        .reset,
        .en(do_read),
        .value(ml_lfsr)
        );


    // =========================================================================
    //
    //   Read logic.
    //
    // =========================================================================

    //
    // READ REQUEST
    //

    assign do_read = (state == STATE_RUN) && ! fiu.c0TxAlmFull;

    // Index of the current read engine. Engines generate read requests round-robin.
    t_rd_engine_idx cur_rd_engine_idx;

    // The read epoch associates read responses with trips through the buffer. When
    // the end of buffer tag is reached the epoch is updated. All read responses with
    // the old epoch become unnecessary speculative reads that can be dropped.
    logic [MAX_RD_ENGINES-1 : 0] cur_rd_epoch;
    logic [MAX_RD_ENGINES-1 : 0] switch_rd_epoch;

    t_cci_clAddr cur_rd_addr[MAX_RD_ENGINES];


    //
    // Emit read requests to the FIU.
    //

    // Read header defines the request to the FIU
    t_cci_mpf_c0_ReqMemHdr rd_hdr;
    t_cci_mpf_ReqMemHdrParams rd_hdr_params;

    always_comb
    begin
        // Use virtual addresses
        rd_hdr_params = cci_mpf_defaultReqHdrParams(1);
        // Let the FIU pick the channel
        rd_hdr_params.vc_sel = eVC_VA;

        // Read a random number of lines. The random value must be legal given
        // the current address.
        case (cur_rd_addr[cur_rd_engine_idx][1:0])
            2'b?1: rd_hdr_params.cl_len = eCL_LEN_1;
            2'b00: rd_hdr_params.cl_len = rand_rd_cl_len;
            2'b10: rd_hdr_params.cl_len = t_cci_clLen'({ 1'b0, 1'(rand_rd_cl_len[0]) });
        endcase
        rand_rd_lines = {1'b0, 2'(rd_hdr_params.cl_len)} + 1;

        // Generate the header
        rd_hdr = cci_mpf_c0_genReqHdr(
                     // Alternate between the speculative read functions so both are tested
                     (cur_rd_engine_idx[0] ? eREQ_RDLSPEC_I : eREQ_RDLSPEC_S),
                     cur_rd_addr[cur_rd_engine_idx],
                     // Store engine info in mdata
                     {'0, cur_rd_engine_idx, cur_rd_epoch[cur_rd_engine_idx]},
                     rd_hdr_params);
    end

    // Send read requests to the FIU
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            fiu.c0Tx.valid <= 1'b0;
        end
        else
        begin
            fiu.c0Tx <= cci_mpf_genC0TxReadReq(rd_hdr, do_read);

            if (do_read)
            begin
                $display("  Reading from VA 0x%x for engine %0d, epoch %0d",
                         clAddrToByteAddr(cci_mpf_c0_getReqAddr(rd_hdr)),
                         cur_rd_engine_idx, cur_rd_epoch[cur_rd_engine_idx]);
            end
        end
    end

    // Round-robin through engines.
    always_ff @(posedge clk)
    begin
        if (reset || (state == STATE_START))
        begin
            cur_rd_engine_idx <= t_rd_engine_idx'(0);
        end
        else if (do_read)
        begin
            if (cur_rd_engine_idx == last_rd_engine_idx)
            begin
                cur_rd_engine_idx <= t_rd_engine_idx'(0);
            end
            else
            begin
                cur_rd_engine_idx <= cur_rd_engine_idx + t_rd_engine_idx'(1);
            end
        end
    end


    //
    // Update engine next addr and epoch
    //
    genvar e;
    generate
        for (e = 0; e < MAX_RD_ENGINES; e = e + 1)
        begin : eng_req
            always_ff @(posedge clk)
            begin
                // Did this engine just read?
                if (do_read && (cur_rd_engine_idx == t_rd_engine_idx'(e)))
                begin
                    // Update read address pointer
                    cur_rd_addr[e] <= cur_rd_addr[e] + t_cci_clAddr'(rand_rd_lines);
                end

                // New epoch (happens when the read response stream finds the buffer end flag)
                if (switch_rd_epoch[e])
                begin
                    // Start reading from the head of the buffer again and toggle the epoch
                    cur_rd_addr[e] <= rd_engine_cfg[e].base_addr;
                    cur_rd_epoch[e] <= ~cur_rd_epoch[e];
                end

                if (reset || (state == STATE_START))
                begin
                    cur_rd_addr[e] <= rd_engine_cfg[e].base_addr;
                    cur_rd_epoch[e] <= 1'b0;
                end
            end
        end
    endgenerate

    //
    // READ RESPONSE HANDLING
    //

    //
    // Extracted state from read responses
    //
    logic rd_rsp_valid;
    logic rd_rsp_present;
    logic rd_rsp_error;
    logic rd_rsp_epoch;
    t_rd_engine_idx rd_rsp_engine_idx;
    logic rd_rsp_end_of_stream;
    logic [31:0] rd_rsp_data;

    always_ff @(posedge clk)
    begin
        rd_rsp_valid <= cci_c0Rx_isReadRsp(fiu.c0Rx) && ! cci_c0Rx_isError(fiu.c0Rx);
        rd_rsp_present <= cci_c0Rx_isReadRsp(fiu.c0Rx);
        rd_rsp_error <= cci_c0Rx_isReadRsp(fiu.c0Rx) && cci_c0Rx_isError(fiu.c0Rx);

        {rd_rsp_engine_idx, rd_rsp_epoch} <= fiu.c0Rx.hdr.mdata;

        // Bit 0 data indicates end of stream when 1.
        rd_rsp_end_of_stream <= fiu.c0Rx.data[0];

        // Hash the low 32 bits of each line
        rd_rsp_data <= fiu.c0Rx.data[31:0];

        if (cci_c0Rx_isReadRsp(fiu.c0Rx) && cci_c0Rx_isError(fiu.c0Rx))
        begin
            $display("    Dropping failed speculative read, engine %0d, epoch %0d",
                     fiu.c0Rx.hdr.mdata[1 +: $bits(t_rd_engine_idx)],
                     fiu.c0Rx.hdr.mdata[0]);
        end
    end

    //
    // Consume read responses and update hashes
    //
    generate
        for (e = 0; e < MAX_RD_ENGINES; e = e + 1)
        begin : eng_rsp
            // Hash received data for each engine.
            logic [31:0] hash_value;
            logic consume_rd_rsp;

            hash32
              hash
               (
                .clk,
                .reset((state == STATE_IDLE) || switch_rd_epoch[e]),
                .en(consume_rd_rsp && ! rd_rsp_end_of_stream),
                .new_data(rd_rsp_data),
                .value(hash_value)
                );

            // Consume a read response when it is for this engine and the
            // response belongs to the active epoch.
            assign consume_rd_rsp = rd_rsp_valid &&
                                    (rd_rsp_engine_idx == t_rd_engine_idx'(e)) &&
                                    (rd_rsp_epoch == cur_rd_epoch[e]) &&
                                    ! switch_rd_epoch[e];

            always_ff @(posedge clk)
            begin
                // End of stream?
                switch_rd_epoch[e] <= consume_rd_rsp && rd_rsp_end_of_stream;

                if (! reset && (consume_rd_rsp && rd_rsp_end_of_stream))
                begin
                    $display("    End of stream, engine %0d, epoch %0d", e, cur_rd_epoch[e]);
                end
            end

            // Statistics
            always_ff @(posedge clk)
            begin
                if (rd_rsp_present && (rd_rsp_engine_idx == t_rd_engine_idx'(e)))
                begin
                    // Prefetches dropped
                    if ((rd_rsp_epoch != cur_rd_epoch[e]) || switch_rd_epoch[e])
                    begin
                        rd_engine_data[e].dropped_reads <= rd_engine_data[e].dropped_reads +
                                                           t_counter'(1);
                    end

                    // Prefetches (hopefully) with failed address translations
                    if (rd_rsp_error)
                    begin
                        rd_engine_data[e].spec_errors <= rd_engine_data[e].spec_errors +
                                                         t_counter'(1);
                    end
                end

                if (reset || (state == STATE_START))
                begin
                    rd_engine_data[e].dropped_reads <= 0;
                    rd_engine_data[e].spec_errors <= 0;
                end
            end

            // Is the hash the expected value at stream end?
            always_ff @(posedge clk)
            begin
                if (switch_rd_epoch[e])
                begin
                    rd_engine_data[e].trips <= rd_engine_data[e].trips + t_counter'(1);
                    rd_engine_data[e].last_hash <= hash_value;

                    if (hash_value != rd_engine_cfg[e].expected_hash)
                    begin
                        rd_engine_error[e] <= 1'b1;

                        if (! reset)
                        begin
                            $display("    ERROR: engine %0d expected hash 0x%x, computed 0x%x", e,
                                     rd_engine_cfg[e].expected_hash, hash_value);
                        end
                    end
                end

                if (reset || (state == STATE_START))
                begin
                    rd_engine_error[e] <= 1'b0;
                    rd_engine_data[e].trips <= 0;
                    rd_engine_data[e].last_hash <= 0;
                end
            end
        end
    endgenerate


    // =========================================================================
    //
    //   Write logic.
    //
    // =========================================================================

    // Construct a memory write request header.  For this AFU it is always
    // the same, since we write to only one address.
    t_cci_mpf_c1_ReqMemHdr wr_hdr;
    assign wr_hdr = cci_mpf_c1_genReqHdr(eREQ_WRLINE_I,
                                         result_addr,
                                         t_cci_mdata'(0),
                                         cci_mpf_defaultReqHdrParams(1));

    // Just write a 1 to signal completion
    assign fiu.c1Tx.data = t_ccip_clData'(1'b1);

    // Control logic for memory writes
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            fiu.c1Tx.valid <= 1'b0;
        end
        else
        begin
            // Request the write as long as the channel isn't full.
            fiu.c1Tx.valid <= ((state == STATE_WRITE_RESULT) &&
                               ! fiu.c1TxAlmFull);
        end

        fiu.c1Tx.hdr <= wr_hdr;
    end


    //
    // This AFU never handles MMIO reads.  MMIO is managed in the CSR module.
    //
    assign fiu.c2Tx.mmioRdValid = 1'b0;

endmodule // test_afu
