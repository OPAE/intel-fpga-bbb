#!/bin/sh

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

BBS_LIB_PATH=${BBS_LIB_PATH:-"${SCRIPT_DIR}/../hw/lib"}
PACKAGER=${PACKAGER:-packager}
GBS_FILE=${GBS_FILE:-$(basename "${AFU_JSON}" .json).gbs}

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
    cp -rLf "${BBS_LIB_PATH}/build/BDW_503_BASE_2041_seed2.qdb" \
            "${BBS_LIB_PATH}/build/output_files" \
            ./build/
else
    cp -rLf "${BBS_LIB_PATH}/build/BDW_503_BASE_2041_seed2.qdb" \
            "${BBS_LIB_PATH}/build/output_files" \
            ./build/

    # Configure the platform interface
    afu_platform_config --qsf --src "${AFU_JSON}" --default-ifc ccip_std_afu --tgt ./build/platform "${PLATFORM_CLASS}"
fi

cd build

PROJ_REV1_NAME="BDW_503_BASE_2041_seed2"
PROJ_REV2_NAME="bdw_503_pr_afu_synth"
PROJ_REV3_NAME="bdw_503_pr_afu"

echo "Revision 1 : $PROJ_REV1_NAME"
echo "Revision 2 : $PROJ_REV2_NAME"
echo "Revision 3 : $PROJ_REV3_NAME"
echo "*********************************************************************************************"

SYNTH_SUCCESS=1
FIT_SUCCESS=1
ASM_SUCCESS=1

# Synthesize PR Persona
# ---------------------
quartus_syn --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV2_NAME
SYNTH_SUCCESS=$?

# Fit PR Persona
# --------------
if [ $SYNTH_SUCCESS -eq 0 ]
then
    quartus_cdb --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV2_NAME --export_block "root_partition" --snapshot synthesized --file "$PROJ_REV2_NAME.qdb"
    quartus_cdb --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV3_NAME --import_block "root_partition" --file "$PROJ_REV1_NAME.qdb"
    quartus_cdb --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV3_NAME --import_block persona1 --file "$PROJ_REV2_NAME.qdb"
    quartus_fit --read_settings_files=on $PROJ_REV1_NAME -c $PROJ_REV3_NAME
    FIT_SUCCESS=$?
else
    echo "Persona synthesis failed"
    exit
fi

# Run Assembler 
# -------------
if [ $FIT_SUCCESS -eq 0 ]
then
    quartus_asm $PROJ_REV1_NAME -c $PROJ_REV3_NAME
    ASM_SUCCESS=$?
else
    echo "Assembler failed"
    exit 1
fi

# Report Timing
# -------------
if [ $ASM_SUCCESS -eq 0 ]
then
    quartus_sta --do_report_timing $PROJ_REV1_NAME -c $PROJ_REV3_NAME
else
    echo "Persona compilation failed"
    exit 1
fi

# Generate output files for PR persona
# ------------------------------------
if [ $ASM_SUCCESS -eq 0 ]
then
    echo "Generating PR rbf file"
    ./generate_pr_bitstream.sh
else
    echo "Persona compilation failed"
    exit 1
fi

cd ..
"${PACKAGER}" create-gbs \
              --gbs="${GBS_FILE}" \
              --afu-json="${AFU_JSON}" \
              --rbf=./build/output_files/bdw_503_pr_afu.rbf \
              --set-value=interface-uuid:"${INTERFACE_UUID}"
PACKAGER_RETCODE=$?

if [ $PACKAGER_RETCODE -ne 0 ]; then
    echo "Package build failed"
    exit $PACKAGER_RETCODE
fi

echo ""
echo "======================================================="
echo "BDW 503 PR AFU compilation complete"
echo "AFU gbs file located at ${GBS_FILE}"
echo "======================================================="
echo ""
