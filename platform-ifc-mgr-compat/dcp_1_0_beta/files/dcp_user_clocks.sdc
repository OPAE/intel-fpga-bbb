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

    # Quartus doesn't accept floating point frequency requests.  Multiply by 10 in order
    # to support a single decimal point.
    set uclk_freq_low [expr {int(ceil(10 * [lindex $uclk_freqs 0]))}]
    set uclk_freq_high [expr {int(ceil(10 * [lindex $uclk_freqs 1]))}]

    # User specified frequency or auto
    create_generated_clock -name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0} -source [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_refclk_select_inst|core_refclk}] -duty_cycle 50/1 -multiply_by $uclk_freq_low -divide_by 1000 -master_clock {SYS_RefClk} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[0]}]
    create_generated_clock -name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1} -source [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_refclk_select_inst|core_refclk}] -duty_cycle 50/1 -multiply_by $uclk_freq_high -divide_by 1000 -master_clock {SYS_RefClk} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[1]}]
} else {
    # Default
    post_message "Using default user clock frequencies."
}
