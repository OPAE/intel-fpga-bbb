# Define a namespace so uclk details are recorded only once.  Other
# modules, such as compute_user_clock_freqs.tcl will use it.
namespace eval userClocks {
    variable u_clkdiv2_name {uClk_usrDiv2}
    variable u_clk_name     {uClk_usr}
    variable u_clk_fmax 600
}
