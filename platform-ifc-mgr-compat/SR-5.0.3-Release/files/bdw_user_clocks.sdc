#**************************************************************
# User clocks
#**************************************************************

# The Platform Interface Manager provides Tcl methods for reading
# the AFU JSON file and configuring user clock frequencies.

# Get the user clock frequencies from the AFU's JSON file, if available.
set uclk_freqs [get_afu_json_user_clock_freqs]

if {[llength $uclk_freqs]} {
    # Adjust the request to the platform, especially when the request is "auto".
    set uclk_freqs [get_aligned_user_clock_targets $uclk_freqs 600]

    # Quartus doesn't accept floating point frequency requests.  Multiply by 100 in order
    # to support floating point.
    set uclk_freq_low [expr {int(ceil(100 * [lindex $uclk_freqs 0]))}]
    set uclk_freq_high [expr {int(ceil(100 * [lindex $uclk_freqs 1]))}]

    # User specified frequency or auto
    create_generated_clock -name {uClk_usrDiv2} -source [get_pins {bot_wcp|top_qph|s45_reset_qph|clk_user_qph|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_refclk_select_inst|iqtxrxclk[1]}] -duty_cycle 50/1 -multiply_by $uclk_freq_low -divide_by 23674 -master_clock {bot_wcp|top_qph|s45_reset_qph|clk_user_qph|SR_11234840_hack_fpll_u0|xcvr_fpll_a10_0|hssi_pll_cascade_clk} [get_pins {bot_wcp|top_qph|s45_reset_qph|clk_user_qph|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[0]}] 
    create_generated_clock -name {uClk_usr} -source [get_pins {bot_wcp|top_qph|s45_reset_qph|clk_user_qph|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_refclk_select_inst|iqtxrxclk[1]}] -duty_cycle 50/1 -multiply_by $uclk_freq_high -divide_by 23674 -master_clock {bot_wcp|top_qph|s45_reset_qph|clk_user_qph|SR_11234840_hack_fpll_u0|xcvr_fpll_a10_0|hssi_pll_cascade_clk} [get_pins {bot_wcp|top_qph|s45_reset_qph|clk_user_qph|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[1]}] 
} else {
    # Default
    post_message "Using default user clock frequencies."
}
