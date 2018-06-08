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

if [ -d ./build ]; then
    # There is already a build directory.  Restore all non-user
    # configurable files.
    rm -rf  "./build/output_files"
    cp -rLf "${BBS_LIB_PATH}/build/fpga_top.qdb" \
            "${BBS_LIB_PATH}/build/output_files" \
            ./build/

    # Encrypted/obscured files need lib/blue/json_files
    rm -rf lib/blue
    mkdir -p lib/blue
    ln -s ../../build/platform/json_files lib/blue/json_files
else
    cp -rLf "${BBS_LIB_PATH}/build/fpga_top.qdb" \
            "${BBS_LIB_PATH}/build/output_files" \
            ./build/

    # Encrypted/obscured files need lib/blue/json_files
    mkdir -p lib/blue
    ln -s ../../build/platform/json_files lib/blue/json_files

    # Configure the platform interface
    afu_platform_config --qsf --src "${AFU_JSON}" --default-ifc ccip_std_afu --tgt ./build/platform "${PLATFORM_CLASS}"
fi

cd build

PROJ_REV1_NAME="fpga_top"
PROJ_REV2_NAME="skx_pr_afu_synth"
PROJ_REV3_NAME="skx_pr_afu"
echo "Revision 1 : $PROJ_REV1_NAME"
echo "Revision 2 : $PROJ_REV2_NAME"
echo "Revision 3 : $PROJ_REV3_NAME"
echo "============================"

SYNTH_SUCCESS=1
FIT_SUCCESS=1
ASM_SUCCESS=1
PACKAGER_RETCODE=1

# Synthesize PR Persona
# =====================
quartus_syn --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV2_NAME
SYNTH_SUCCESS=$?

# Fit PR Persona
# ==============
if [ $SYNTH_SUCCESS -eq 0 ]
then
    quartus_cdb --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV2_NAME --export_block "root_partition" --snapshot synthesized --file "$PROJ_REV2_NAME.qdb"
    quartus_cdb --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV3_NAME --import_block "root_partition" --file "$PROJ_REV1_NAME.qdb"
    quartus_cdb --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV3_NAME --import_block persona1 --file "$PROJ_REV2_NAME.qdb"
    quartus_fit --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV3_NAME    
    FIT_SUCCESS=$?
else
    echo "AFU synthesis failed"
    exit
fi

# Run Assembler 
# =============
if [ $FIT_SUCCESS -eq 0 ]
then
    quartus_asm $PROJ_REV1_NAME -c $PROJ_REV3_NAME
    ASM_SUCCESS=$?
else
    echo "AFU place and route failed"
    exit 1
fi

# Report Timing
# =============
if [ $ASM_SUCCESS -eq 0 ]
then
    (quartus_sta --do_report_timing $PROJ_REV1_NAME -c $PROJ_REV3_NAME \
     && quartus_sh -t ./a10_partial_reconfig/compute_user_clock_freqs.tcl --project=$PROJ_REV1_NAME --revision=$PROJ_REV3_NAME \
     && quartus_sta -t ./a10_partial_reconfig/report_timing.tcl --project=$PROJ_REV1_NAME --revision=$PROJ_REV3_NAME)
    TIME_SUCCESS=$?
else
    echo "AFU bitstream generation failed"
    exit 1
fi

# Load any user clock frequency updates
UCLK_CFG=""
if [ -f output_files/user_clock_freq.txt ]; then
    UCLK_CFG="$(grep -v '^#' output_files/user_clock_freq.txt)"
fi

# Generate output files for GBS
# =============================
if [ $TIME_SUCCESS -eq 0 ]
then
    echo "Generating PR rbf file"
    PROJ_REV_NAME="skx_pr_afu"
    cd output_files/
    
    SOF_FILE=`ls $PROJ_REV_NAME.sof`
    SOF_EXISTS=$?
    echo "SOF file : $SOF_FILE"
    
    PMSF_FILE=$PROJ_REV_NAME.persona1.pmsf
    PMSF_EXISTS=$?
    echo "PMSF file: $PMSF_FILE"
    
    RBF_FILE=$PROJ_REV_NAME.rbf
    echo "RBF file : $RBF_FILE"
 
    # ---------------------------------------------------------------------------------------------------------------------------------------------------------   
    if [ $PMSF_EXISTS -eq 0 ]
    then
      echo "Generated PMSF file"
      quartus_cpf -c $PMSF_FILE $RBF_FILE
      RBF_CREATED=$?
      cd ../..
      
      # ------------------------------------------------------
      if [ $RBF_CREATED -eq 0 ]
      then
          packager create-gbs \
                   --gbs="${GBS_FILE}" \
                   --afu-json="${AFU_JSON}" \
                   --rbf=build/output_files/skx_pr_afu.rbf \
                   --set-value interface-uuid:"${INTERFACE_UUID}" ${UCLK_CFG}
        PACKAGER_RETCODE=$?
        if [ $PACKAGER_RETCODE -ne 0 ]; then
            echo "Package build failed"
            exit $PACKAGER_RETCODE
        fi
        echo "Generated GBS file"
      else
        echo "Bitstream generation failed"
        exit 1
      fi
      # ------------------------------------------------------

    else
      echo "Bitstream generation failed"
      exit 1
    fi
    # ---------------------------------------------------------------------------------------------------------------------------------------------------------   

else
    echo "Quartus build failed"
    exit 1
fi

echo ""
echo "==========================================================================="
echo " SKX-P 6.4.0 AFU compilation complete"
echo " AFU gbs file is ${GBS_FILE}"

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
