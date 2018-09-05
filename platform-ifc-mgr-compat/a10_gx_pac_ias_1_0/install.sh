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
## Update the a10_gx_pac_ias 1.0 release for use with the platform database.
## After the update, the original sample workloads continue to compile.
## After the transformation, the OPAE afu_sim_setup and afu_synth_setup
## scripts may be used to configure workloads.
##

SCRIPTNAME="$(basename -- "$0")"
SCRIPT_DIR="$(cd "$(dirname -- "$0")" 2>/dev/null && pwd -P)"

function usage {
    echo "Usage: ${SCRIPTNAME} <a10_gx_pac_ias_1_0 release dir>"
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

# Copy the updated run.sh
echo "Updating bin/run.sh..."
cp "${SCRIPT_DIR}/files/run.sh" bin

# Drop bin/packager.  OPAE's updated packager will be used instead.
if [ -f bin/packager ]; then
    mv bin/packager bin/packager.disabled
fi

# Copy updated green_bs.sv
if [ ! -f hw/lib/build/platform/green_bs.sv.orig ]; then
    mv hw/lib/build/platform/green_bs.sv hw/lib/build/platform/green_bs.sv.orig
fi
echo "Updating hw/lib/build/platform/green_bs.sv..."
cp "${SCRIPT_DIR}/files/green_bs.sv" "hw/lib/build/platform/green_bs.sv"

# Copy user clock constraints
echo "Adding hw/lib/build/dcp_user_clocks.sdc..."
cp "${SCRIPT_DIR}/files/dcp_user_clocks.sdc" "hw/lib/build/dcp_user_clocks.sdc"

# Copy new a10_partial_reconfig scripts
echo "Updating hw/lib/build/a10_partial_reconfig..."
cp "${SCRIPT_DIR}"/files/a10_partial_reconfig/*.tcl hw/lib/build/a10_partial_reconfig/

# Remove files that are no longer needed
if [ -f hw/lib/build/platform/ccip_if_pkg.sv ]; then
    # This will come from the platform database
    mv hw/lib/build/platform/ccip_if_pkg.sv hw/lib/build/platform/ccip_if_pkg.sv.orig
fi

# Copy platform DB
echo "Creating hw/lib/platform/platform_db..."
mkdir -p hw/lib/platform/platform_db
cp "${SCRIPT_DIR}"/files/platform_db/*[^~] hw/lib/platform/platform_db/

# Tag the platform type
echo "Storing platform name in hw/lib/fme-platform-class.txt..."
echo a10_gx_pac > hw/lib/fme-platform-class.txt

# Update QSF scripts to use the platform configuration
for qsf in hw/lib/build/afu_synth.qsf hw/lib/build/afu_fit.qsf; do
    echo "Updating ${qsf}..."
    if [ ! -f ${qsf}.orig ]; then
        cp -p ${qsf} ${qsf}.orig
    fi

    # Drop ccip_if_pkg.sv from configuration.  Also drop the include of ../hw/afu.qsf.
    # We will add it back at the end.
    grep -v ccip_if_pkg.sv ${qsf}.orig | grep -v ../hw/afu.qsf > ${qsf}

    # Import the platform interface
    cat >>${qsf} <<EOF
set_global_assignment -name SDC_FILE dcp_user_clocks.sdc
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ./platform/platform_if_addenda.qsf
set_global_assignment -name SEARCH_PATH ../hw
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE ../hw/afu.qsf
EOF
done

echo "Update complete."
