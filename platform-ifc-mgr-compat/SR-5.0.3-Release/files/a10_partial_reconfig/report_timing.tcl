namespace eval timingReport {
	variable optionMap
}

if { [info exists ::timingReport::optionMap] } {
	array unset ::timingReport::optionMap
}
array set ::timingReport::optionMap {}

#************************************************
#
# Description: Parse the input arguments to the script
#              Valid arguments are:
#					-project (project)
#					-revision (revision)
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
                                          set ::timingReport::optionMap($opt) $optValue
                                  }
                          }
                  } else {
                          if { [llength $optList] == 1 } {
                                  set ::timingReport::optionMap($arg) 1
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
                          if { ![info exists ::timingReport::optionMap($opt)] } {
                                  puts "Error: Missing $opt option."
                                  set success 0
                          }
                  }
          }
  }

  if {$success != 1 } {
          SubPrintHelp
          return -1
  } 
}

#************************************************
# Description: Print the HELP info
#************************************************
proc SubPrintHelp {} {
   puts "This script generates detailed timing report for the given project in output_files/timing_report"
   puts "Usage: report_timing.tcl <option>.."
   puts "Supported options:"
   puts "    --project <project>         "
   puts "    --revision <revision>       "
}


# Write clock summary to open file handle $ofile
proc emitClockSummaryInfo {ofile corner domain type} {
  set name [lindex $domain 0]
  set slack [lindex $domain 1]
  set keeper_tns [lindex $domain 2]

  puts $ofile "Type  : ${corner} ${type} '${name}'"
  puts $ofile "Slack : ${slack}"
  puts $ofile "TNS   : ${keeper_tns}"
  puts $ofile ""
}


proc subReportTiming {} {
  set project $::timingReport::optionMap(--project)
  set revision $::timingReport::optionMap(--revision)

  if [file exists output_files/timing_report] {
    file delete -force -- output_files/timing_report
  }
  project_open -revision $revision $project
  create_timing_netlist 
  read_sdc

  report_clocks -file "output_files/timing_report/clocks.rpt"

  set pass_file [open "output_files/timing_report/clocks.sta.pass.summary" w]
  set fail_file [open "output_files/timing_report/clocks.sta.fail.summary" w]

  set operating_conditions [get_available_operating_conditions]
  foreach corner $operating_conditions {
    set_operating_conditions $corner
    update_timing_netlist

    set report_type_list {setup hold recovery removal mpw}
    foreach type $report_type_list {
      set report_name "output_files/timing_report/${revision}_${corner}_${type}.rpt"
      set domain_list [get_clock_domain_info -${type}]
      foreach domain $domain_list {
        set name [lindex $domain 0]
        set slack [lindex $domain 1]

        if {$slack >= 0} {
          emitClockSummaryInfo $pass_file $corner $domain $type
        } else {
          emitClockSummaryInfo $fail_file $corner $domain $type

          if {$type != "mpw"} {
            report_timing -to_clock $name -${type} -show_routing -npaths 20 -file $report_name -append
          } else {
            report_min_pulse_width -nworst 20 -file $report_name -append
          }
        }
      }
    }
  }

  close $pass_file
  close $fail_file

  delete_timing_netlist
  project_close
}

#************************************************
# Description: Entry point of TCL post processing
#************************************************
proc main {} {
  if { [SubParseCMDArguments] == -1 } {
    return -1
  }

  subReportTiming

}

main
