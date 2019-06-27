//
// Functions that operate on CCI-P data types.
//

`ifdef PLATFORM_IF_AVAIL
`include "platform_if.vh"
`endif

package ccip_if_funcs_pkg;

    import ccip_if_pkg::*;

    function automatic t_if_ccip_c0_Tx ccip_c0Tx_clearValids();
        t_if_ccip_c0_Tx r = 'x;
        r.valid = 1'b0;
        return r;
    endfunction

    function automatic t_if_ccip_c1_Tx ccip_c1Tx_clearValids();
        t_if_ccip_c1_Tx r = 'x;
        r.valid = 1'b0;
        return r;
    endfunction

    function automatic t_if_ccip_c2_Tx ccip_c2Tx_clearValids();
        t_if_ccip_c2_Tx r = 'x;
        r.mmioRdValid = 0;
        return r;
    endfunction

    function automatic t_if_ccip_c0_Rx ccip_c0Rx_clearValids();
        t_if_ccip_c0_Rx r = 'x;
        r.rspValid = 0;
        r.mmioRdValid = 0;
        r.mmioWrValid = 0;
        return r;
    endfunction

    function automatic t_if_ccip_c1_Rx ccip_c1Rx_clearValids();
        t_if_ccip_c1_Rx r = 'x;
        r.rspValid = 0;
        return r;
    endfunction

    function automatic logic ccip_c0Rx_isValid(
        input t_if_ccip_c0_Rx r
        );

        return r.rspValid ||
               r.mmioRdValid ||
               r.mmioWrValid;
    endfunction

    function automatic logic ccip_c1Rx_isValid(
        input t_if_ccip_c1_Rx r
        );

        return r.rspValid;
    endfunction

    function automatic logic ccip_c0Rx_isReadRsp(
        input t_if_ccip_c0_Rx r
        );

        return r.rspValid && (r.hdr.resp_type == eRSP_RDLINE);
    endfunction

    function automatic logic ccip_c0Rx_isError(
        input t_if_ccip_c0_Rx r
        );
        // Speculative translation error? This field was added
        // later, so we must test whether it is supported.
`ifdef CCIP_RDLSPEC_AVAIL
        return r.hdr.error;
`else
        return 1'b0;
`endif
    endfunction

    function automatic logic ccip_c1Rx_isWriteRsp(
        input t_if_ccip_c1_Rx r
        );

        return r.rspValid && (r.hdr.resp_type == eRSP_WRLINE);
    endfunction

    function automatic logic ccip_c1Rx_isWriteFenceRsp(
        input t_if_ccip_c1_Rx r
        );

        return r.rspValid && (r.hdr.resp_type == eRSP_WRFENCE);
    endfunction

endpackage // ccip_if_funcs_pkg
