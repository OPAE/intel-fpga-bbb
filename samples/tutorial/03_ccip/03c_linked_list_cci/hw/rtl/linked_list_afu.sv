//
// Copyright (c) 2017, Intel Corporation
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
`include "csr_mgr.vh"
`include "afu_json_info.vh"

//
// AFU wrapper -- convert MPF interface to CCI-P structures and pass them
//                to the AFU implementation.
//
module app_afu
   (
    input  logic clk,

    // Connection toward the host.  Reset comes in here.
    cci_mpf_if.to_fiu fiu,

    // CSR connections
    app_csrs.app csrs,

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

    //
    // Convert MPF interfaces back to the standard CCI structures.
    //
    t_if_ccip_Rx mpf2af_sRx;
    t_if_ccip_Tx af2mpf_sTx;

    //
    // The base module has already registered the Rx wires heading
    // toward the AFU, so wires are acceptable.
    //
    always_comb
    begin
        //
        // Response wires
        //

        mpf2af_sRx.c0 = fiu.c0Rx;
        mpf2af_sRx.c1 = fiu.c1Rx;

        mpf2af_sRx.c0TxAlmFull = fiu.c0TxAlmFull;
        mpf2af_sRx.c1TxAlmFull = fiu.c1TxAlmFull;


        //
        // Request wires
        //

        fiu.c0Tx = cci_mpf_cvtC0TxFromBase(af2mpf_sTx.c0);
        if (cci_mpf_c0TxIsReadReq(fiu.c0Tx))
        begin
            // Treat all addresses as virtual.  If MPF's VTP isn't
            // enabled this field is ignored and addresses will remain
            // physical.
            fiu.c0Tx.hdr.ext.addrIsVirtual = 1'b1;

            // Enable eVC_VA to physical channel mapping.  This will only
            // be triggered when MPF's ENABLE_VC_MAP is set.
            fiu.c0Tx.hdr.ext.mapVAtoPhysChannel = 1'b1;

            // Enforce load/store and store/store ordering within lines.
            // This will only be triggered when ENFORCE_WR_ORDER is set.
            fiu.c0Tx.hdr.ext.checkLoadStoreOrder = 1'b1;
        end

        fiu.c1Tx = cci_mpf_cvtC1TxFromBase(af2mpf_sTx.c1);
        if (cci_mpf_c1TxIsWriteReq(fiu.c1Tx))
        begin
            // See comments on the c0Tx fields above
            fiu.c1Tx.hdr.ext.addrIsVirtual = 1'b1;
            fiu.c1Tx.hdr.ext.mapVAtoPhysChannel = 1'b1;
            fiu.c1Tx.hdr.ext.checkLoadStoreOrder = 1'b1;

            // Don't ever request an MPF partial write
            fiu.c1Tx.hdr.pwrite = t_cci_mpf_c1_PartialWriteHdr'(0);
        end

        fiu.c2Tx = af2mpf_sTx.c2;
    end


    // Connect to the AFU
    app_afu_cci
      app_cci
       (
        .clk,
        .reset,
        .cp2af_sRx(mpf2af_sRx),
        .af2cp_sTx(af2mpf_sTx),
        .csrs,
        .c0NotEmpty,
        .c1NotEmpty
        );

endmodule // app_afu


//
// Linked list implementation using pure CCI-P request/response structures
// and no MPF interfaces.  This implementation still uses virtual addresses.
// The instantiating module above (app_afu) transforms CCI-P requests to
// MPF-formatted requests and forces virtual addressing.
//
module app_afu_cci
   (
    input  logic clk,
    input  logic reset,

    // CCI-P request/response
    input  t_if_ccip_Rx cp2af_sRx,
    output t_if_ccip_Tx af2cp_sTx,

    // CSR connections
    app_csrs.app csrs,

    // MPF tracks outstanding requests.  These will be true as long as
    // reads or unacknowledged writes are still in flight.
    input  logic c0NotEmpty,
    input  logic c1NotEmpty
    );

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

    // Count the length of the chain and export it in CSR 0.
    // Count of data entries read from the linked list and export it in CSR 1.
    logic [15:0] cnt_list_length;
    logic [15:0] cnt_data_entries;

    always_comb
    begin
        // The AFU ID is a unique ID for a given program.  Here we generated
        // one with the "uuidgen" program and stored it in the AFU's JSON file.
        // ASE and synthesis setup scripts automatically invoke afu_json_mgr
        // to extract the UUID into afu_json_info.vh.
        csrs.afu_id = `AFU_ACCEL_UUID;

        // Default
        for (int i = 0; i < NUM_APP_CSRS; i = i + 1)
        begin
            csrs.cpu_rd_csrs[i].data = 64'(0);
        end

        // Exported counters.  The simple csrs interface used here has
        // no read request.  It expects the current CSR value to be
        // available every cycle.
        csrs.cpu_rd_csrs[0].data = 64'(cnt_list_length);
        csrs.cpu_rd_csrs[1].data = 64'(cnt_data_entries);
    end


    //
    // Consume configuration CSR writes
    //

    // Memory address to which this AFU will write the result
    t_ccip_clAddr result_addr;

    // CSR 1 triggers list traversal
    logic start_traversal;
    t_ccip_clAddr start_traversal_addr;

    always_ff @(posedge clk)
    begin
        if (csrs.cpu_wr_csrs[0].en)
        begin
            result_addr <= byteAddrToClAddr(csrs.cpu_wr_csrs[0].data);
        end

        start_traversal <= csrs.cpu_wr_csrs[1].en;
        start_traversal_addr <= byteAddrToClAddr(csrs.cpu_wr_csrs[1].data);
    end


    // =========================================================================
    //
    //   State machine
    //
    // =========================================================================

    typedef enum logic [1:0]
    {
        STATE_IDLE,
        STATE_RUN,
        STATE_END_OF_LIST,
        STATE_WRITE_RESULT
    }
    t_state;

    t_state state;
    // Status signals that affect state changes
    logic rd_end_of_list;
    logic rd_last_beat_received;

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
                    // Traversal begins when CSR 1 is written
                    if (start_traversal)
                    begin
                        state <= STATE_RUN;
                        $display("AFU starting traversal at 0x%x",
                                 clAddrToByteAddr(start_traversal_addr));
                    end
                end

              STATE_RUN:
                begin
                    // rd_end_of_list is set when the "next" pointer
                    // in the linked list is NULL.
                    if (rd_end_of_list)
                    begin
                        state <= STATE_END_OF_LIST;
                        $display("AFU reached end of list");
                    end
                end

              STATE_END_OF_LIST:
                begin
                    // The NULL pointer indicating the list end has been
                    // reached.  When the remainder of the record containing
                    // the NULL pointer has been processed completely it
                    // will be time to write the response.
                    if (rd_last_beat_received)
                    begin
                        state <= STATE_WRITE_RESULT;
                        $display("AFU write result to 0x%x",
                                 clAddrToByteAddr(result_addr));
                    end
                end

              STATE_WRITE_RESULT:
                begin
                    // The end of the list has been reached.  The AFU must
                    // write the computed hash to result_addr.  It is the
                    // only memory write the AFU will request.  The write
                    // will be triggered as soon as the pipeline can
                    // accept requests.
                    if (! cp2af_sRx.c1TxAlmFull)
                    begin
                        state <= STATE_IDLE;
                        $display("AFU done");
                    end
                end
            endcase
        end
    end


    // =========================================================================
    //
    //   Read logic.
    //
    // =========================================================================

    //
    // READ REQUEST
    //

    // Did a read response just arrive containing a pointer to the next entry
    // in the list?
    logic addr_next_valid;

    // When a read response contains a next pointer, this is the next address.
    t_cci_clAddr addr_next;

    always_ff @(posedge clk)
    begin
        // Read response from the first line in a 4 line group?  The next
        // pointer is in the first line of each 4-line object.  The read
        // response header's cl_num is 0 for the first line.
        addr_next_valid <= cci_c0Rx_isReadRsp(cp2af_sRx.c0) &&
                           (cp2af_sRx.c0.hdr.cl_num == t_cci_clNum'(0));

        // Next address is in the low word of the line
        addr_next <= byteAddrToClAddr(cp2af_sRx.c0.data[63:0]);

        // End of list reached if the next address is NULL.  This test
        // is a combination of the same state setting addr_next_valid
        // this cycle, with the addition of a test for a NULL next address.
        rd_end_of_list <= (byteAddrToClAddr(cp2af_sRx.c0.data[63:0]) == t_cci_clAddr'(0)) &&
                          cci_c0Rx_isReadRsp(cp2af_sRx.c0) &&
                          (cp2af_sRx.c0.hdr.cl_num == t_cci_clNum'(0));
    end


    //
    // Since back pressure may prevent an immediate read request, we must
    // record whether a read is needed and hold it until the request can
    // be sent to the FIU.
    //
    t_cci_clAddr rd_addr;
    logic rd_needed;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            rd_needed <= 1'b0;
        end
        else
        begin
            // If reads are allowed this cycle then we can safely clear
            // any previously requested reads.  This simple AFU has only
            // one read in flight at a time since it is walking a pointer
            // chain.
            if (rd_needed)
            begin
                rd_needed <= cp2af_sRx.c0TxAlmFull;
            end
            else
            begin
                // Need a read under two conditions:
                //   - Starting a new walk
                //   - A read response just arrived from a line containing
                //     a next pointer.
                rd_needed <= (start_traversal || (addr_next_valid && ! rd_end_of_list));
                rd_addr <= (start_traversal ? start_traversal_addr : addr_next);
            end
        end
    end


    //
    // Emit read requests to the FIU.
    //

    // Read header defines the request to the FIU
    t_cci_c0_ReqMemHdr rd_hdr;

    always_comb
    begin
        rd_hdr = t_cci_c0_ReqMemHdr'(0);

        // Read request type
        rd_hdr.req_type = eREQ_RDLINE_I;
        // Virtual address (MPF virtual addressing is enabled)
        rd_hdr.address = rd_addr;
        // Let the FIU pick the channel
        rd_hdr.vc_sel = eVC_VA;
        // Read 4 lines (the size of an entry in the list)
        rd_hdr.cl_len = eCL_LEN_4;
    end

    // Send read requests to the FIU
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            af2cp_sTx.c0.valid <= 1'b0;
            cnt_list_length <= 0;
        end
        else
        begin
            // Generate a read request when needed and the FIU isn't full
            af2cp_sTx.c0.valid <= (rd_needed && ! cp2af_sRx.c0TxAlmFull);
            af2cp_sTx.c0.hdr <= rd_hdr;

            if (rd_needed && ! cp2af_sRx.c0TxAlmFull)
            begin
                cnt_list_length <= cnt_list_length + 1;
                $display("  Reading from VA 0x%x", clAddrToByteAddr(rd_addr));
            end
        end
    end


    //
    // READ RESPONSE HANDLING
    //

    //
    // Registers requesting the addition of read data to the hash.
    //
    logic hash_data_en;
    logic [31:0] hash_data;
    // The cache-line number of the associated data is recorded in order
    // to figure out when reading is complete.  We will have read all
    // the data when the 4th beat of the final request is read.
    t_cci_clNum hash_cl_num;

    //
    // Receive data (read responses).
    //
    always_ff @(posedge clk)
    begin
        // A read response is data if the cl_num is non-zero.  (When cl_num
        // is zero the response is a pointer to the next record.)
        hash_data_en <= (cci_c0Rx_isReadRsp(cp2af_sRx.c0) &&
                         (cp2af_sRx.c0.hdr.cl_num != t_cci_clNum'(0)));
        hash_data <= cp2af_sRx.c0.data[31:0];
        hash_cl_num <= cp2af_sRx.c0.hdr.cl_num;

        if (cci_c0Rx_isReadRsp(cp2af_sRx.c0) &&
            (cp2af_sRx.c0.hdr.cl_num != t_cci_clNum'(0)))
        begin
            $display("    Received entry v%0d: %0d",
                     cp2af_sRx.c0.hdr.cl_num, cp2af_sRx.c0.data[63:0]);
        end
    end


    //
    // Signal completion of reading a line.  The state machine consumes this
    // to transition from END_OF_LIST to WRITE_RESULT.
    //
    assign rd_last_beat_received = hash_data_en &&
                                   (hash_cl_num == t_cci_clNum'(3));

    //
    // Compute a hash of the received data.
    //
    logic [31:0] hash_value;

    hash32
      hash
       (
        .clk,
        .reset(reset || start_traversal),
        .en(hash_data_en),
        .new_data(hash_data),
        .value(hash_value)
        );


    //
    // Count the number of fields read and added to the hash.
    //
    always_ff @(posedge clk)
    begin
        if (reset || start_traversal)
        begin
            cnt_data_entries <= 0;
        end
        else if (hash_data_en)
        begin
            cnt_data_entries <= cnt_data_entries + 1;
        end
    end


    // =========================================================================
    //
    //   Write logic.
    //
    // =========================================================================

    // Construct a memory write request header.  For this AFU it is always
    // the same, since we write to only one address.
    t_cci_c1_ReqMemHdr wr_hdr;

    always_comb
    begin
        wr_hdr = t_cci_c1_ReqMemHdr'(0);

        // Write request type
        wr_hdr.req_type = eREQ_WRLINE_I;
        // Virtual address (MPF virtual addressing is enabled)
        wr_hdr.address = result_addr;
        // Let the FIU pick the channel
        wr_hdr.vc_sel = eVC_VA;
        // Write 1 line
        wr_hdr.cl_len = eCL_LEN_1;
        // Start of packet is true (single line write)
        wr_hdr.sop = 1'b1;
    end

    // Data to write to memory.  The low word is a non-zero flag.  The
    // CPU-side software will spin, waiting for this flag.  The computed
    // hash is written in the 2nd 64 bit word.
    assign af2cp_sTx.c1.data = t_ccip_clData'({ hash_value, 64'h1 });

    // Control logic for memory writes
    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            af2cp_sTx.c1.valid <= 1'b0;
        end
        else
        begin
            // Request the write as long as the channel isn't full.
            af2cp_sTx.c1.valid <= ((state == STATE_WRITE_RESULT) &&
                                   ! cp2af_sRx.c1TxAlmFull);
        end

        af2cp_sTx.c1.hdr <= wr_hdr;
    end


    //
    // This AFU never handles MMIO reads.  MMIO is managed in the CSR module.
    //
    assign af2cp_sTx.c2.mmioRdValid = 1'b0;

endmodule // app_afu_cci

