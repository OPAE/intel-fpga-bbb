# Constrain state coming from clock cycle counters to the AFU clock domain
foreach r [list "count"] {
    set_max_skew  -from [get_keepers "*|ofs_plat_afu|*|cntclksync_${r}*"] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
    set_max_delay -from [get_keepers "*|ofs_plat_afu|*|cntclksync_${r}*"] 100.000
    set_min_delay -from [get_keepers "*|ofs_plat_afu|*|cntclksync_${r}*"] -100.000
}

# Constrain state coming from the AFU clock domain to clock cycle counters
foreach r [list "reset" "enable"] {
    set_max_skew  -to [get_keepers "*|ofs_plat_afu|*|cntclksync_${r}*"] -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.800 
    set_max_delay -to [get_keepers "*|ofs_plat_afu|*|cntclksync_${r}*"] 100.000
    set_min_delay -to [get_keepers "*|ofs_plat_afu|*|cntclksync_${r}*"] -100.000
}
