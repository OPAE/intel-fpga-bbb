##
## Build mpf_opae_config.h, describing the OPAE version's features.
##

include(CheckCSourceCompiles)
check_c_source_compiles(
   "#include <opae/types_enum.h>
    const int dummy = FPGA_BUF_READ_ONLY;
    int main(void) {}"
    MFP_OPAE_HAS_BUF_READ_ONLY)

configure_file("${PROJECT_SOURCE_DIR}/src/cmake/config/mpf_opae_config.h.in"
               "${PROJECT_BINARY_DIR}/include/opae/mpf/mpf_opae_config.h")
install(FILES "${PROJECT_BINARY_DIR}/include/opae/mpf/mpf_opae_config.h"
        DESTINATION include/opae/mpf)

include_directories(BEFORE "${PROJECT_BINARY_DIR}/include")
