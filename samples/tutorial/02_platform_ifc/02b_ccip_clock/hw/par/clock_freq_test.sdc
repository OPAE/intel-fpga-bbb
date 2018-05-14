# Constrain state coming from clock cycle counters to the CCI-P domain
foreach r [list "count" "max_value_reached"] {
    set_max_skew  -from [get_keepers "*|ccip_std_afu|afu|counter*|cntsync_${r}*"] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
    set_max_delay -from [get_keepers "*|ccip_std_afu|afu|counter*|cntsync_${r}*"] 100.000
    set_min_delay -from [get_keepers "*|ccip_std_afu|afu|counter*|cntsync_${r}*"] -100.000
}

# Constrain state coming from the CCI-P domain to clock cycle counters
foreach r [list "max_value" "reset" "enable"] {
    set_max_skew  -to [get_keepers "*|ccip_std_afu|afu|counter*|cntsync_${r}*"] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
    set_max_delay -to [get_keepers "*|ccip_std_afu|afu|counter*|cntsync_${r}*"] 100.000
    set_min_delay -to [get_keepers "*|ccip_std_afu|afu|counter*|cntsync_${r}*"] -100.000
}
