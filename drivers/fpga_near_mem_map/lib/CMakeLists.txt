## Copyright(c) 2020, Intel Corporation
##
## Redistribution  and  use  in source  and  binary  forms,  with  or  without
## modification, are permitted provided that the following conditions are met:
##
## * Redistributions of  source code  must retain the  above copyright notice,
##   this list of conditions and the following disclaimer.
## * Redistributions in binary form must reproduce the above copyright notice,
##   this list of conditions and the following disclaimer in the documentation
##   and/or other materials provided with the distribution.
## * Neither the name  of Intel Corporation  nor the names of its contributors
##   may be used to  endorse or promote  products derived  from this  software
##   without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
## AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED TO,  THE
## IMPLIED WARRANTIES OF  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
## ARE DISCLAIMED.  IN NO EVENT  SHALL THE COPYRIGHT OWNER  OR CONTRIBUTORS BE
## LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY,  OR
## CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT LIMITED  TO,  PROCUREMENT  OF
## SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  DATA, OR PROFITS;  OR BUSINESS
## INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,  WHETHER IN
## CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
## ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  EVEN IF ADVISED OF THE
## POSSIBILITY OF SUCH DAMAGE.

project("fpga_near_mem_map")

cmake_minimum_required(VERSION 2.8.12)

############################################################################
## Add 'versioning' library ################################################
############################################################################

set(CMAKE_PROJECT "FPGA_NEAR_MEM_MAP")
set(CMAKE_VERSION_MAJOR "0")
set(CMAKE_VERSION_MINOR "9")
set(CMAKE_VERSION_PATCH "0")
if (${CMAKE_VERSION} VERSION_GREATER "3.0")
    cmake_policy(SET CMP0046 NEW)
endif()

set(FPGA_NEAR_MEM_LIBS_ROOT ${CMAKE_CURRENT_SOURCE_DIR} CACHE PATH "Root directory of FPGA near-memory libs project" FORCE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${FPGA_NEAR_MEM_LIBS_ROOT}/cmake/modules")

##
## Allow specification of an alternate path to the FPGA library include files
## and binary.
##
set (OPAELIB_LIBS_PATH "" CACHE STRING "OPAE libs path")
set (OPAELIB_INC_PATH "" CACHE STRING "OPAE include path")

include_directories(${PROJECT_SOURCE_DIR}/include ${OPAELIB_INC_PATH})

include(GNUInstallDirs)
include(FindNuma)

# Add a macro to detect debug builds in source
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG_BUILD=1")

file(
    GLOB
    HDR
    ${PROJECT_SOURCE_DIR}/include/opae/*.h
    )

aux_source_directory(
    ${PROJECT_SOURCE_DIR}/src
    LIBFPGA_NEAR_MEM_MAP
    )

add_library(fpga_near_mem_map SHARED ${LIBFPGA_NEAR_MEM_MAP})
target_link_libraries(fpga_near_mem_map ${NUMA_LIBRARIES})

install(
    TARGETS fpga_near_mem_map
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )

install(FILES ${HDR} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/opae)
