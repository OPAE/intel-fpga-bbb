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
// A generic CSR (MMIO) interface for MPF services. The interface assumes
// the service offers an array of same-size CSRs and defines methods for
// reading and writing from the CSR array. The services is responsible only
// for mapping these reads and writes to service-specific semantics.
//
// Integration with actuall MMIO reads and writes is the responsibility of
// the master, outside the MPF service. This allows the MPF service to be
// MMIO protocol independent.
//

interface mpf_services_gen_csr_if
  #(
    parameter N_ENTRIES = 16,

    // When N_DATA_BITS is 64 the slave will respond with standard CCI-P
    // feature details in entries 0 through 4. The master can override
    // these by ignorning them. The slave will respond with the incoming
    // dfh_value port in response to reads of index 0. Masters will
    // typically set dfh_value to a constant.
    //
    // When N_DATA_BITS is something other than 64 bits, the master is
    // solely responsible for handling the CCI-P device feature list.
    parameter N_DATA_BITS = 64
    );

    typedef logic [$clog2(N_ENTRIES)-1 : 0] t_csr_idx;
    typedef logic [N_DATA_BITS-1 : 0] t_data;

    // dfh_value is forwarded by the slave in response to reading entry 0.
    // Masters typically set this to a constant. Managing the device
    // feature header value in the slave pipeline is typically simpler
    // than treating it as a special case in the master. See the comment
    // about N_DATA_BITS above.
    //
    // By handling dfh_value in masters, slaves remain oblivious to
    // their position in the MMIO address space.
    logic [63:0] dfh_value;

    // The CSR index is shared by read and write. Only one of rd_req_en
    // and wr_req_en may be set at the same time.
    t_csr_idx csr_req_idx;
    logic rd_req_en;
    logic wr_req_en;
    t_data wr_data;

    // Read response must be returned in the cycle immediately following
    // rd_req_en.
    logic rd_rsp_valid;
    t_data rd_data;

    //
    // Connection from slave toward master. The master is the CSR (MMIO)
    // manager.
    //
    modport to_master
       (
        input  dfh_value,

        input  csr_req_idx,
        input  rd_req_en,
        input  wr_req_en,
        input  wr_data,

        output rd_rsp_valid,
        output rd_data
        );

    //
    // Connection from master toward slave. The slave is the MPF service.
    //
    modport to_slave
       (
        output dfh_value,

        output csr_req_idx,
        output rd_req_en,
        output wr_req_en,
        output wr_data,

        input  rd_rsp_valid,
        input  rd_data
        );

endinterface // mpf_services_gen_csr_if
