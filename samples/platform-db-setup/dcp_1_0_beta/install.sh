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

##
## Update the DCP 1.0 beta release for use with the platform database.
## After the update, the original sample workloads continue to compile.
## The script adds a new "afu_quartus_setup" script that is the analog
## of the OPAE "afu_sim_setup" script.
##

SCRIPTNAME="$(basename -- "$0")"
SCRIPT_DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd -P)"

function usage {
    echo "Usage: ${SCRIPTNAME} <dcp_1_0_beta release dir>"
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
if [ ! -d bin -o ! -f bin/run.sh ]; then
    not_release "bin/run.sh"
fi

if [ ! -f hw/lib/build/afu_synth.qsf ]; then
    not_release "hw/lib/build/afu_synth.qsf"
fi

if [ ! -f hw/lib/build/platform/green_bs.sv ]; then
    not_release "hw/lib/build/platform/green_bs.sv"
fi

# Add afu_synth_setup to bin
cp ${SCRIPT_DIR}/../common/files/afu_synth_setup bin

# Drop bin/packager.  OPAE's updated packager will be used instead.
if [ -f bin/packager ]; then
    mv bin/packager bin/packager.disabled
fi

# Copy updated green_bs.sv
if [ ! -f hw/lib/build/platform/green_bs.sv.orig ]; then
    mv hw/lib/build/platform/green_bs.sv hw/lib/build/platform/green_bs.sv.orig
fi
cp "${SCRIPT_DIR}/files/green_bs.sv" "hw/lib/build/platform/green_bs.sv"

# Copy updated dcp_bbs.sdc
if [ ! -f hw/lib/build/dcp_bbs.sdc.orig ]; then
    mv hw/lib/build/dcp_bbs.sdc hw/lib/build/dcp_bbs.sdc.orig
fi
cp "${SCRIPT_DIR}/files/dcp_bbs.sdc" "hw/lib/build/dcp_bbs.sdc"

# Copy new afu_json.tcl
cp "${SCRIPT_DIR}/../common/files/afu_json.tcl" hw/lib/build/platform/lib/common/

# Remove files that are no longer needed
if [ -f hw/lib/build/platform/ccip_if_pkg.sv ]; then
    # This will come from the platform database
    mv hw/lib/build/platform/ccip_if_pkg.sv hw/lib/build/platform/ccip_if_pkg.sv.orig
fi

# Tag the platform type
echo discrete_pcie3 > hw/lib/fme-platform-class.txt

# Install default platform database files
afu_platform_config --ifc=ccip_std_afu_avalon_mm_legacy_wires --qsf --tgt=hw/lib/build/platform discrete_pcie3

# Update QSF scripts to use the platform configuration
for qsf in hw/lib/build/afu_synth.qsf hw/lib/build/afu_fit.qsf; do
    if [ ! -f ${qsf}.orig ]; then
        cp -p ${qsf} ${qsf}.orig
    fi

    # Drop ccip_if_pkg.sv from configuration.  Also drop the include of ../hw/afu.qsf.
    # We will add it back at the end.
    grep -v ccip_if_pkg.sv ${qsf}.orig | grep -v ../hw/afu.qsf > ${qsf}

    # Import the platform interface
    cat >>${qsf} <<EOF
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ./platform/lib/common/afu_json.tcl
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ./platform/platform_if_addenda.qsf
set_global_assignment -name SEARCH_PATH ../hw
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../hw/afu.qsf
EOF
done
