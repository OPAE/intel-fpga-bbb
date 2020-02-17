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

# Enable checking compiler flags
include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

# Export compile commands
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

# Set the default build type to release with debug info
if (CMAKE_BUILD_TYPE STREQUAL "")
  set(CMAKE_BUILD_TYPE Release
    CACHE STRING
    "Choose the type of build, options are: None Debug Release."
    FORCE)
elseif (CMAKE_BUILD_TYPE STREQUAL "Opt")
  # Builds used to support "Opt" mode -- treat it as "Release"
  set(CMAKE_BUILD_TYPE Release)
endif ()

set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
find_package(Threads)

# Default flags to compiler when build user-space programs.
# Should come before enabling language.

if (WIN32)
  set(CMAKE_C_FLAGS_RELEASE   "-Wall -wd4710 -wd4711 -wd4820 -O2")
  set(CMAKE_C_FLAGS_DEBUG     "-Od")

  set(CMAKE_CXX_FLAGS_RELEASE "-O2")
  set(CMAKE_CXX_FLAGS_DEBUG   "-Od")
else()
  set(CMAKE_C_FLAGS_RELEASE   "-O2 -Wall -Wextra -Werror -pthread")
  set(CMAKE_C_FLAGS_DEBUG     "-g -O0 -Wall -Wextra -Werror -pthread")

  set(CMAKE_CXX_FLAGS_RELEASE "-O2 -Wall -Wextra -Werror -pthread")
  set(CMAKE_CXX_FLAGS_DEBUG   "-g -O0 -Wall -Wextra -Werror -pthread")
endif()

# Check support for C standards
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_C_STANDARD_REQUIRED OFF)
set(CMAKE_C_STANDARD 11)
if(CMAKE_VERSION VERSION_LESS "3.1")
  # Old version of CMake doesn't know how to set C standard
  check_c_compiler_flag("-std=gnu11" COMPILER_SUPPORTS_CGNU11)
  check_c_compiler_flag("-std=gnu99" COMPILER_SUPPORTS_CGNU99)
  check_c_compiler_flag("-std=c11" COMPILER_SUPPORTS_C11)

  if(COMPILER_SUPPORTS_CGNU11)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu11")
  elseif(COMPILER_SUPPORTS_CGNU99)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99")
  elseif(COMPILER_SUPPORTS_C11)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c11")
  endif()
endif(CMAKE_VERSION VERSION_LESS "3.1")


# Check support for C++ standards
set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD_REQUIRED OFF)
set(CMAKE_CXX_STANDARD 14)
if(CMAKE_VERSION VERSION_LESS "3.1")
  # Old version of CMake doesn't know how to set C++ standard
  check_cxx_compiler_flag("-std=c++14" COMPILER_SUPPORTS_CXX14)
  check_cxx_compiler_flag("-std=c++11" COMPILER_SUPPORTS_CXX11)
  check_cxx_compiler_flag("-std=c++0x" COMPILER_SUPPORTS_CXX0X)

  if(COMPILER_SUPPORTS_CXX14)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
  elseif(COMPILER_SUPPORTS_CXX11)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
  elseif(COMPILER_SUPPORTS_CXX0X)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
  endif()
endif()

# Disable some warnings that fire in system libraries
check_cxx_compiler_flag("-Wno-unused-local-typedefs"
  CXX_SUPPORTS_NO_LOCAL_TYPEDEFS)
if (CXX_SUPPORTS_NO_LOCAL_TYPEDEFS)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-local-typedefs")
endif()


############################################################################
## Defensive compilation for Release #######################################
############################################################################
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  ## C options
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wformat -Wformat-security")
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -D_FORTIFY_SOURCE=2")
  if (GCC_VERSION VERSION_GREATER 4.9 OR GCC_VERSION VERSION_EQUAL 4.9)
      set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-protector-strong")
      set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -z noexecstack -z relro -z now")
  else()
      set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fstack-protector-all")
  endif()

  ## C++ options
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wformat -Wformat-security")
  set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -D_FORTIFY_SOURCE=2")
  if (GCC_VERSION VERSION_GREATER 4.9 OR GCC_VERSION VERSION_EQUAL 4.9)
      set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-strong")
      set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -z noexecstack -z relro -z now")
  else()
      set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-all")
  endif()

  set (CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -pie")

  set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pie")
endif(CMAKE_BUILD_TYPE STREQUAL "Release")
