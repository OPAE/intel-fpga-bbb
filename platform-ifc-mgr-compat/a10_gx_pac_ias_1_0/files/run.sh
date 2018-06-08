#!/bin/sh
# Copyright(c) 2017, Intel Corporation
#
# Redistribution  and  use  in source  and  binary  forms,  with  or  without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of  source code  must retain the  above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name  of Intel Corporation  nor the names of its contributors
#   may be used to  endorse or promote  products derived  from this  software
#   without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED TO,  THE
# IMPLIED WARRANTIES OF  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT  SHALL THE COPYRIGHT OWNER  OR CONTRIBUTORS BE
# LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY,  OR
# CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT LIMITED  TO,  PROCUREMENT  OF
# SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  DATA, OR PROFITS;  OR BUSINESS
# INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,  WHETHER IN
# CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

SCRIPTNAME="$(basename -- "$0")"
SCRIPT_DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd -P)"

while [ $# -gt 0 ]; do
    case "$1" in
        -l|--bbs-lib)
            BBS_LIB_PATH="$2"
            shift 2
            ;;
        -p|--packager)
            PACKAGER="$2"
            shift 2
            ;;
        -o|--gbs)
            GBS_FILE="$2"
            shift 2
            ;;
        --) shift; break;;
        -*) echo "usage: $SCRIPTNAME [-l/--bbs-lib <bbs_lib_dir>] [-l/--packager <packager>] [--] [afu_metadata.json]" 1>&2
            exit 1
            ;;
        *) break;;
    esac
done

if [ $# -eq 0 ]; then
    set -- hw/rtl/*.json hw/*.json *.json
    while [ $# -gt 0 ] && [ ! -e "$1" ]; do shift; done

    if [ -z "$1" ]; then
        echo "ERROR: JSON metadata definition not found." 1>&2
        exit 1
    fi
fi
AFU_JSON="$1"

OPAE_PLATFORM_ROOT=${OPAE_PLATFORM_ROOT:-"$(dirname -- "${SCRIPT_DIR}")"}
BBS_LIB_PATH=${BBS_LIB_PATH:-"${OPAE_PLATFORM_ROOT}/hw/lib"}
PACKAGER=${PACKAGER:-packager}
GBS_FILE=${GBS_FILE:-$(basename "${AFU_JSON}" .json).gbs}

if [ ! -f "${BBS_LIB_PATH}/fme-ifc-id.txt" ]; then
    echo "ERROR: Release hw/lib directory not found!" 1>&2
    echo "  Please set OPAE_PLATFORM_ROOT, BBS_LIB_PATH or --bbs-lib" 1>&2
    exit 1
fi

INTERFACE_UUID="$(cat "${BBS_LIB_PATH}/fme-ifc-id.txt")"
PLATFORM_CLASS="$(cat "${BBS_LIB_PATH}/fme-platform-class.txt")"

if ! "${PACKAGER}" >/dev/null; then
    echo "ERROR: Packager tool '${PACKAGER}' failed to run. Please check \$PATH and installation." 1>&2
    exit 1
fi

echo "Restoring blue bitstream lib files"
echo "=================================="

# Restore the base revision files needed for PR compilation:
if [ -d ./build ]; then
    # There is already a build directory.  Restore all non-user
    # configurable files.
    rm -rf  "./build/output_files" \
            "./build/a10_partial_reconfig"
    cp -rLf "${BBS_LIB_PATH}/build/dcp.qdb" \
            "${BBS_LIB_PATH}/build/output_files" \
            "${BBS_LIB_PATH}/build/a10_partial_reconfig" \
            ./build/
else
    cp -rLf "${BBS_LIB_PATH}/build" .

    # Configure the platform interface
    afu_platform_config --qsf --src "${AFU_JSON}" --default-ifc ccip_std_afu_avalon_mm_legacy_wires --tgt ./build/platform "${PLATFORM_CLASS}"
fi
tar -xz <"${BBS_LIB_PATH}/pr_design_artifacts.tar.gz"

if [ -f ./hw/rtl/components.ipx ] && [ ! -e ./build/components.ipx ]; then
    ln -s ../hw/rtl/components.ipx build/
fi

# Run the actual build process:
(cd ./build && quartus_sh -t ./a10_partial_reconfig/flow.tcl -nobasecheck -setup_script ./a10_partial_reconfig/setup.tcl -impl afu_fit \
  && quartus_sh -t ./a10_partial_reconfig/compute_user_clock_freqs.tcl --project=dcp --revision=afu_fit \
  && quartus_sta -t ./a10_partial_reconfig/report_timing.tcl --project=dcp --revision=afu_fit)
QUARTUS_RETCODE=$?

if [ $QUARTUS_RETCODE -ne 0 ]; then
    echo "Quartus build failed"
    exit $QUARTUS_RETCODE
fi

# Load any user clock frequency updates
UCLK_CFG=""
if [ -f ./build/output_files/user_clock_freq.txt ]; then
    UCLK_CFG="$(grep -v '^#' ./build/output_files/user_clock_freq.txt)"
fi

"${PACKAGER}" create-gbs \
              --gbs="${GBS_FILE}" \
              --afu-json="${AFU_JSON}" \
              --rbf=./build/output_files/afu_fit.green_region.rbf \
              --set-value interface-uuid:"${INTERFACE_UUID}" ${UCLK_CFG}
PACKAGER_RETCODE=$?

if [ $PACKAGER_RETCODE -ne 0 ]; then
    echo "Package build failed"
    exit $PACKAGER_RETCODE
fi

echo ""
echo "==========================================================================="
echo " PR AFU compilation complete"
echo " AFU gbs file is '${GBS_FILE}'"

TIMING_SUMMARY_FILE="build/output_files/timing_report/clocks.sta.fail.summary"
if [ -s "${TIMING_SUMMARY_FILE}" ]; then
    echo
    echo "  *** Design does not meet timing. See build/output_files/timing_report. ***"
    echo
elif [ -f "${TIMING_SUMMARY_FILE}" ]; then
    echo " Design meets timing"
fi

echo "==========================================================================="
echo ""
