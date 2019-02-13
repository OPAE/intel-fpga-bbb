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

//
// Instantiate the VTP service and page translation engine.
//

`include "cci_mpf_if.vh"
`include "cci_mpf_csrs.vh"

`include "cci_mpf_shim_vtp.vh"
`include "cci_mpf_config.vh"


module cci_mpf_svc_vtp_wrapper
  #(
    parameter ENABLE_VTP = 0,
    parameter N_VTP_PORTS = 0,

    // Two implementations of physical to virtual page translation are
    // available in VTP. Pick mode "HARDWARE_WALKER" to walk the VTP
    // page table using AFU-generated memory reads. Pick mode
    // "SOFTWARE_SERVICE" to send translation requests to software.
    // In HARDWARE_WALKER mode it is the user code's responsibility to
    // pin all pages that may be touched by the FPGA. The SOFTWARE_SERVICE
    // mode may pin pages automatically on demand.
    parameter VTP_PT_MODE = 0,

    parameter DEBUG_MESSAGES = 0
    )
   (
    input  logic clk,
    input  logic reset,

    // Client connections to the server
    cci_mpf_shim_vtp_svc_if.server vtp_svc[N_VTP_PORTS],

    // FIM interface for host I/O
    cci_mpf_shim_vtp_pt_fim_if.pt_walk pt_fim,

    // CSRs
    cci_mpf_csrs.vtp csrs,
    cci_mpf_csrs.vtp_events vtp_events,
    cci_mpf_csrs.vtp_events_pt_walk pt_events
    );

    generate
        if (ENABLE_VTP)
        begin : v_to_p
            cci_mpf_shim_vtp_pt_walk_if pt_walk();

            cci_mpf_svc_vtp
              #(
                .N_VTP_PORTS(N_VTP_PORTS),
                .DEBUG_MESSAGES(DEBUG_MESSAGES)
                )
              vtp
               (
                .clk,
                .reset,
                .vtp_svc,
                .pt_walk,
                .csrs,
                .events(vtp_events)
                );

            if (VTP_PT_MODE == "HARDWARE_WALKER")
            begin
                cci_mpf_svc_vtp_pt_walk
                  #(
                    .DEBUG_MESSAGES(DEBUG_MESSAGES)
                    )
                  walker
                   (
                    .clk,
                    .reset,
                    .pt_walk,
                    .pt_fim,
                    .csrs,
                    .events(pt_events)
                );
            end
            else if (VTP_PT_MODE == "SOFTWARE_SERVICE")
            begin
                cci_mpf_svc_vtp_pt_sw
                  #(
                    .DEBUG_MESSAGES(DEBUG_MESSAGES)
                    )
                  walker
                   (
                    .clk,
                    .reset,
                    .pt_walk,
                    .pt_fim,
                    .csrs,
                    .events(pt_events)
                );
            end
            else
            begin
                initial
                begin
                    $fatal(2, "*** Illegal VTP_PT_MODE ***");
                end
            end
        end
        else
        begin : no_vtp
            // Tie off page table walker
            assign pt_fim.readEn = 1'b0;
            assign pt_fim.writeEn = 1'b0;
        end
    endgenerate

endmodule // cci_mpf_svc_vtp_wrapper
