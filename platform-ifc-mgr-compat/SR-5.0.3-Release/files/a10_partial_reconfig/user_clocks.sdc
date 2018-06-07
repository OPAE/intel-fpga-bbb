#**************************************************************
# User clocks
#**************************************************************

# The Platform Interface Manager provides Tcl methods for reading
# the AFU JSON file and configuring user clock frequencies.

source a10_partial_reconfig/user_clock_defs.tcl

# Get the user clock frequencies from the AFU's JSON file, if available.
set uclk_freqs [get_afu_json_user_clock_freqs]

if {[llength $uclk_freqs]} {
    # Adjust the request to the platform, especially when the request is "auto".
    # If there is a different max. frequency for auto mode, apply it only when
    # the true achieved frequency is not yet determined.
    set u_clk_fmax $::userClocks::u_clk_fmax
    if {[info exists ::userClocks::u_clk_auto_fmax] && 0 == [llength [load_computed_user_clocks $u_clk_fmax]]} {
        # Frequencies are not known yet.
        set u_clk_fmax $::userClocks::u_clk_auto_fmax
    }

    set uclk_freqs [get_aligned_user_clock_targets $uclk_freqs $u_clk_fmax]

    # In user_clock_defs...
    constrain_user_clks $uclk_freqs
} else {
    # Default
    post_message -type info "Using default user clock frequencies."
}
