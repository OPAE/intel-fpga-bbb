## Generated SDC file "dcp_bbs.sdc"

## Copyright (C) 2017  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Intel and sold by Intel or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Intel Corporation"
## PROGRAM "Quartus Prime"
## VERSION "Version 17.0.0 Build 290 04/26/2017 SJ Pro Edition"

## DATE    "Thu Dec 14 23:43:22 2017"

##
## DEVICE  "10AX115N3F40E2SG"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {mem|ddr4b|ddr4b_ref_clock} -period 3.752 -waveform { 0.000 1.876 } [get_ports {DDR4_RefClk}]
create_clock -name {DDR4B_DQS_P[0]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[0]}]
create_clock -name {DDR4B_DQS_P[1]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[1]}]
create_clock -name {DDR4B_DQS_P[2]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[2]}]
create_clock -name {DDR4B_DQS_P[3]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[3]}]
create_clock -name {DDR4B_DQS_P[4]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[4]}]
create_clock -name {DDR4B_DQS_P[5]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[5]}]
create_clock -name {DDR4B_DQS_P[6]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[6]}]
create_clock -name {DDR4B_DQS_P[7]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4B_DQS_P[7]}]
create_clock -name {DDR4A_DQS_P[0]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[0]}]
create_clock -name {DDR4A_DQS_P[1]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[1]}]
create_clock -name {DDR4A_DQS_P[2]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[2]}]
create_clock -name {DDR4A_DQS_P[3]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[3]}]
create_clock -name {DDR4A_DQS_P[4]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[4]}]
create_clock -name {DDR4A_DQS_P[5]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[5]}]
create_clock -name {DDR4A_DQS_P[6]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[6]}]
create_clock -name {DDR4A_DQS_P[7]_IN} -period 0.937 -waveform { 0.000 0.469 } [get_ports {DDR4A_DQS_P[7]}]
create_clock -name {altera_ts_clk} -period 1000.000 -waveform { 0.000 500.000 } [get_nodes {*|sd1~sn_adc_ts_clk.reg}]
create_clock -name {SYS_RefClk} -period 10.000 -waveform { 0.000 5.000 } [get_ports {SYS_RefClk}]
create_clock -name {PCIE_REFCLK} -period 10.000 -waveform { 0.000 5.000 } [get_ports {PCIE_REFCLK}]
create_clock -name {ETH_RefClk} -period 3.103 -waveform { 0.000 1.600 } [get_ports {ETH_RefClk}]
create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]


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
    create_generated_clock -name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0} -source [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_refclk_select_inst|core_refclk}] -duty_cycle 50/1 -multiply_by 25 -divide_by 16 -master_clock {SYS_RefClk} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[0]}] 
    create_generated_clock -name {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1} -source [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_refclk_select_inst|core_refclk}] -duty_cycle 50/1 -multiply_by 25 -divide_by 8 -master_clock {SYS_RefClk} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[1]}] 
}


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {mem|ddr4b|ddr4b_vco_clk_0} -source [get_ports {DDR4_RefClk}] -multiply_by 4 -master_clock {mem|ddr4b|ddr4b_ref_clock} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|phy_clk_phs[0]}] 
create_generated_clock -name {mem|ddr4b|ddr4b_vco_clk_1} -source [get_ports {DDR4_RefClk}] -multiply_by 4 -master_clock {mem|ddr4b|ddr4b_ref_clock} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1VCOPH0}] 
create_generated_clock -name {mem|ddr4b|ddr4b_vco_clk_2} -source [get_ports {DDR4_RefClk}] -multiply_by 4 -master_clock {mem|ddr4b|ddr4b_ref_clock} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_DuplicateVCOPH0}] 
create_generated_clock -name {mem|ddr4a|ddr4a_vco_clk} -source [get_ports {DDR4_RefClk}] -multiply_by 4 -master_clock {mem|ddr4b|ddr4b_ref_clock} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|phy_clk_phs[0]}] 
create_generated_clock -name {mem|ddr4a|ddr4a_core_usr_clk} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|phy_clk_phs[0]}] -divide_by 4 -phase 11.250 -master_clock {mem|ddr4a|ddr4a_vco_clk} [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].tile_ctrl_inst|pa_core_clk_out[0]}] 
create_generated_clock -name {mem|ddr4a|ddr4a_core_cal_slave_clk} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|phy_clk_phs[0]}] -divide_by 7 -master_clock {mem|ddr4a|ddr4a_vco_clk} [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst|outclk[3]}] 
create_generated_clock -name {mem|ddr4b|ddr4b_phy_clk_0} -source [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|phy_clk_phs[0]}] -divide_by 2 -phase 22.500 -master_clock {mem|ddr4b|ddr4b_vco_clk_0} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|phy_clk[0]}] 
create_generated_clock -name {mem|ddr4b|ddr4b_phy_clk_1} -source [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1VCOPH0}] -divide_by 2 -phase 22.500 -master_clock {mem|ddr4b|ddr4b_vco_clk_1} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1LOADEN0}] 
create_generated_clock -name {mem|ddr4b|ddr4b_phy_clk_2} -source [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_DuplicateVCOPH0}] -divide_by 2 -phase 22.500 -master_clock {mem|ddr4b|ddr4b_vco_clk_2} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_DuplicateLOADEN0}] 
create_generated_clock -name {mem|ddr4b|ddr4b_phy_clk_l_0} -source [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|phy_clk_phs[0]}] -divide_by 4 -phase 11.250 -master_clock {mem|ddr4b|ddr4b_vco_clk_0} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|phy_clk[1]}] 
create_generated_clock -name {mem|ddr4b|ddr4b_phy_clk_l_1} -source [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1VCOPH0}] -divide_by 4 -phase 11.250 -master_clock {mem|ddr4b|ddr4b_vco_clk_1} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1LVDS_CLK0}] 
create_generated_clock -name {mem|ddr4b|ddr4b_phy_clk_l_2} -source [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_DuplicateVCOPH0}] -divide_by 4 -phase 11.250 -master_clock {mem|ddr4b|ddr4b_vco_clk_2} [get_nets {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_DuplicateLVDS_CLK0}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_0} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_0} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[1].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_1} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_0} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[2].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_2} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_0} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[0].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_3} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_2} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[0].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_4} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_2} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[1].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_5} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_2} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[2].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_6} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_2} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[3].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_7} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_1} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[3].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_8} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_1} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[2].lane_gen[0].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_9} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_1} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[2].lane_gen[1].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4b|ddr4b_wf_clk_10} -source [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4b|ddr4b_vco_clk_1} [get_registers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[2].lane_gen[2].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_vco_clk_1} -source [get_ports {DDR4_RefClk}] -multiply_by 4 -master_clock {mem|ddr4b|ddr4b_ref_clock} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1VCOPH0}] 
create_generated_clock -name {mem|ddr4a|ddr4a_vco_clk_2} -source [get_ports {DDR4_RefClk}] -multiply_by 4 -master_clock {mem|ddr4b|ddr4b_ref_clock} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_DuplicateVCOPH0}] 
create_generated_clock -name {mem|ddr4a|ddr4a_phy_clk_0} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|phy_clk_phs[0]}] -divide_by 2 -phase 22.500 -master_clock {mem|ddr4a|ddr4a_vco_clk} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|phy_clk[0]}] 
create_generated_clock -name {mem|ddr4a|ddr4a_phy_clk_1} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1VCOPH0}] -divide_by 2 -phase 22.500 -master_clock {mem|ddr4a|ddr4a_vco_clk_1} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1LOADEN0}] 
create_generated_clock -name {mem|ddr4a|ddr4a_phy_clk_2} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_DuplicateVCOPH0}] -divide_by 2 -phase 22.500 -master_clock {mem|ddr4a|ddr4a_vco_clk_2} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_DuplicateLOADEN0}] 
create_generated_clock -name {mem|ddr4a|ddr4a_phy_clk_l_0} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|phy_clk_phs[0]}] -divide_by 4 -phase 11.250 -master_clock {mem|ddr4a|ddr4a_vco_clk} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|phy_clk[1]}] 
create_generated_clock -name {mem|ddr4a|ddr4a_phy_clk_l_1} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1VCOPH0}] -divide_by 4 -phase 11.250 -master_clock {mem|ddr4a|ddr4a_vco_clk_1} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1LVDS_CLK0}] 
create_generated_clock -name {mem|ddr4a|ddr4a_phy_clk_l_2} -source [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_DuplicateVCOPH0}] -divide_by 4 -phase 11.250 -master_clock {mem|ddr4a|ddr4a_vco_clk_2} [get_nets {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_DuplicateLVDS_CLK0}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_0} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[1].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_1} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[2].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_2} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[0].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_3} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_2} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[0].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_4} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_2} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[1].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_5} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_2} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[2].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_6} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_2} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[0].lane_gen[3].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_7} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_1} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[1].lane_gen[3].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_8} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_1} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[2].lane_gen[0].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_9} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_1} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[2].lane_gen[1].lane_inst~out_phy_reg}] 
create_generated_clock -name {mem|ddr4a|ddr4a_wf_clk_10} -source [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|pll_inst|pll_inst~_Duplicate_1|vcoph[0]}] -master_clock {mem|ddr4a|ddr4a_vco_clk_1} [get_registers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[2].lane_gen[2].lane_inst~out_phy_reg}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|wys|pll_fixed_clk_central}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|wys|core_clk_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|wys~CORE_CLK_OUTCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|wys|pld_clk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pld_pcs_interface.inst_twentynm_hssi_common_pld_pcs_interface|hip_cmn_clk[0]}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk} -source [get_pins {PCIE_REFCLK~inputFITTER_INSERTEDCLKENA0|outclk}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_xcvr_avmm|avmm_atom_insts[0].twentynm_hssi_avmm_if_inst|avmmclk}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pld_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|byte_deserializer_pcs_clk_div_by_4_txclk_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_rx_pcs.inst_twentynm_hssi_8g_rx_pcs|sta_rx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[0]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[0]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[10]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[10]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|pma_hclk}] -duty_cycle 50/1 -multiply_by 1 -divide_by 2 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_common_pcs_pma_interface.inst_twentynm_hssi_common_pcs_pma_interface|sta_pma_hclk_by2}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[10]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_channel_pll.inst_twentynm_hssi_pma_channel_pll|fref}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[0]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.g_pll_g3n.lcpll_g3xn|lcpll_g3xn|a10_xcvr_atx_pll_inst|twentynm_hssi_pma_lc_refclk_select_mux_inst|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 40 -master_clock {PCIE_REFCLK} -invert [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.g_pll_g3n.lcpll_g3xn|lcpll_g3xn|a10_xcvr_atx_pll_inst|twentynm_atx_pll_inst|clk0_8g}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.fpll_g3|fpll_g3|fpll_refclk_select_inst|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 25 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.fpll_g3|fpll_g3|fpll_inst|clk0}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.fpll_g3|fpll_g3|fpll_refclk_select_inst|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.fpll_g3|fpll_g3|fpll_inst|hclk_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[0]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[1].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[2].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pld_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1_out}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[3].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[11]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[4].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[10]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[5].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[10]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[6].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_cdr_refclk_select_mux.inst_twentynm_hssi_pma_cdr_refclk_select_mux|ref_iqclk[10]}] -duty_cycle 50/1 -multiply_by 5 -master_clock {PCIE_REFCLK} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|byte_serializer_pcs_clk_div_by_4_reg}] -duty_cycle 50/1 -multiply_by 1 -divide_by 4 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_xcvr.g_phy_g3x8.phy_g3x8|phy_g3x8|g_xcvr_native_insts[7].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs|sta_tx_clk2_by4_1}] 
create_generated_clock -name {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]} -source [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.g_pll_g3n.lcpll_g3xn|lcpll_g3xn|a10_xcvr_atx_pll_inst|twentynm_hssi_pma_cgb_master_inst|clk_fpll_b}] -duty_cycle 50/1 -multiply_by 1 -divide_by 16 -master_clock {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk} [get_pins {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|altpcie_a10_hip_pipen1b|g_xcvr.altpcie_a10_hip_pllnphy|g_pll.g_pll_g3n.lcpll_g3xn|lcpll_g3xn|a10_xcvr_atx_pll_inst|twentynm_hssi_pma_cgb_master_inst|cpulse_out_bus[0]}] 
create_generated_clock -name {u0|dcp_iopll|dcp_iopll|clk2x} -source [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|refclk[0]}] -duty_cycle 50/1 -multiply_by 8 -divide_by 2 -master_clock {SYS_RefClk} [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|outclk[0]}] 
create_generated_clock -name {u0|dcp_iopll|dcp_iopll|clk1x} -source [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|refclk[0]}] -duty_cycle 50/1 -multiply_by 8 -divide_by 4 -master_clock {SYS_RefClk} [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|outclk[1]}] 
create_generated_clock -name {u0|dcp_iopll|dcp_iopll|clk100} -source [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|refclk[0]}] -duty_cycle 50/1 -multiply_by 8 -divide_by 8 -master_clock {SYS_RefClk} [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|outclk[3]}] 
create_generated_clock -name {u0|dcp_iopll|dcp_iopll|clk25} -source [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|refclk[0]}] -duty_cycle 50/1 -multiply_by 8 -divide_by 32 -master_clock {SYS_RefClk} [get_pins {u0|dcp_iopll|dcp_iopll|altera_iopll_i|twentynm_pll|iopll_inst|outclk[4]}] 
create_generated_clock -name {vl_qph_user_clk_clkpsc_clk0} -source [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[0]}] -master_clock {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_freq_u0|vl_qph_user_clk_clkpsc|combout}] -add
create_generated_clock -name {vl_qph_user_clk_clkpsc_clk1} -source [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|fpll_inst|outclk[1]}] -master_clock {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1} [get_pins {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_freq_u0|vl_qph_user_clk_clkpsc|combout}] -add


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.152  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.183  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.152  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.183  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.152  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.183  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.152  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.183  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.000  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.192  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.223  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.192  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.223  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}]  0.000  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.192  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.223  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -setup 0.192  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -hold 0.223  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -setup 0.289  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -hold 0.320  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -setup 0.152  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -hold 0.183  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.268  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.272  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -setup 0.131  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_cal_slave_clk}] -hold 0.135  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -setup 0.171  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -hold 0.175  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[7]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[7]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[7]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[7]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[6]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[6]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[6]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[6]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[5]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[5]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[5]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[5]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[3]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[3]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[3]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[3]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[2]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[2]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[2]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[2]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[4]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[4]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[4]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[4]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[1]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[1]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[1]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[1]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[0]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4B_DQS_P[0]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[0]_IN}] -rise_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4B_DQS_P[0]_IN}] -fall_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_10}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_9}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_8}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_7}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_6}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_5}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_4}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_3}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_wf_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_2}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_1}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_l_0}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_2}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_1}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_phy_clk_0}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_vco_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_vco_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -rise_to [get_clocks {mem|ddr4a|ddr4a_vco_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -fall_to [get_clocks {mem|ddr4a|ddr4a_vco_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4B_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -rise_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_ref_clock}] -fall_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_vco_clk_0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_5}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_4}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_3}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_2}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_1}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_l_0}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_2}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_1}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -rise_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}] -fall_to [get_clocks {mem|ddr4a|ddr4a_phy_clk_0}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -rise_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}] -fall_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -rise_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}] -fall_to [get_clocks {mem|ddr4a|ddr4a_vco_clk_1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[7]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[7]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[7]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[7]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[7]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[6]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[6]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[6]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[6]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[6]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[5]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[5]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[5]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[5]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[5]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[4]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[4]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[4]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[4]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[4]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[3]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[3]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[3]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[3]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[3]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[2]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[2]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[2]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[2]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[2]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[1]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[1]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[1]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[1]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[1]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[0]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {DDR4A_DQS_P[0]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[0]_IN}] -rise_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {DDR4A_DQS_P[0]_IN}] -fall_to [get_clocks {DDR4A_DQS_P[0]_IN}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_10}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_9}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_8}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_7}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -rise_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -fall_to [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -rise_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}] -fall_to [get_clocks {mem|ddr4a|ddr4a_wf_clk_6}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.080  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.080  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.080  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.080  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -rise_to [get_clocks {vl_qph_user_clk_clkpsc_clk1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -fall_to [get_clocks {vl_qph_user_clk_clkpsc_clk1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -rise_to [get_clocks {vl_qph_user_clk_clkpsc_clk1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -fall_to [get_clocks {vl_qph_user_clk_clkpsc_clk1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk1}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.070  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.210  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.210  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.070  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.210  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.210  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -rise_to [get_clocks {vl_qph_user_clk_clkpsc_clk0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -fall_to [get_clocks {vl_qph_user_clk_clkpsc_clk0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.330  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -rise_to [get_clocks {vl_qph_user_clk_clkpsc_clk0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -fall_to [get_clocks {vl_qph_user_clk_clkpsc_clk0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.080  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.080  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.050  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.080  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk25}]  0.080  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.050  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {mem|ddr4a|ddr4a_core_usr_clk}]  0.370  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk100}]  0.060  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -setup 0.161  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -hold 0.207  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -setup 0.161  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -hold 0.207  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -setup 0.161  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -hold 0.207  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -setup 0.161  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}] -hold 0.207  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.190  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pll_pcie_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_serial_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|twentynm_atx_pll_inst~O_CLK0_8G}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.010  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.010  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {PCIE_REFCLK}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.120  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|tx_bonding_clocks[0]}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_pma_clk}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|tx_clk}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_pma_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_fref}]  0.120  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_fref}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|pma_hclk_by2}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[7]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[6]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[5]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[4]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|hip_cmn_clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[3]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[2]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[1]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -setup 0.022  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -hold 0.088  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -setup 0.022  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -hold 0.088  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -setup 0.022  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -hold 0.088  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -setup 0.022  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -hold 0.088  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.200  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {PCIE_REFCLK}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {PCIE_REFCLK}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -setup 0.019  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -hold 0.067  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -setup 0.019  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -hold 0.067  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk1x}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {u0|dcp_iopll|dcp_iopll|clk2x}]  0.200  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {PCIE_REFCLK}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {PCIE_REFCLK}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -setup 0.019  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -hold 0.067  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -setup 0.019  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|pld_clk}] -hold 0.067  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|wys~CORE_CLK_OUT}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|rx_clkout}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -rise_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -fall_to [get_clocks {PCIE_REFCLK}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_pcie0_ccib_top|pcie_hip0|pcie_a10_hip_0|g_xcvr_native_insts[0]|avmmclk}]  0.040  
set_clock_uncertainty -rise_from [get_clocks {SYS_RefClk}] -rise_to [get_clocks {SYS_RefClk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {SYS_RefClk}] -fall_to [get_clocks {SYS_RefClk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {SYS_RefClk}] -rise_to [get_clocks {SYS_RefClk}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {SYS_RefClk}] -fall_to [get_clocks {SYS_RefClk}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk1}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}] -rise_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}] -fall_to [get_clocks {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|inst_user_clk|qph_user_clk_fpll_u0|xcvr_fpll_a10_0|outclk0}]  0.030  


#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_ALERT_L}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[0]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[1]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[2]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[3]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[4]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[5]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[6]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[7]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[0]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[1]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[2]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[3]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[4]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[5]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[6]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[7]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[8]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[9]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[10]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[11]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[12]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[13]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[14]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[15]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[16]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[17]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[18]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[19]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[20]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[21]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[22]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[23]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[24]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[25]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[26]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[27]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[28]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[29]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[30]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[31]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[32]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[33]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[34]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[35]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[36]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[37]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[38]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[39]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[40]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[41]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[42]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[43]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[44]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[45]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[46]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[47]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[48]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[49]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[50]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[51]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[52]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[53]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[54]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[55]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[56]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[57]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[58]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[59]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[60]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[61]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[62]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[63]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_ALERT_L}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[0]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[1]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[2]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[3]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[4]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[5]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[6]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[7]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[0]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[1]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[2]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[3]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[4]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[5]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[6]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[7]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[8]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[9]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[10]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[11]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[12]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[13]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[14]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[15]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[16]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[17]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[18]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[19]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[20]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[21]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[22]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[23]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[24]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[25]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[26]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[27]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[28]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[29]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[30]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[31]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[32]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[33]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[34]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[35]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[36]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[37]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[38]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[39]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[40]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[41]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[42]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[43]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[44]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[45]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[46]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[47]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[48]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[49]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[50]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[51]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[52]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[53]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[54]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[55]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[56]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[57]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[58]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[59]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[60]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[61]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[62]}]
set_input_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[63]}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_ACT_L}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[8]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[9]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[10]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[11]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[12]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[13]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[14]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[15]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_A[16]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_BA[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_BA[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_BG}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_CKE}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_CK_N}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_CK_P}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_CS_L}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DBI_L[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_N[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQS_P[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[8]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[9]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[10]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[11]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[12]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[13]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[14]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[15]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[16]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[17]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[18]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[19]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[20]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[21]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[22]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[23]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[24]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[25]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[26]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[27]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[28]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[29]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[30]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[31]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[32]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[33]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[34]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[35]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[36]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[37]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[38]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[39]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[40]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[41]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[42]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[43]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[44]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[45]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[46]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[47]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[48]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[49]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[50]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[51]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[52]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[53]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[54]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[55]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[56]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[57]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[58]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[59]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[60]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[61]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[62]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_DQ[63]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_ODT}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_PAR}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4A_RESET_L}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_ACT_L}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[8]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[9]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[10]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[11]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[12]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[13]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[14]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[15]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_A[16]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_BA[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_BA[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_BG}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_CKE}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_CK_N}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_CK_P}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_CS_L}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DBI_L[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_N[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQS_P[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[0]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[1]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[2]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[3]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[4]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[5]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[6]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[7]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[8]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[9]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[10]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[11]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[12]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[13]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[14]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[15]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[16]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[17]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[18]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[19]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[20]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[21]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[22]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[23]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[24]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[25]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[26]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[27]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[28]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[29]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[30]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[31]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[32]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[33]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[34]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[35]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[36]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[37]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[38]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[39]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[40]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[41]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[42]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[43]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[44]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[45]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[46]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[47]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[48]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[49]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[50]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[51]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[52]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[53]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[54]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[55]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[56]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[57]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[58]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[59]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[60]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[61]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[62]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_DQ[63]}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_ODT}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_PAR}]
set_output_delay -add_delay  -clock [get_clocks {mem|ddr4b|ddr4b_ref_clock}]  0.000 [get_ports {DDR4B_RESET_L}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {vl_qph_user_clk_clkpsc_clk0}] -group [get_clocks {vl_qph_user_clk_clkpsc_clk1}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path  -from  [get_clocks {altera_ts_clk}]  -to  [get_clocks {*dcp_iopll|clk100}]
set_false_path -hold -to [get_keepers {*sync_regs_m*din_meta[*]}]
set_false_path -to [get_registers {*alt_xcvr_resync*sync_r[0]}]
set_false_path -to [get_keepers {*altera_std_synchronizer:*|din_s1}]
set_false_path -from [get_fanins -asynch [get_keepers {*app_rstn_altpcie_reset_delay_sync_altpcie_a10_hip_hwtcl*rs_meta[*]}]] -to [get_keepers {*app_rstn_altpcie_reset_delay_sync_altpcie_a10_hip_hwtcl*rs_meta[*]}]
set_false_path -from [get_fanins -asynch [get_keepers {*por_sync_altpcie_reset_delay_sync*rs_meta[*]}]] -to [get_keepers {*por_sync_altpcie_reset_delay_sync*rs_meta[*]}]
set_false_path -from [get_fanins -asynch [get_keepers {*app_rstn_altpcie_reset_delay_sync_altpcie_a10_hip_hwtcl*rs_meta[*]}]] -to [get_keepers {*app_rstn_altpcie_reset_delay_sync_altpcie_a10_hip_hwtcl*rs_meta[*]}]
set_false_path -from [get_fanins -asynch [get_keepers {*por_sync_altpcie_reset_delay_sync*rs_meta[*]}]] -to [get_keepers {*por_sync_altpcie_reset_delay_sync*rs_meta[*]}]
set_false_path -from [get_fanins -asynch [get_keepers {*app_rstn_altpcie_reset_delay_sync_altpcie_a10_hip_hwtcl*rs_meta[*]}]] -to [get_keepers {*app_rstn_altpcie_reset_delay_sync_altpcie_a10_hip_hwtcl*rs_meta[*]}]
set_false_path -from [get_fanins -asynch [get_keepers {*por_sync_altpcie_reset_delay_sync*rs_meta[*]}]] -to [get_keepers {*por_sync_altpcie_reset_delay_sync*rs_meta[*]}]
set_false_path -hold -to [get_keepers {*pld_clk_in_use_altpcie_sc_bitsync*altpcie_sc_bitsync_meta_dff[*]}]
set_false_path -hold -to [get_keepers {*reset_status_altpcie_sc_bitsync*altpcie_sc_bitsync_meta_dff[*]}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_se9:dffpipe8|dffe9a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_re9:dffpipe5|dffe6a*}]
set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_qe9:dffpipe16|dffe17a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_pe9:dffpipe13|dffe14a*}]
set_false_path -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_8g_g3_rx_pld_rst_n*}]
set_false_path -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_8g_rxpolarity*}]
set_false_path -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_pmaif_rx_pld_rst_n*}]
set_false_path -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_bitslip*}]
set_false_path -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_rx_prbs_err_clr*}]
set_false_path -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_polinv_tx*}]
set_false_path -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_polinv_rx*}]
set_false_path -to [get_keepers {{DDR4B_A[0]} {DDR4B_A[1]} {DDR4B_A[2]} {DDR4B_A[3]} {DDR4B_A[4]} {DDR4B_A[5]} {DDR4B_A[6]} {DDR4B_A[7]} {DDR4B_A[8]} {DDR4B_A[9]} {DDR4B_A[10]} {DDR4B_A[11]} {DDR4B_A[12]} {DDR4B_A[13]} {DDR4B_A[14]} {DDR4B_A[15]} {DDR4B_A[16]} DDR4B_ACT_L {DDR4B_BA[0]} {DDR4B_BA[1]} DDR4B_BG DDR4B_CKE DDR4B_CS_L DDR4B_ODT DDR4B_PAR}]
set_false_path -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst|core_dll[2]}]  -to [get_keepers {mem|ddr4b|ddr4b*|tile_gen[*].lane_gen[*].lane_inst~lane_reg}]
set_false_path -to [get_keepers {{DDR4B_DQ[0]} {DDR4B_DQ[1]} {DDR4B_DQ[2]} {DDR4B_DQ[3]} {DDR4B_DQ[4]} {DDR4B_DQ[5]} {DDR4B_DQ[6]} {DDR4B_DQ[7]} {DDR4B_DQ[8]} {DDR4B_DQ[9]} {DDR4B_DQ[10]} {DDR4B_DQ[11]} {DDR4B_DQ[12]} {DDR4B_DQ[13]} {DDR4B_DQ[14]} {DDR4B_DQ[15]} {DDR4B_DQ[16]} {DDR4B_DQ[17]} {DDR4B_DQ[18]} {DDR4B_DQ[19]} {DDR4B_DQ[20]} {DDR4B_DQ[21]} {DDR4B_DQ[22]} {DDR4B_DQ[23]} {DDR4B_DQ[24]} {DDR4B_DQ[25]} {DDR4B_DQ[26]} {DDR4B_DQ[27]} {DDR4B_DQ[28]} {DDR4B_DQ[29]} {DDR4B_DQ[30]} {DDR4B_DQ[31]} {DDR4B_DQ[32]} {DDR4B_DQ[33]} {DDR4B_DQ[34]} {DDR4B_DQ[35]} {DDR4B_DQ[36]} {DDR4B_DQ[37]} {DDR4B_DQ[38]} {DDR4B_DQ[39]} {DDR4B_DQ[40]} {DDR4B_DQ[41]} {DDR4B_DQ[42]} {DDR4B_DQ[43]} {DDR4B_DQ[44]} {DDR4B_DQ[45]} {DDR4B_DQ[46]} {DDR4B_DQ[47]} {DDR4B_DQ[48]} {DDR4B_DQ[49]} {DDR4B_DQ[50]} {DDR4B_DQ[51]} {DDR4B_DQ[52]} {DDR4B_DQ[53]} {DDR4B_DQ[54]} {DDR4B_DQ[55]} {DDR4B_DQ[56]} {DDR4B_DQ[57]} {DDR4B_DQ[58]} {DDR4B_DQ[59]} {DDR4B_DQ[60]} {DDR4B_DQ[61]} {DDR4B_DQ[62]} {DDR4B_DQ[63]}}]
set_false_path -from [get_keepers {{DDR4B_DQ[0]} {DDR4B_DQ[1]} {DDR4B_DQ[2]} {DDR4B_DQ[3]} {DDR4B_DQ[4]} {DDR4B_DQ[5]} {DDR4B_DQ[6]} {DDR4B_DQ[7]} {DDR4B_DQ[8]} {DDR4B_DQ[9]} {DDR4B_DQ[10]} {DDR4B_DQ[11]} {DDR4B_DQ[12]} {DDR4B_DQ[13]} {DDR4B_DQ[14]} {DDR4B_DQ[15]} {DDR4B_DQ[16]} {DDR4B_DQ[17]} {DDR4B_DQ[18]} {DDR4B_DQ[19]} {DDR4B_DQ[20]} {DDR4B_DQ[21]} {DDR4B_DQ[22]} {DDR4B_DQ[23]} {DDR4B_DQ[24]} {DDR4B_DQ[25]} {DDR4B_DQ[26]} {DDR4B_DQ[27]} {DDR4B_DQ[28]} {DDR4B_DQ[29]} {DDR4B_DQ[30]} {DDR4B_DQ[31]} {DDR4B_DQ[32]} {DDR4B_DQ[33]} {DDR4B_DQ[34]} {DDR4B_DQ[35]} {DDR4B_DQ[36]} {DDR4B_DQ[37]} {DDR4B_DQ[38]} {DDR4B_DQ[39]} {DDR4B_DQ[40]} {DDR4B_DQ[41]} {DDR4B_DQ[42]} {DDR4B_DQ[43]} {DDR4B_DQ[44]} {DDR4B_DQ[45]} {DDR4B_DQ[46]} {DDR4B_DQ[47]} {DDR4B_DQ[48]} {DDR4B_DQ[49]} {DDR4B_DQ[50]} {DDR4B_DQ[51]} {DDR4B_DQ[52]} {DDR4B_DQ[53]} {DDR4B_DQ[54]} {DDR4B_DQ[55]} {DDR4B_DQ[56]} {DDR4B_DQ[57]} {DDR4B_DQ[58]} {DDR4B_DQ[59]} {DDR4B_DQ[60]} {DDR4B_DQ[61]} {DDR4B_DQ[62]} {DDR4B_DQ[63]}}] 
set_false_path -to [get_keepers {{DDR4B_DBI_L[0]} {DDR4B_DBI_L[1]} {DDR4B_DBI_L[2]} {DDR4B_DBI_L[3]} {DDR4B_DBI_L[4]} {DDR4B_DBI_L[5]} {DDR4B_DBI_L[6]} {DDR4B_DBI_L[7]}}]
set_false_path -from [get_keepers {{DDR4B_DBI_L[0]} {DDR4B_DBI_L[1]} {DDR4B_DBI_L[2]} {DDR4B_DBI_L[3]} {DDR4B_DBI_L[4]} {DDR4B_DBI_L[5]} {DDR4B_DBI_L[6]} {DDR4B_DBI_L[7]}}] 
set_false_path -to [get_keepers {{DDR4B_DQS_P[0]} {DDR4B_DQS_P[1]} {DDR4B_DQS_P[2]} {DDR4B_DQS_P[3]} {DDR4B_DQS_P[4]} {DDR4B_DQS_P[5]} {DDR4B_DQS_P[6]} {DDR4B_DQS_P[7]}}]
set_false_path -to [get_keepers {{DDR4B_DQS_N[0]} {DDR4B_DQS_N[1]} {DDR4B_DQS_N[2]} {DDR4B_DQS_N[3]} {DDR4B_DQS_N[4]} {DDR4B_DQS_N[5]} {DDR4B_DQS_N[6]} {DDR4B_DQS_N[7]}}]
set_false_path -from [get_keepers {{DDR4B_DQS_P[0]} {DDR4B_DQS_P[1]} {DDR4B_DQS_P[2]} {DDR4B_DQS_P[3]} {DDR4B_DQS_P[4]} {DDR4B_DQS_P[5]} {DDR4B_DQS_P[6]} {DDR4B_DQS_P[7]}}] 
set_false_path -from [get_keepers {{DDR4B_DQS_N[0]} {DDR4B_DQS_N[1]} {DDR4B_DQS_N[2]} {DDR4B_DQS_N[3]} {DDR4B_DQS_N[4]} {DDR4B_DQS_N[5]} {DDR4B_DQS_N[6]} {DDR4B_DQS_N[7]}}] 
set_false_path -to [get_keepers {DDR4B_CK_P}]
set_false_path -to [get_keepers {DDR4B_CK_N}]
set_false_path -to [get_keepers {DDR4B_RESET_L DDR4B_ALERT_L}]
set_false_path -from [get_keepers {DDR4B_RESET_L DDR4B_ALERT_L}] 
set_false_path -to [get_keepers {{DDR4A_A[0]} {DDR4A_A[1]} {DDR4A_A[2]} {DDR4A_A[3]} {DDR4A_A[4]} {DDR4A_A[5]} {DDR4A_A[6]} {DDR4A_A[7]} {DDR4A_A[8]} {DDR4A_A[9]} {DDR4A_A[10]} {DDR4A_A[11]} {DDR4A_A[12]} {DDR4A_A[13]} {DDR4A_A[14]} {DDR4A_A[15]} {DDR4A_A[16]} DDR4A_ACT_L {DDR4A_BA[0]} {DDR4A_BA[1]} DDR4A_BG DDR4A_CKE DDR4A_CS_L DDR4A_ODT DDR4A_PAR}]
set_false_path -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst|core_dll[2]}]  -to [get_keepers {mem|ddr4a|ddr4a*|tile_gen[*].lane_gen[*].lane_inst~lane_reg}]
set_false_path -to [get_keepers {{DDR4A_DQ[0]} {DDR4A_DQ[1]} {DDR4A_DQ[2]} {DDR4A_DQ[3]} {DDR4A_DQ[4]} {DDR4A_DQ[5]} {DDR4A_DQ[6]} {DDR4A_DQ[7]} {DDR4A_DQ[8]} {DDR4A_DQ[9]} {DDR4A_DQ[10]} {DDR4A_DQ[11]} {DDR4A_DQ[12]} {DDR4A_DQ[13]} {DDR4A_DQ[14]} {DDR4A_DQ[15]} {DDR4A_DQ[16]} {DDR4A_DQ[17]} {DDR4A_DQ[18]} {DDR4A_DQ[19]} {DDR4A_DQ[20]} {DDR4A_DQ[21]} {DDR4A_DQ[22]} {DDR4A_DQ[23]} {DDR4A_DQ[24]} {DDR4A_DQ[25]} {DDR4A_DQ[26]} {DDR4A_DQ[27]} {DDR4A_DQ[28]} {DDR4A_DQ[29]} {DDR4A_DQ[30]} {DDR4A_DQ[31]} {DDR4A_DQ[32]} {DDR4A_DQ[33]} {DDR4A_DQ[34]} {DDR4A_DQ[35]} {DDR4A_DQ[36]} {DDR4A_DQ[37]} {DDR4A_DQ[38]} {DDR4A_DQ[39]} {DDR4A_DQ[40]} {DDR4A_DQ[41]} {DDR4A_DQ[42]} {DDR4A_DQ[43]} {DDR4A_DQ[44]} {DDR4A_DQ[45]} {DDR4A_DQ[46]} {DDR4A_DQ[47]} {DDR4A_DQ[48]} {DDR4A_DQ[49]} {DDR4A_DQ[50]} {DDR4A_DQ[51]} {DDR4A_DQ[52]} {DDR4A_DQ[53]} {DDR4A_DQ[54]} {DDR4A_DQ[55]} {DDR4A_DQ[56]} {DDR4A_DQ[57]} {DDR4A_DQ[58]} {DDR4A_DQ[59]} {DDR4A_DQ[60]} {DDR4A_DQ[61]} {DDR4A_DQ[62]} {DDR4A_DQ[63]}}]
set_false_path -from [get_keepers {{DDR4A_DQ[0]} {DDR4A_DQ[1]} {DDR4A_DQ[2]} {DDR4A_DQ[3]} {DDR4A_DQ[4]} {DDR4A_DQ[5]} {DDR4A_DQ[6]} {DDR4A_DQ[7]} {DDR4A_DQ[8]} {DDR4A_DQ[9]} {DDR4A_DQ[10]} {DDR4A_DQ[11]} {DDR4A_DQ[12]} {DDR4A_DQ[13]} {DDR4A_DQ[14]} {DDR4A_DQ[15]} {DDR4A_DQ[16]} {DDR4A_DQ[17]} {DDR4A_DQ[18]} {DDR4A_DQ[19]} {DDR4A_DQ[20]} {DDR4A_DQ[21]} {DDR4A_DQ[22]} {DDR4A_DQ[23]} {DDR4A_DQ[24]} {DDR4A_DQ[25]} {DDR4A_DQ[26]} {DDR4A_DQ[27]} {DDR4A_DQ[28]} {DDR4A_DQ[29]} {DDR4A_DQ[30]} {DDR4A_DQ[31]} {DDR4A_DQ[32]} {DDR4A_DQ[33]} {DDR4A_DQ[34]} {DDR4A_DQ[35]} {DDR4A_DQ[36]} {DDR4A_DQ[37]} {DDR4A_DQ[38]} {DDR4A_DQ[39]} {DDR4A_DQ[40]} {DDR4A_DQ[41]} {DDR4A_DQ[42]} {DDR4A_DQ[43]} {DDR4A_DQ[44]} {DDR4A_DQ[45]} {DDR4A_DQ[46]} {DDR4A_DQ[47]} {DDR4A_DQ[48]} {DDR4A_DQ[49]} {DDR4A_DQ[50]} {DDR4A_DQ[51]} {DDR4A_DQ[52]} {DDR4A_DQ[53]} {DDR4A_DQ[54]} {DDR4A_DQ[55]} {DDR4A_DQ[56]} {DDR4A_DQ[57]} {DDR4A_DQ[58]} {DDR4A_DQ[59]} {DDR4A_DQ[60]} {DDR4A_DQ[61]} {DDR4A_DQ[62]} {DDR4A_DQ[63]}}] 
set_false_path -to [get_keepers {{DDR4A_DBI_L[0]} {DDR4A_DBI_L[1]} {DDR4A_DBI_L[2]} {DDR4A_DBI_L[3]} {DDR4A_DBI_L[4]} {DDR4A_DBI_L[5]} {DDR4A_DBI_L[6]} {DDR4A_DBI_L[7]}}]
set_false_path -from [get_keepers {{DDR4A_DBI_L[0]} {DDR4A_DBI_L[1]} {DDR4A_DBI_L[2]} {DDR4A_DBI_L[3]} {DDR4A_DBI_L[4]} {DDR4A_DBI_L[5]} {DDR4A_DBI_L[6]} {DDR4A_DBI_L[7]}}] 
set_false_path -to [get_keepers {{DDR4A_DQS_P[0]} {DDR4A_DQS_P[1]} {DDR4A_DQS_P[2]} {DDR4A_DQS_P[3]} {DDR4A_DQS_P[4]} {DDR4A_DQS_P[5]} {DDR4A_DQS_P[6]} {DDR4A_DQS_P[7]}}]
set_false_path -to [get_keepers {{DDR4A_DQS_N[0]} {DDR4A_DQS_N[1]} {DDR4A_DQS_N[2]} {DDR4A_DQS_N[3]} {DDR4A_DQS_N[4]} {DDR4A_DQS_N[5]} {DDR4A_DQS_N[6]} {DDR4A_DQS_N[7]}}]
set_false_path -from [get_keepers {{DDR4A_DQS_P[0]} {DDR4A_DQS_P[1]} {DDR4A_DQS_P[2]} {DDR4A_DQS_P[3]} {DDR4A_DQS_P[4]} {DDR4A_DQS_P[5]} {DDR4A_DQS_P[6]} {DDR4A_DQS_P[7]}}] 
set_false_path -from [get_keepers {{DDR4A_DQS_N[0]} {DDR4A_DQS_N[1]} {DDR4A_DQS_N[2]} {DDR4A_DQS_N[3]} {DDR4A_DQS_N[4]} {DDR4A_DQS_N[5]} {DDR4A_DQS_N[6]} {DDR4A_DQS_N[7]}}] 
set_false_path -to [get_keepers {DDR4A_CK_P}]
set_false_path -to [get_keepers {DDR4A_CK_N}]
set_false_path -to [get_keepers {DDR4A_RESET_L DDR4A_ALERT_L}]
set_false_path -from [get_keepers {DDR4A_RESET_L DDR4A_ALERT_L}] 
set_false_path -to [get_pins -nocase -compatibility_mode {*|alt_rst_sync_uq1|altera_reset_synchronizer_int_chain*|clrn}]
set_false_path -from [get_ports {PCIE_RESET_N}] 
set_false_path -from [get_registers {fpga_top|inst_fiu_top|*|PR_IP|*|freeze_reg}] 
set_false_path -from [get_registers {*|inst_fme_csr|go_bit_r2}] -to [get_clocks {*|dcp_iopll|clk25}]
set_false_path -from [get_registers {*|inst_fme_csr|go_bit_r3}] -to [get_clocks {*|dcp_iopll|clk25}]
set_false_path -from [get_registers {*|inst_fme_csr|csr_reg[14][1][*]}] -to [get_clocks {*|dcp_iopll|clk25}]
set_false_path -from [get_registers {*inst_ccip_fabric_top*ccie_t_cdc*cdn2x_SoftReset_T1*}] -to [get_cells -compatibility_mode {*inst_ccip_fabric_top*ccie_t_cdc*inst_async_CfgTx_fifo*}]
set_false_path -from [get_registers {*inst_ccip_fabric_top*ccie_t_cdc*cdn2x_SoftReset_T1*}] -to [get_cells -compatibility_mode {*inst_ccip_fabric_top*ccie_t_cdc*inst_async_C0Tx_fifo*}]
set_false_path -from [get_registers {*inst_ccip_fabric_top*ccie_t_cdc*cdn2x_SoftReset_T1*}] -to [get_cells -compatibility_mode {*inst_ccip_fabric_top*ccie_t_cdc*inst_async_C1Tx_fifo*}]
set_false_path -from [get_registers {*inst_ccip_fabric_top*ccie_t_cdc*cdn2x_SoftReset_T1*}] -to [get_cells -compatibility_mode {*inst_ccip_fabric_top*ccie_t_cdc*inst_async_C0Rx_fifo*}]
set_false_path -from [get_registers {*inst_ccip_fabric_top*ccie_t_cdc*cdn2x_SoftReset_T1*}] -to [get_cells -compatibility_mode {*inst_ccip_fabric_top*ccie_t_cdc*inst_async_C1Rx_fifo*}]
set_false_path -to [get_registers {*inst_ccip_fabric_top*ccie_t_cdc*cup_ap_tx_en_cdc[0]}]
set_false_path -to [get_registers {*inst_ccip_fabric_top*ccie_t_cdc*cup_SoftReset_n_cdc*}]
set_false_path -to [get_registers {*ccip_fabric_top|cavl0_SystemReset_n_1}]
set_false_path -to [get_registers {*ccip_fabric_top*ccie_t_cdc*error_grpA_v_cdc*}]
set_false_path -to [get_registers {*ccip_fabric_top*ccie_t_cdc*error_grpA_ack_cdc*}]
set_false_path -from [get_registers {*ccip_fabric_top*ccie_t_cdc*cup_error_grpA*}] -to [get_registers {*ccip_fabric_top*ccie_t_cdc*cdn1x_error_grpA*}]
set_false_path -to [get_registers {*ccip_fabric_top*inst_pcie0_cdc*cdnrx_initDn_cdc*}]
set_false_path -to [get_registers {*inst_ccip_fabric_top*inst_ccip_front_end*flr_completed_vf_sync1*}]
set_false_path -to [get_registers {*inst_ccip_fabric_top*inst_ccip_front_end*flr_completed_pf_sync1*}]
set_false_path -from [get_registers {*inst_ccip_fabric_top*inst_ccip_front_end*flr_rcvd_vf_flag*}] -to [get_registers {*inst_ccip_fabric_top*inst_ccip_front_end*flr_rcvd_vf_flag_sync1*}]
set_false_path -from [get_registers {*inst_pcie0_ccib_top*altpcie_sriov2_cfg_fn0_regset_inst*flr_active*}] -to [get_registers {*inst_ccip_fabric_top*inst_ccip_front_end*flr_active_pf_sync1*}]
set_false_path -to [get_registers {*inst_fme_top*c100_sync_reset_full_cdc_n*0*}]
set_false_path -from [get_registers {*|inst_user_clk|*|ffs_ckpsc_vl4_prescaler[*]}] -to [get_registers {*|inst_user_clk|*|ffs_ck100_vl_smpclk_meta}]
set_false_path -from [get_registers {*|inst_pcie*_ccib_top|avl_cci_bridge|b2c_rx_err*}] -to [get_registers {*|inst_fme_top|b2c_rx_err_*}]


#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -setup -end -to [get_keepers {*sync_regs_m*din_meta[*]}] 2
set_multicycle_path -setup -end -to [get_keepers {*pld_clk_in_use_altpcie_sc_bitsync*altpcie_sc_bitsync_meta_dff[*]}] 3
set_multicycle_path -setup -end -to [get_keepers {*reset_status_altpcie_sc_bitsync*altpcie_sc_bitsync_meta_dff[*]}] 3
set_multicycle_path -setup -end -through [get_pins -nocase -compatibility_mode {*|altpcie_a10_hip_pipen1b:altpcie_a10_hip_pipen1b|wys|tl_cfg_ctl[*]}]  2
set_multicycle_path -hold -end -through [get_pins -nocase -compatibility_mode {*|altpcie_a10_hip_pipen1b:altpcie_a10_hip_pipen1b|wys|tl_cfg_ctl[*]}]  2
set_multicycle_path -setup -start -from [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst~hmc_reg0}] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst|ctl2core_avl_cmd_ready}]  2
set_multicycle_path -hold -start -from [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst~hmc_reg0}] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst|ctl2core_avl_cmd_ready}]  1
set_multicycle_path -setup -end -from [get_clocks *] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst|reset_n}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst*}] 7
set_multicycle_path -hold -end -from [get_clocks *] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst|reset_n}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst*}] 6
set_multicycle_path -setup -end -from [get_clocks *] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*|global_reset_n}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*}] 7
set_multicycle_path -hold -end -from [get_clocks *] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*|global_reset_n}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*}] 6
set_multicycle_path -setup -end -from [get_clocks *] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_aux_inst|io_aux|core_usr_reset_n}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_aux_inst|io_aux*}] 7
set_multicycle_path -hold -end -from [get_clocks *] -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|io_aux_inst|io_aux|core_usr_reset_n}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|io_aux_inst|io_aux*}] 6
set_multicycle_path -setup -end -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*|clrn}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*}] 7
set_multicycle_path -hold -end -through [get_pins {mem|ddr4b|ddr4b|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*|clrn}]  -to [get_keepers {mem|ddr4b|ddr4b|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*}] 6
set_multicycle_path -setup -start -from [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst~hmc_reg0}] -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst|ctl2core_avl_cmd_ready}]  2
set_multicycle_path -hold -start -from [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst~hmc_reg0}] -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst|ctl2core_avl_cmd_ready}]  1
set_multicycle_path -setup -end -from [get_clocks *] -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst|reset_n}]  -to [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst*}] 7
set_multicycle_path -hold -end -from [get_clocks *] -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst|reset_n}]  -to [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].lane_gen[*].lane_inst*}] 6
set_multicycle_path -setup -end -from [get_clocks *] -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*|global_reset_n}]  -to [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*}] 7
set_multicycle_path -hold -end -from [get_clocks *] -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*|global_reset_n}]  -to [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|io_tiles_wrap_inst|io_tiles_inst|tile_gen[*].tile_ctrl_inst*}] 6
set_multicycle_path -setup -end -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*|clrn}]  -to [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*}] 7
set_multicycle_path -hold -end -through [get_pins {mem|ddr4a|ddr4a|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*|clrn}]  -to [get_keepers {mem|ddr4a|ddr4a|arch|arch_inst|non_hps.core_clks_rsts_inst|*reset_sync*}] 6
set_multicycle_path -setup -end -through [get_nets {*inst_ccip_fabric_top*inst_pcie0_cdc*}]  -to [get_cells -compatibility_mode {*inst_ccip_fabric_top*c16ui_xy2cvl_RxPort*}] 2
set_multicycle_path -hold -end -through [get_nets {*inst_ccip_fabric_top*inst_pcie0_cdc*}]  -to [get_cells -compatibility_mode {*inst_ccip_fabric_top*c16ui_xy2cvl_RxPort*}] 1
set_multicycle_path -setup -start -from [get_keepers {*inst_ccip_fabric_top*ccip_front_end*}] -to [get_registers {*inst_ccip_fabric_top*ccip_front_end*fe2cr_debug0*}] 2
set_multicycle_path -hold -start -from [get_keepers {*inst_ccip_fabric_top*ccip_front_end*}] -to [get_registers {*inst_ccip_fabric_top*ccip_front_end*fe2cr_debug0*}] 1
set_multicycle_path -setup -start -from [get_keepers {*inst_ccip_fabric_top*ccip_front_end*}] -to [get_registers {*inst_ccip_fabric_top*ccip_front_end*fsm_status*}] 2
set_multicycle_path -hold -start -from [get_keepers {*inst_ccip_fabric_top*ccip_front_end*}] -to [get_registers {*inst_ccip_fabric_top*ccip_front_end*fsm_status*}] 1
set_multicycle_path -setup -start -from [get_keepers {*inst_ccip_fabric_top*ccip_front_end*}] -to [get_registers {*inst_ccip_fabric_top*ccip_front_end*sts_reset_flush_done*}] 2
set_multicycle_path -hold -start -from [get_keepers {*inst_ccip_fabric_top*ccip_front_end*}] -to [get_registers {*inst_ccip_fabric_top*ccip_front_end*sts_reset_flush_done*}] 1
set_multicycle_path -setup -end -from [get_keepers {*inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[*].inst_csr_mux|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 2
set_multicycle_path -hold -end -from [get_keepers {*inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[*].inst_csr_mux|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 1
set_multicycle_path -setup -end -from [get_keepers {*inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[*].inst_port_csr|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 2
set_multicycle_path -hold -end -from [get_keepers {*inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[*].inst_port_csr|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 1
set_multicycle_path -setup -end -from [get_keepers {*inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[*].inst_remote_green_stp|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 2
set_multicycle_path -hold -end -from [get_keepers {*inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[*].inst_remote_green_stp|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 1
set_multicycle_path -setup -end -from [get_keepers {*inst_ccip_fabric_top|inst_fme_top|inst_csr_mux|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 2
set_multicycle_path -hold -end -from [get_keepers {*inst_ccip_fabric_top|inst_fme_top|inst_csr_mux|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 1
set_multicycle_path -setup -end -from [get_keepers {*inst_ccip_fabric_top|inst_fme_top|inst_fme_csr|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 2
set_multicycle_path -hold -end -from [get_keepers {*inst_ccip_fabric_top|inst_fme_top|inst_fme_csr|*}] -to [get_registers {*inst_ccip_fabric_top*c16ui_TxCfg*}] 1


#**************************************************************
# Set Maximum Delay
#**************************************************************

set_max_delay -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_8g_g3_tx_pld_rst_n}] 50.000
set_max_delay -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_pma_txpma_rstb}] 20.000
set_max_delay -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_pma_rxpma_rstb}] 20.000
set_max_delay -to [get_registers {*xcvr_native*altera_xcvr_native_pcie_dfe_ip*pcie_rate[*]}] 30.000
set_max_delay -to [get_registers {*xcvr_native*altera_xcvr_native_pcie_dfe_ip*pcie_rate_sync[0]}] 30.000
set_max_delay -to [get_registers {*xcvr_native*altera_xcvr_native_pcie_dfe_ip*pcie_rate_sync[1]}] 30.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_clocks {*cci*pcie_a10_hip_0*}] -to [get_keepers {*fme*csr_reg*}] 5.000
set_max_delay -from [get_keepers {fpga_top|inst_blue_ccip_interface_reg|pck_cp2af_softReset_T0_q}] -to [get_pins {fpga_top|inst_green_bs|ddr4*_reset_sync|resync_chains[0].synchronizer_nocut|*|clrn}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|ddr_reset_sync|resync_chains[0].synchronizer_nocut|*|clrn}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|wraclr|*|clrn}] 100.000
set_max_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rdaclr|*|clrn}] 100.000


#**************************************************************
# Set Minimum Delay
#**************************************************************

set_min_delay -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_8g_g3_tx_pld_rst_n}] -50.000
set_min_delay -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_pma_txpma_rstb}] -10.000
set_min_delay -to [get_pins -compatibility_mode {*twentynm_xcvr_native_inst|*inst_twentynm_pcs|*twentynm_hssi_*_pld_pcs_interface*|pld_pma_rxpma_rstb}] -10.000
set_min_delay -to [get_registers {*xcvr_native*altera_xcvr_native_pcie_dfe_ip*pcie_rate[*]}] -4.000
set_min_delay -to [get_registers {*xcvr_native*altera_xcvr_native_pcie_dfe_ip*pcie_rate_sync[0]}] -4.000
set_min_delay -to [get_registers {*xcvr_native*altera_xcvr_native_pcie_dfe_ip*pcie_rate_sync[1]}] -4.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_blue_ccip_interface_reg|pck_cp2af_softReset_T0_q}] -to [get_pins {fpga_top|inst_green_bs|ddr4*_reset_sync|resync_chains[0].synchronizer_nocut|*|clrn}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|ddr_reset_sync|resync_chains[0].synchronizer_nocut|*|clrn}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|wraclr|*|clrn}] -100.000
set_min_delay -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rdaclr|*|clrn}] -100.000


#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Net Delay
#**************************************************************

set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]
set_net_delay -max -value_multiplier 0.800 -get_value_from_clock_period dst_clock_period -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}]


#**************************************************************
# Set Max Skew
#**************************************************************

set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_CfgTx_fifo|CfgTx_fifo.inst_async_CfgTx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Tx_fifo|C1Tx_fifo.inst_async_C1Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C1Rx_fifo|C1Rx_fifo.inst_async_C1Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Tx_fifo|C0Tx_fifo.inst_async_C0Tx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_pcie0_cdc|inst_async_C0Rx_fifo|C0Rx_fifo.inst_async_C0Rx_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_cvl_top|gen_ccip_ports[0].inst_ccip_front_end|inst_mmioTx_data_fifo_cdc|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_msix_top|msix_brid|msix_dcfifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_fiu_top|inst_ccip_fabric_top|inst_fme_top|inst_PR_cntrl|inst_PR_async_FIFO|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_blue_ccip_interface_reg|pck_cp2af_softReset_T0_q}] -to [get_pins {fpga_top|inst_green_bs|ddr4*_reset_sync|resync_chains[0].synchronizer_nocut|*|clrn}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4a_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|*rdptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|ws_dgrp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|delayed_wrptr_g*}] -to [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4b_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|rs_dgwp|dffpipe*|dffe*}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|ddr_reset_sync|resync_chains[0].synchronizer_nocut|*|clrn}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|afu_res_fifo|fifo_0|dcfifo_component|auto_generated|wraclr|*|clrn}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
set_max_skew -from [get_keepers {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|SoftReset_mem}] -to [get_pins {fpga_top|inst_green_bs|inst_ccip_std_afu|nlb_lpbk|inst_local_mem|ddr4*_mem_if|afu_cmd_fifo|fifo_0|dcfifo_component|auto_generated|rdaclr|*|clrn}] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
