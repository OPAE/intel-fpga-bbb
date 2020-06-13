## Copyright(c) 2017, Intel Corporation
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

include(GNUInstallDirs)

# Configuration based on the OPAE version, etc.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/src/cmake/config")
include(mpf_opae_config)

# Add a macro to detect debug builds in source
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DDEBUG_BUILD=1")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG_BUILD=1")

file(
    GLOB
    HDR
    ${PROJECT_SOURCE_DIR}/include/opae/mpf/*.h
    )
file(
    GLOB
    HDR_CXX
    ${PROJECT_SOURCE_DIR}/include/opae/mpf/cxx/*.h
    )

aux_source_directory(
    ${PROJECT_SOURCE_DIR}/src/libmpf
    LIBMPF
    )
aux_source_directory(
    ${PROJECT_SOURCE_DIR}/src/libmpf++
    LIBMPF_CXX
    )

add_library(MPF SHARED ${LIBMPF})
add_library(MPF-cxx SHARED ${LIBMPF_CXX})

install(
    TARGETS MPF MPF-cxx
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )

install(FILES ${HDR} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/opae/mpf)
install(FILES ${HDR_CXX} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/opae/mpf/cxx)

##
## Add pthreads to the generated library.  VTP uses a mutex to guarantee
## that only one allocation happens at a time.
##
find_package(Threads REQUIRED)
if(CMAKE_THREAD_LIBS_INIT)
    target_link_libraries(MPF "${CMAKE_THREAD_LIBS_INIT}")
    target_link_libraries(MPF-cxx "${CMAKE_THREAD_LIBS_INIT}")
endif()

if(OPAELIB_LIBS_PATH)
    target_link_libraries(MPF OpaeLib)
    target_link_libraries(MPF-cxx OpaeLib)
endif()

if(BUILD_FPGA_NEAR_MEM_MAP)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DFPGA_NEAR_MEM_MAP=1")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DFPGA_NEAR_MEM_MAP=1")

    target_link_libraries(MPF fpga_near_mem_map)
endif()
