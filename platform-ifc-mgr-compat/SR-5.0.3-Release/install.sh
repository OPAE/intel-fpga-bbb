#!/bin/bash
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

##
## Update the SR-5.0.3-Release tree for use with the platform database.
## The script constructs a new environment at the top of the release,
## leaving the original release intact.  The new top level directories
## (bin and hw) mirror the structure of the DCP 1.0 beta release.
##
## The script adds a new "afu_quartus_setup" script that is the analog
## of the OPAE "afu_sim_setup" script.
##

SCRIPTNAME="$(basename -- "$0")"
SCRIPT_DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd -P)"

function usage {
    echo "Usage: ${SCRIPTNAME} <SR-5.0.3-Release dir>"
    exit 1
}

function not_release {
    echo "Can't find ${tgt_dir}/${1}"
    echo "Target isn't the proper release tree"
    exit 1
}

tgt_dir="$1"
if [ "$tgt_dir" == "" ]; then
    usage
fi

# Does the target directory look like the release?
if [ ! -d "$tgt_dir" ]; then
    echo "${tgt_dir} does not exist!"
    exit 1
fi

cd "$tgt_dir"
if [ ! -d Base/HW/bdw_503_pr_pkg/par -o ! -f Base/HW/bdw_503_pr_pkg/par/run.sh ]; then
    not_release "Base/HW/bdw_503_pr_pkg/par/run.sh"
fi

if [ ! -f Base/HW/bdw_503_pr_pkg/par/bdw_503_pr_afu_synth.qsf ]; then
    not_release "hw/lib/build/afu_synth.qsf"
fi

# Delete old copies of the update
rm -rf bin hw

#
# Set up bin directory
#
mkdir bin
# clean.sh just deletes. No more copying.
awk '/^rm/ { print "cd build"; print $0; exit } 1' Base/HW/bdw_503_pr_pkg/par/clean.sh > bin/clean.sh
chmod a+x bin/clean.sh
# Use updated run.sh
cp ${SCRIPT_DIR}/files/run.sh bin

#
# Build restructured hw/lib/build
#
echo "Restructuring SR-5.0.3 build tree into new standard hw tree..."
mkdir -p hw/lib/build/platform
cp -r Base/HW/bdw_503_pr_pkg/lib/blue/output_files hw/lib/build/output_files
cp -r Base/HW/bdw_503_pr_pkg/lib/blue/qdb_file/*.qdb hw/lib/build/
cp -r Base/HW/bdw_503_pr_pkg/lib/green/AFU_debug hw/lib/build/platform
cp Base/HW/bdw_503_pr_pkg/par/generate_pr_bitstream.sh hw/lib/build/
cp Base/HW/bdw_503_pr_pkg/par/*.qpf hw/lib/build/
cp Base/HW/bdw_503_pr_pkg/par/{quartus.ini,readme} hw/lib/build/
cp Base/HW/bdw_503_pr_pkg/lib/blue/BDW_base.sdc hw/lib/build/

# Grab the beginnings of qsf files
awk '/ccip_if_pkg.sv/ { exit } 1' Base/HW/bdw_503_pr_pkg/par/bdw_503_pr_afu_synth.qsf > hw/lib/build/bdw_503_pr_afu_synth.qsf
awk '/DO NOT MODIFY/ { print $0; exit } 1' Base/HW/bdw_503_pr_pkg/par/bdw_503_pr_afu.qsf | grep -v SDC > hw/lib/build/bdw_503_pr_afu.qsf
echo "# =====================================" >> hw/lib/build/bdw_503_pr_afu.qsf

# Copy updated green_bs.sv
echo "Adding hw/lib/build/platform/green_top.sv..."
cp "${SCRIPT_DIR}/files/green_top.sv" hw/lib/build/platform/

# Copy new a10_partial_reconfig scripts
echo "Adding hw/lib/build/a10_partial_reconfig..."
mkdir hw/lib/build/a10_partial_reconfig
cp "${SCRIPT_DIR}"/files/a10_partial_reconfig/*.sdc hw/lib/build/a10_partial_reconfig/
cp "${SCRIPT_DIR}"/files/a10_partial_reconfig/*.tcl hw/lib/build/a10_partial_reconfig/

# Copy platform DB
echo "Creating hw/lib/platform/platform_db..."
mkdir -p hw/lib/platform/platform_db
cp "${SCRIPT_DIR}"/files/platform_db/*[^~] hw/lib/platform/platform_db/

# Tag the platform type
echo "Storing platform name in hw/lib/fme-platform-class.txt..."
echo a10_gx_intg_xeon_bdx > hw/lib/fme-platform-class.txt

echo 00000000-0000-0000-0000-000000000000 > hw/lib/fme-ifc-id.txt

# Update QSF scripts to use the platform configuration
for qsf in hw/lib/build/bdw_503_pr_afu.qsf hw/lib/build/bdw_503_pr_afu_synth.qsf; do
    echo "Updating ${qsf}..."
    # Import the platform interface
    cat >>${qsf} <<EOF
set_global_assignment -name SEARCH_PATH ./platform
set_global_assignment -name SEARCH_PATH ./platform/AFU_debug
set_global_assignment -name SDC_FILE BDW_base.sdc

set_global_assignment -name SYSTEMVERILOG_FILE ./platform/green_top.sv
set_global_assignment -name QSYS_FILE ./platform/AFU_debug/SCJIO.qsys
set_global_assignment -name SDC_FILE a10_partial_reconfig/user_clocks.sdc
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ./platform/platform_if_addenda.qsf
set_global_assignment -name SEARCH_PATH ../hw
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../hw/afu.qsf
EOF
done

echo "Update complete."
