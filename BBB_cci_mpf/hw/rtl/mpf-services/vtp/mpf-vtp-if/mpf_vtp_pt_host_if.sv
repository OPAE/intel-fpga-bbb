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
// Interface between a page table walker and the host.
//

`include "mpf_vtp.vh"


interface mpf_vtp_pt_host_if;

    //
    // Read the page table from host memory
    //
    logic readEn;
    cci_mpf_if_pkg::t_cci_clAddr readAddr;
    cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value readReqTag;
    logic readRdy;

    logic readDataEn;
    cci_mpf_if_pkg::t_cci_clData readData;
    cci_mpf_shim_pkg::t_cci_mpf_shim_mdata_value readRspTag;

    //
    // Write messages to a page table service. Only the low 64 bits are
    // written in the line at writeAddr. The value written to higher
    // bits is undefined.
    //
    logic writeEn;
    cci_mpf_if_pkg::t_cci_clAddr writeAddr;
    logic writeRdy;
    t_mpf_vtp_pt_fim_wr_data writeData;


    // Page table walker (server) ports
    modport pt_walk
       (
        output readEn,
        output readAddr,
        output readReqTag,
        input  readRdy,

        input  readDataEn,
        input  readData,
        input  readRspTag,

        output writeEn,
        output writeAddr,
        input  writeRdy,
        output writeData
        );

    // Memory read port, used by the walker to read PT entries in host memory
    modport to_fim
       (
        input  readEn,
        input  readAddr,
        input  readReqTag,
        output readRdy,

        output readDataEn,
        output readData,
        output readRspTag,

        input  writeEn,
        input  writeAddr,
        output writeRdy,
        input  writeData
        );

endinterface // mpf_vtp_pt_host_if
