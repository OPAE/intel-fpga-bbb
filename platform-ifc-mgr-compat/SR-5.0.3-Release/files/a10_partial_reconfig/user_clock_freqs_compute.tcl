#
# Copyright (c) 2018, Intel Corporation
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# Neither the name of the Intel Corporation nor the names of its contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

#
# This flow is run after place & route and initial timing analysis.  It discovers
# the actual frequencies achieved for user clocks.  When the AFU JSON specifies
# auto user clock frequencies this script computes the clock constraints based
# on both the JSON and the timing report.
#

# Required packages
package require ::quartus::project
package require ::quartus::report
package require ::quartus::flow

# Load state into userClocks namespace
source a10_partial_reconfig/user_clock_defs.tcl

# Namespace for holding command line options
namespace eval setUserClocks {
    variable optionMap
}
if { [info exists ::setUserClocks::optionMap] } {
    array unset ::setUserClocks::optionMap
}
array set ::setUserClocks::optionMap {}


proc main {} {
    SubParseCMDArguments

    set project_name $::setUserClocks::optionMap(--project)
    set revision_name $::setUserClocks::optionMap(--revision)

    set jitter_compensation 0.01

    post_message "Project name: $project_name"
    post_message "Revision name: $revision_name"

    load_package design
    project_open $project_name -revision $revision_name
    design::load_design -snapshot final
    load_report $revision_name

    delete_computed_user_clocks_file

    # get device speedgrade
    set part_name [get_global_assignment -name DEVICE]
    post_message "Device part name is $part_name"
    set report [report_part_info $part_name]
    regexp {Speed Grade.*$} $report speedgradeline
    regexp {(\d+)} $speedgradeline speedgrade
    if { $speedgrade < 1 || $speedgrade > 8 } {
        post_message "Speedgrade is $speedgrade and not in the range of 1 to 8"
        post_message "Terminating post-flow script"
        return TCL_ERROR
    }
    post_message "Speedgrade is $speedgrade"

    set json_uclk_freqs [get_afu_json_user_clock_freqs]

    if {[uclk_freq_is_auto $json_uclk_freqs]} {
        post_message "User clocks auto mode: computing FMax"

        # Get the achieved frequencies for each clock
        set x [get_user_clks_and_fmax $::userClocks::u_clkdiv2_name $::userClocks::u_clk_name $jitter_compensation]
        # Construct a list of just frequencies (low then high)
        set uclk_freqs_actual [list [lindex $x 0] [lindex $x 2]]

        # Choose uclk frequencies, based on the original JSON constraints and
        # the achieved frequencies.
        set uclk_freqs [uclk_pick_aligned_freqs $json_uclk_freqs $uclk_freqs_actual $::userClocks::u_clk_fmax]

        # Write chosen frequencies to a file, which will be used both by the
        # next timing analysis phase and by the packager.
        save_computed_user_clocks $uclk_freqs

        # Force sta timing netlist to be rebuilt
        file delete [glob -nocomplain db/$revision_name.sta_cmp.*.tdb]
        file delete [glob -nocomplain qdb/_compiler/$revision_name/root_partition/*/final/1/*cache*]
        file delete [glob -nocomplain qdb/_compiler/$revision_name/root_partition/*/final/1/timing_netlist*]
    } else {
        post_message "User clocks not in auto mode"

        # Canonicalize clocks in case only one was specified
        if {[llength $json_uclk_freqs] == 2} {
            if {[lindex $json_uclk_freqs 0] == 0} {
                lset json_uclk_freqs 0 [expr {[lindex $json_uclk_freqs 1] / 2.0}]
            }
            if {[lindex $json_uclk_freqs 1] == 0} {
                lset json_uclk_freqs 1 [expr {[lindex $json_uclk_freqs 0] * 2}]
            }

            save_computed_user_clocks $json_uclk_freqs
        }
    }

    design::unload_design
    project_close
}



# Return values: [retval panel_id row_index]
#   panel_id and row_index are only valid if the query is successful
# retval:
#    0: success
#   -1: not found
#   -2: panel not found (could be report not loaded)
#   -3: no rows found in panel
#   -4: multiple matches found
proc find_report_panel_row { panel_name col_index string_op string_pattern } {
    if {[catch {get_report_panel_id $panel_name} panel_id] || $panel_id == -1} {
        return -2;
    }

    if {[catch {get_number_of_rows -id $panel_id} num_rows] || $num_rows == -1} {
        return -3;
    }

    # Search for row match.
    set found 0
    set row_index -1;

    for {set r 1} {$r < $num_rows} {incr r} {
        if {[catch {get_report_panel_data -id $panel_id -row $r -col $col_index} value] == 0} {


            if {[string $string_op $string_pattern $value]} {
                if {$found == 0} {

                    # If multiple rows match, return the first
                    set row_index $r

                }
                incr found
            }

        }
    }

    if {$found > 1} {return [list -4 $panel_id $row_index]}
    if {$row_index == -1} {return -1}

    return [list 0 $panel_id $row_index]
}


# get_fmax_from_report: Determines the fmax for the given clock. The fmax value returned
# will meet all timing requirements (setup, hold, recovery, removal, minimum pulse width)
# across all corners.  The return value is a 2-element list consisting of the
# fmax and clk name
proc get_fmax_from_report { clkname required jitter_compensation} {
    # Find the clock period.
    set result [find_report_panel_row "TimeQuest Timing Analyzer||Clocks" 0 match $clkname]
    set retval [lindex $result 0]

    if {$retval == -1} {
        if {$required == 1} {
           error "Error: Could not find clock: $clkname"
        } else {
           post_message -type warning "Could not find clock: $clkname.  Clock is not required assuming 10 GHz and proceeding."
           return [list 10000 $clkname]
        }
    } elseif {$retval < 0} {
        error "Error: Failed search for clock $clkname (error $retval)"
    }

    # Update clock name to full clock name ($clkname as passed in may contain wildcards).
    set panel_id [lindex $result 1]
    set row_index [lindex $result 2]
    set clkname [get_report_panel_data -id $panel_id -row $row_index -col 0]
    set clk_period [get_report_panel_data -id $panel_id -row $row_index -col 2]

    post_message "Clock $clkname"
    post_message "  Period: $clk_period"

    # Determine the most negative slack across all relevant timing metrics (setup, recovery, minimum pulse width)
    # and across all timing corners. Hold and removal metrics are not taken into account
    # because their slack values are independent on the clock period (for kernel clocks at least).
    #
    # Paths that involve both a posedge and negedge of the kernel clocks are not handled properly (slack
    # adjustment needs to be doubled).
    set timing_metrics [list "Setup" "Recovery" "Minimum Pulse Width"]
    set timing_metric_colindex [list 1 3 5 ]
    set timing_metric_required [list 1 0 0]
    set wc_slack $clk_period
    set has_slack 0
    set fmax_from_summary 5000.0

    # Find the "Fmax Summary" numbers reported in Quartus.  This may not
    # account for clock transfers but it does account for pos-to-neg edge same
    # clock transfers.  Whatever we calculate should be less than this.
    set fmax_panel_name "TimeQuest Timing Analyzer||* Model||* Model Fmax Summary"
    foreach panel_name [get_report_panel_names] {
      if {[string match $fmax_panel_name $panel_name] == 1} {
        set result [find_report_panel_row $panel_name 2 equal $clkname]
        set retval [lindex $result 0]
        if {$retval == 0} {
          set restricted_fmax_field [get_report_panel_data -id [lindex $result 1] -row [lindex $result 2] -col 1]
          regexp {([0-9\.]+)} $restricted_fmax_field restricted_fmax
          if {$restricted_fmax < $fmax_from_summary} {
            set fmax_from_summary $restricted_fmax
          }
        }
      }
    }
    post_message "  Restricted Fmax from STA: $fmax_from_summary"

    # Find the worst case slack across all corners and metrics
    foreach metric $timing_metrics metric_required $timing_metric_required col_ndx $timing_metric_colindex {
      set panel_name "TimeQuest Timing Analyzer||Multicorner Timing Analysis Summary"
      set panel_id [get_report_panel_id $panel_name]
      set result [find_report_panel_row $panel_name 0 equal " $clkname"]
      set retval [lindex $result 0]

      if {$retval == -1} {
        if {$required == 1 && $metric_required == 1} {
          error "Error: Could not find clock: $clkname"
        }
      } elseif {$retval < 0 && $retval != -4 } {
        error "Error: Failed search for clock $clkname (error $retval)"
      }

      if {$retval == 0 || $retval == -4} {
        set slack [get_report_panel_data -id [lindex $result 1] -row [lindex $result 2] -col $col_ndx ]
        post_message "    $metric slack: $slack"
        if {$slack != "N/A"} {
          if {$metric == "Setup" || $metric == "Recovery"} {
            set has_slack 1
            if {$metric == "Recovery"} {
              set normalized_slack [ expr $slack / 4.0 ]
              post_message "    normalized $metric slack: $normalized_slack"
              set slack $normalized_slack
            }
          }
        }
        # Keep track of the most negative slack.
        if {$slack < $wc_slack} {
          set wc_slack $slack
          set wc_metric $metric
        }
      }
    }

    if {$has_slack == 1} {
        # Adjust the clock period to meet the worst-case slack requirement.
        set clk_period [expr $clk_period - $wc_slack + $jitter_compensation]
        post_message "  Adjusted period: $clk_period ([format %+0.3f [expr -$wc_slack]], $wc_metric)"

        # Compute fmax from clock period. Clock period is in nanoseconds and the
        # fmax number should be in MHz.
        set fmax [expr 1000 / $clk_period]

        if {$fmax_from_summary < $fmax} {
            post_message "  Restricted Fmax from STA is lower than $fmax, using it instead."
            set fmax $fmax_from_summary
        }

        # Truncate to two decimal places. Truncate (not round to nearest) to avoid the
        # very small chance of going over the clock period when doing the computation.
        set fmax [expr floor($fmax * 100) / 100]
        post_message "  Fmax: $fmax"
    } else {
        post_message -type warning "No slack found for clock $clkname - assuming 10 GHz."
        set fmax 10000
    }

    return [list $fmax $clkname]
}

# Returns [fmax1 u_clkdiv2_name fmax2 u_clk_name]
proc get_user_clks_and_fmax {u_clkdiv2_name u_clk_name jitter_compensation} {
    set result [list]

    # Read in the achieved fmax for each clock
    set x [get_fmax_from_report $u_clkdiv2_name 1 $jitter_compensation]
    set fmax1 [lindex $x 0]
    set u_clkdiv2_name [lindex $x 1]
    set x [get_fmax_from_report $u_clk_name 0 $jitter_compensation]
    set fmax2 [lindex $x 0]
    set u_clk_name [lindex $x 1]

    return [list $fmax1 $u_clkdiv2_name $fmax2 $u_clk_name]
}


###########################################################################
#
# Argument parsing
#
###########################################################################

#************************************************
#
# Description: Parse the input arguments to the script
#              Valid arguments are:
#                               -project (project)
#                               -revision (revision)
#************************************************

proc SubParseCMDArguments {} {
    global argv
    global argc

    set singleOptionMap(--project) 0
    set singleOptionMap(--revision) 0

    set success 1
    set i 0

    while { ($i < $argc) && ($success==1) } {
        set arg [lindex $argv $i]
        incr i

        set optList [split $arg "="]
        set opt [lindex $optList 0]

        if [info exists singleOptionMap($opt)] {
            if { $singleOptionMap($opt) == 0 } {
                if { [llength $optList] < 2 } {
                    set success 0
                    puts "Error: No value is specified for option $opt"
                } elseif { [llength $optList] > 2 } {
                    set success 0
                    puts "Error: Illegal option found \"$arg\"."
                } else {
                    set optValue [lindex $optList 1]
                    if [string equal $optValue ""] {
                        set success 0
                        puts "Error: No value is specified for option $opt"
                    } else {
                        set ::setUserClocks::optionMap($opt) $optValue
                    }
                }
            } else {
                if { [llength $optList] == 1 } {
                    set ::setUserClocks::optionMap($arg) 1
                } else {
                    set success 0
                    puts "Error: Illegal option found \"$arg\"."
                }
            }
        } else {
            set success 0
            puts "Error: $arg is not a valid option."
        }
    }

    if { $success == 1 } {
        foreach opt [array names singleOptionMap] {
            if { $singleOptionMap($opt) == 0 } {
                if { ![info exists ::setUserClocks::optionMap($opt)] } {
                    puts "Error: Missing $opt option."
                    set success 0
                }
            }
        }
    }

    if {$success != 1 } {
        SubPrintHelp
        error "aborting"
    }
}


#************************************************
# Description: Print the HELP info
#************************************************
proc SubPrintHelp {} {
    puts "Compute user clock frequencies based on the AFU JSON requests and actual frequencies"
    puts "achieved following place and route."
    puts ""
    puts "Usage: compute_user_clock_freqs.tcl --project=<project> --revision=<revision>"
}


# Invoke main routine
main
