#! /bin/bash
# Copyright 2020-2026 NXP
# SPDX-License-Identifier: BSD-3-Clause
# Script to build MCX N94x/N54x Master Boot Image using nxpimage tool

# Environment variables - absolute paths simplifying re-use of the script on another machine
#  - Absolute path to SPT workspace (it is recommended to copy/move all user files in this workspace)
if [ -z "${SPT_WORKSPACE}" ]; then
  export "SPT_WORKSPACE=$(cd "$(dirname "$0")"; pwd -P)"
fi
if ! [ -d "$SPT_WORKSPACE" ]; then
  echo "FAILURE: Directory not found: $SPT_WORKSPACE"
  exit 2
fi
#  - Absolute path to SPT installation directory
if [ -z "${SPT_INSTALL_BIN}" ]; then
  export "SPT_INSTALL_BIN=E:/NXP_SEC_PROV_TOOL/bin/_internal"
fi
if ! [ -d "$SPT_INSTALL_BIN" ]; then
  echo "FAILURE: Directory not found: $SPT_INSTALL_BIN"
  exit 2
fi
#  - SPSDK debug log, absolute path
if [ -z "${SPSDK_DEBUG_LOG_FILE}" ]; then
  export "SPSDK_DEBUG_LOG_FILE=${SPT_WORKSPACE}/logs/spsdk-debug.log"
fi

# Use parameter: "no_dev_hsm_provi" to avoid creation and modification of dev_hsm_provisioning.sb file

echo "### Parse input arguments ###"
i=1
while (( i<=$#)); do
    param=${!i}
    case $param in
        "no_dev_hsm_provi")
            export "no_dev_hsm_provi=1"
            ;;
        *)
            echo "ERROR: Unsupported argument ${!i}"
            exit 2
    esac
    i=$((i+1))
done
# Used command line utilities
export "nxpimage=${SPT_INSTALL_BIN}/tools/spsdk/nxpimage"
export "pfr=${SPT_INSTALL_BIN}/tools/spsdk/pfr"
export "nxpdevhsm=${SPT_INSTALL_BIN}/tools/spsdk/nxpdevhsm"

# SUBROUTINE hook script execution, accepts one argument "hook step", if specified it is passed into hook script, when not specified call context hook script
hook_execute()
{
    if [ $# -eq 0 ]; then
        if [ -x "${SPT_WORKSPACE}/hooks/build_context_mac.sh" ]; then
            source "${SPT_WORKSPACE}/hooks/build_context_mac.sh"
            if [ $? -ge 1 ]; then
                exit 2
            fi
        fi
    else
        if [ -x "${SPT_WORKSPACE}/hooks/build_mac.sh" ]; then
            "${SPT_WORKSPACE}/hooks/build_mac.sh" $1
            if [ $? -ge 1 ]; then
                exit 2
            fi
        fi
    fi
}

mkdir -p "${SPT_WORKSPACE}/bootable_images"
if [ $? -ge 1 ]; then
    exit 2
fi
# Call hook that can modify environment variables
hook_execute
# hook executed before any other command is executed
hook_execute started

echo '### Create Master Boot Image using nxpimage tool ###'
"$nxpimage" mbi export -c "${SPT_WORKSPACE}/configs/mbi_config.yaml"
if [ $? -ge 1 ]; then
    exit 2
fi
# hook executed after build of bootable image is done
hook_execute build_image_done

echo "### Create reset application Master Boot Image ###"
"$nxpimage" mbi export -c "${SPT_WORKSPACE}/configs/mbi_cfg_4_reset_app.yaml"
if [ $? -ge 1 ]; then
    exit 2
fi

echo "### Create CFPA page (binary) ###"
echo "$pfr export -c \"${SPT_WORKSPACE}/configs/cfpa.yaml\" -o \"${SPT_WORKSPACE}/configs/cfpa.bin\""
"$pfr" export -c "${SPT_WORKSPACE}/configs/cfpa.yaml" -o "${SPT_WORKSPACE}/configs/cfpa.bin"
[ $? -ge 1 ] && exit 2 || true

echo "### Create CMPA page (binary) ###"
echo "$pfr export -c \"${SPT_WORKSPACE}/configs/cmpa.yaml\" -e \"${SPT_WORKSPACE}/keys/IMG1_1_cert_block.bin\" -o \"${SPT_WORKSPACE}/configs/cmpa.bin\""
"$pfr" export -c "${SPT_WORKSPACE}/configs/cmpa.yaml" -e "${SPT_WORKSPACE}/keys/IMG1_1_cert_block.bin" -o "${SPT_WORKSPACE}/configs/cmpa.bin"
[ $? -ge 1 ] && exit 2 || true
# hook executed after CFPA or/and CMPA page generation is done
hook_execute pfr_generation_done

echo "### Create SB file ###"
"$nxpimage" sb31 export -c "${SPT_WORKSPACE}/configs/sb3_config.yaml"
if [ $? -ge 1 ]; then
    exit 2
fi

if [ "$no_dev_hsm_provi" = "1" ]; then
    # hook executed after SB file generation is done
    hook_execute build_sb_done
    # hook executed after all steps of the script were executed
    hook_execute finished
    echo "Device HSM build skipped due to parameter."
    exit 0
fi
echo "### Create key-provisioning SB file installing CUST-MK-SK key into processor ###"
mkdir -p "$SPT_WORKSPACE/configs/nxpdevhsm"
if [ $? -ge 1 ]; then
    exit 2
fi
echo "$nxpdevhsm generate -u 0x1FC9,0x014F -oc \"containerOutputFile=$SPT_WORKSPACE/bootable_images/dev_hsm_provisioning.sb\" -c \"${SPT_WORKSPACE}/configs/dev_hsm_provi_sb3.yaml\""
"$nxpdevhsm" generate -u 0x1FC9,0x014F \
    -oc "containerOutputFile=$SPT_WORKSPACE/bootable_images/dev_hsm_provisioning.sb" \
    -c "${SPT_WORKSPACE}/configs/dev_hsm_provi_sb3.yaml"
if [ $? -ge 1 ]; then
    echo "Build of device HSM provisioning SB file failed; however rest of the build script passed and the application was built successfully."
    echo "Build of device HSM provisioning SB file usually fails if the board is not in ISP mode or processor is not in development life cycle."
    exit 2
fi
# hook executed after SB file generation is done
hook_execute build_sb_done

# hook executed after all steps of the script were executed
hook_execute finished