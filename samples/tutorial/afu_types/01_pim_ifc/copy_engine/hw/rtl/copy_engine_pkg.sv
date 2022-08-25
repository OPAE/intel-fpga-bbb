//
// Copyright (c) 2022, Intel Corporation
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

`include "ofs_plat_if.vh"

package copy_engine_pkg;

    localparam CMD_NUM_LINES_BITS = 8;
    localparam CMD_ADDR_BITS = 64;
    localparam CMD_INTR_VEC_BITS = `OFS_PLAT_PARAM_HOST_CHAN_NUM_INTR_VECS;

    typedef logic [CMD_NUM_LINES_BITS-1 : 0] t_cmd_num_lines;
    typedef logic [CMD_ADDR_BITS-1 : 0] t_cmd_addr;
    typedef logic [CMD_INTR_VEC_BITS-1 : 0] t_cmd_intr_id;

    // Read commands (CSR to read engine)
    typedef struct {
        logic enable;
        t_cmd_num_lines num_lines;
        t_cmd_addr addr;
    } t_rd_cmd;

    // Read state (read engine to CSR)
    typedef struct {
        logic [63:0] num_lines_read;
    } t_rd_state;

    // Write commands (CSR to write engine)
    typedef struct {
        logic enable;
        t_cmd_num_lines num_lines;
        t_cmd_addr addr;
        t_cmd_intr_id intr_id;
        logic intr_ack;

        // When use_mem_status is set, the write engine writes completion
        // updates to the mem_status_addr. Completions are indicated by
        // writing the total number of commands processed. When use_mem_status
        // is clear, the write engine indicates generates interrupts.
        logic use_mem_status;
        t_cmd_addr mem_status_addr;
    } t_wr_cmd;

    // Write state (write engine to CSR)
    typedef struct {
        logic [63:0] num_lines_write;
    } t_wr_state;

endpackage // copy_engine_pkg
