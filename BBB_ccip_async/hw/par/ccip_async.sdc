## Reset paths --
##   The FROM object will need to change if you drive the FIFO from
##   a different reset.
##
set_false_path -from [get_keepers inst*_ccip_interface_reg|pck_cp2af_softReset_T*] -to [get_keepers *ccip_async_shim*softreset*]
set_false_path -from [get_keepers inst*_ccip_interface_reg|pck_cp2af_softReset_T*] -to [get_keepers *ccip_async_shim*dcfifo_component*dffe*]



###########################################################################
##
##   Taken from the SDC file generated for a Qsys DCFIFO
##
###########################################################################


# (C) 2001-2016 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera MegaCore Function License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


# constraints for DCFIFO sdc
#
# top-level sdc
# convention for module sdc apply_sdc_<module_name>
#
proc apply_sdc_dcfifo {hier_path} {
# gray_rdptr
apply_sdc_dcfifo_rdptr $hier_path
# gray_wrptr
apply_sdc_dcfifo_wrptr $hier_path
}
#
# common constraint setting proc
#
proc apply_sdc_dcfifo_for_ptrs {from_node_list to_node_list} {
# control skew for bits
set_max_skew -from $from_node_list -to $to_node_list -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8
# path delay (exception for net delay)
set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
#relax setup and hold calculation
set_max_delay -from $from_node_list -to $to_node_list 100
set_min_delay -from $from_node_list -to $to_node_list -100
}
#
# mstable propgation delay
#
proc apply_sdc_dcfifo_mstable_delay {from_node_list to_node_list} {
# mstable delay
set_net_delay -from $from_node_list -to $to_node_list -max -get_value_from_clock_period dst_clock_period -value_multiplier 0.8
}
#
# rdptr constraints
#
proc apply_sdc_dcfifo_rdptr {hier_path} {
# get from and to list
set from_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|*rdptr_g*]
set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
# mstable
set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*]
apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}
#
# wrptr constraints
#
proc apply_sdc_dcfifo_wrptr {hier_path} {
# control skew for bits
set from_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|delayed_wrptr_g*]
set to_node_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
apply_sdc_dcfifo_for_ptrs $from_node_list $to_node_list
# mstable
set from_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
set to_node_mstable_list [get_keepers $hier_path|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*]
apply_sdc_dcfifo_mstable_delay $from_node_mstable_list $to_node_mstable_list
}

proc apply_sdc_pre_dcfifo {entity_name} {

# set inst_list [get_entity_instances $entity_name]
load_package design 
set inst_list [design::get_instances -entity $entity_name]

foreach each_inst $inst_list {

        apply_sdc_dcfifo ${each_inst} 

    }
}


###########################################################################
##
##   Apply the constraints
##
###########################################################################

apply_sdc_pre_dcfifo "ccip_afifo_channel"
