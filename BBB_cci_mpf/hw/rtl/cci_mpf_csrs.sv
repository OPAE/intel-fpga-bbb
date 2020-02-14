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

//
// MPF implements a single CSR read/write module that connects to the host
// through MMIO reads and writes.  A single module is more efficient, since
// MMIO lacks flow control and requires message buffering.  The CCI MPF CSRs
// interface defines a set of signals that are managed by the CSR module.
// Private modports are defined for each class of MPF shims.
//
//   *** Directions are relative to a shim ***
//

interface cci_mpf_csrs();

    //
    // VC MAP -- Mapping eVC_VA to real physical channels.
    //
    logic [63:0] vc_map_ctrl;
    logic        vc_map_ctrl_valid;

    logic [63:0] vc_map_history;
    logic vc_map_out_event_mapping_changed;


    //
    // Latency QoS -- Throttle request rate to maintain bandwidth but reduce
    //                latency.
    //
    logic [63:0] latency_qos_ctrl;
    logic        latency_qos_ctrl_valid;

    //
    // WRO -- write/read ordering
    //

    // Configuration
    logic [63:0] wro_ctrl;
    logic wro_ctrl_valid;

    // WRO events
    t_cci_mpf_wro_pipe_events wro_pipe_events;

    //
    // PWRITE -- Partial writes
    //

    logic pwrite_out_event_pwrite;    // Partial write processed


    // CSR manager port
    modport csr
       (
        output vc_map_ctrl,
        output vc_map_ctrl_valid,
        input  vc_map_history,

        output latency_qos_ctrl,
        output latency_qos_ctrl_valid,

        output wro_ctrl,
        output wro_ctrl_valid
        );
    modport csr_events
       (
        input  vc_map_out_event_mapping_changed,

        input  wro_pipe_events,

        input  pwrite_out_event_pwrite
        );

    modport vc_map
       (
        input  vc_map_ctrl,
        input  vc_map_ctrl_valid,
        output vc_map_history
        );
    modport vc_map_events
       (
        output vc_map_out_event_mapping_changed
        );

    modport latency_qos
       (
        input  latency_qos_ctrl,
        input  latency_qos_ctrl_valid
        );

    modport wro
       (
        input  wro_ctrl,
        input  wro_ctrl_valid
        );
    modport wro_events
       (
        output wro_pipe_events
        );

    modport pwrite_events
       (
        output pwrite_out_event_pwrite
        );

endinterface // cci_mpf_csrs
