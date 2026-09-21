#! /bin/bash
# Copyright 2020-2026 NXP
# SPDX-License-Identifier: BSD-3-Clause

# The script for writing the image into MCX N94x/N54x


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

# Use parameter: "blhost_connect <connection_param>" to use custom connection parameters for blhost
#     <connection_param> should be in format "-p COMx[,baud]" or "-u VID,PID" and must be enclosed in quotes
# Use parameter: "manufacturing_task_no index" to set number/index of the manufacturing task (to avoid same filename created from two tasks)
# Use parameter: "erase_all" to perform an erase of the entire flash memory instead erasing only regions that will be written
# Use parameter: "pre_erase" to perform an erase of the first region in the bootable region to prevent potential application start after the reset in provisioning part of the script, the write script expects the processor stays in ISP mode
# Use parameter: "manufacturing_phase <n>" to specify manufacturing phase: 1 for fuse burning and reset, 2 for application download

# Default connection parameters
export "blhost_connect=-u 0x1FC9,0x014F"
export "manufacturing_task_no="

echo "### Parse input arguments ###"
i=1
while (( i<=$#)); do
    param=${!i}
    case $param in
        "blhost_connect")
            i=$((i+1))
            export "blhost_connect=${!i}"
            ;;
        "manufacturing_task_no")
            i=$((i+1))
            export "manufacturing_task_no=${!i}"
            ;;
        "erase_all")
            export "erase_all=1"
            ;;
        "pre_erase")
            export "pre_erase=1"
            ;;
        "manufacturing_phase")
            i=$((i+1))
            export "manufacturing_phase=${!i}"
            ;;
        *)
            echo "ERROR: Unsupported argument ${!i}"
            exit 2
    esac
    i=$((i+1))
done

# Used command line utilities
export "blhost=${SPT_INSTALL_BIN}/tools_scripts/blhost_spsdk_mac_wrapper.sh"

# SUBROUTINE hook script execution, accepts one argument "hook step", if specified it is passed into hook script, when not specified call context hook script
hook_execute()
{
    if [ $# -eq 0 ]; then
        if [ -x "${SPT_WORKSPACE}/hooks/write_context_mac.sh" ]; then
            source "${SPT_WORKSPACE}/hooks/write_context_mac.sh"
            if [ $? -ge 1 ]; then
                exit 2
            fi
        fi
    else
        if [ -x "${SPT_WORKSPACE}/hooks/write_mac.sh" ]; then
            "${SPT_WORKSPACE}/hooks/write_mac.sh" $1
            if [ $? -ge 1 ]; then
                exit 2
            fi
        fi
    fi
}

# Call hook that can modify environment variables
hook_execute
# hook executed before any other command is executed
hook_execute started

if [ "$manufacturing_phase" = "2" ]; then
    true  # do nothing, ignore phase 1
else
# ======================== MANUFACTURING PHASE 1 ========================
# === Phase 1: Provisioning: Apply security assets into processor and reset

# Ping the device to establish communication; Result is ignored as the communication sometime fails for the first time
"$blhost" $blhost_connect -j -- get-property 1 0 > /dev/null 2> /dev/null

echo "### Check connection ###"
"$blhost" $blhost_connect -j -- get-property 1 0
if [ $? -ge 2 ]; then exit 2; fi

# === Handle processor in DEPLOYMENT mode ===
echo "### Check if processor is in DEVELOPMENT mode ###"
export "blhost_wrapper_expected_output=3275539260 (0xc33cc33c)"
"$blhost" $blhost_connect -- get-property 17
STATUS=$?
unset blhost_wrapper_expected_output
if [ $STATUS -ge 2 ]; then exit 2; fi
if [ $STATUS -ge 1 ]; then
    echo "### Processor is in DEPLOYMENT mode; however the application still can be updated using SB file ###"
    echo "### WARNING - CFPA page is not included in the SB file if the workspace is not in SECURED life cycle ###"

    echo "### Load/Update bootable image using SB capsule ###"
    "$blhost" $blhost_connect -- receive-sb-file "${SPT_WORKSPACE}/bootable_images/zephyr.sb"
    if [ $? -ge 1 ]; then
        echo "Try to call receive-sb-file with parameter '--check-errors' to detect real problem description"
        exit 2
    fi
    # hook executed after processing of SB file is done
    hook_execute sb_file_processed

    # hook executed after all steps of the script were executed
    hook_execute finished
    exit 0
fi

# === Erase ===
if [ "$erase_all" = "1" ]; then
    echo "### Erase entire flash ###"
    "$blhost" $blhost_connect -j -- flash-erase-all 0
    if [ $STATUS -ge 2 ]; then
        exit 2
    fi
elif [ "$pre_erase" = "1" ]; then
    echo "### Pre erase flash to prevent potential application start after the reset when provisioning is done ###"
    "$blhost" $blhost_connect -j -- flash-erase-region 0x00000000 8192 0
    if [ $? -ge 1 ]; then exit 2; fi
fi
# hook executed after erase of the memory is done
hook_execute erase_done

# === Apply device HSM SB file ===
echo "### Install/update security assets (like CUST_MK_SK key, CMPA, CFPA) using provisioning SB capsule ###"
"$blhost" $blhost_connect -- receive-sb-file "${SPT_WORKSPACE}/bootable_images/dev_hsm_provisioning.sb"
if [ $? -ge 1 ]; then
    echo "Try to call receive-sb-file with parameter '--check-errors' to detect real problem description"
    exit 2
fi

echo "### Wait until processor restarts - 3 seconds ###"
echo "### Timeout wait value can be adjusted from Preferences ###"
sleep 3

# hook executed after device provisioning SB file is processed
hook_execute device_provisioning_sb_processed

fi

if [ "$manufacturing_phase" = "1" ]; then
    exit 0
fi

# ======================== MANUFACTURING PHASE 2 ========================
# === Phase 2: Application image downloaded into target memory

# Test connection
"$blhost" $blhost_connect -- get-property 1
STATUS=$?
if [ $STATUS -ge 2 ]; then exit 2; fi

# === CFPA ===
echo "### Write Customer Field Programmable Area [CFPA] ###"
"$blhost" $blhost_connect -j -- write-memory 0x01000000 "${SPT_WORKSPACE}/configs/cfpa.bin"
STATUS="$?"
if [ $STATUS -eq 1 ]; then
    echo "### WARNING - CFPA page already written; check CFPA version to update the content ###"
elif [ $STATUS -ge 2 ]; then
    exit 2
fi
# hook executed after write of the CFPA is done
hook_execute cfpa_written

# === Load/update application using SB3 capsule ===
echo "### Load/Update bootable image using SB3 capsule ###"
"$blhost" $blhost_connect -- receive-sb-file "${SPT_WORKSPACE}/bootable_images/zephyr.sb"
if [ $? -ge 1 ]; then
    echo "Try to call receive-sb-file with parameter '--check-errors' to detect real problem description"
    exit 2
fi
# hook executed after processing of SB file is done
hook_execute sb_file_processed
# hook executed after all steps of the script were executed
hook_execute finished