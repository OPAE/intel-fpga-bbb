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
// VTP CSR and event interface. This interface is internal to the VTP service.
// The external interface, exposed to the AFU, is mpf_services_gen_csr_if.
//

`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

interface mpf_vtp_csrs_if();

    import mpf_vtp_pkg::*;

    //
    // VTP -- virtual to physical translation
    //

    t_mpf_vtp_ctrl vtp_ctrl;

    // Output: page table mode (see cci_mpf_csrs.h)
    t_mpf_vtp_csr_out_mode vtp_out_mode;

    // Events: these wires fire to indicate an event. The CSR shim sums
    // events into counters.
    t_mpf_vtp_tlb_events vtp_tlb_events;
    t_mpf_vtp_pt_walk_events vtp_pt_walk_events;

    // CSR manager port
    modport csr
       (
        output vtp_ctrl,
        input  vtp_out_mode
        );
    modport csr_events
       (
        input  vtp_tlb_events,
        input  vtp_pt_walk_events
        );

    modport vtp
       (
        input  vtp_ctrl
        );
    modport vtp_events
       (
        output vtp_tlb_events
        );
    modport vtp_events_pt_walk
       (
        output vtp_pt_walk_events
        );

endinterface // mpf_vtp_csrs_if
