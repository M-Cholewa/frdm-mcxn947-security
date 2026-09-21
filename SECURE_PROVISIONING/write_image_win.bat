@echo off
@rem Copyright 2020-2026 NXP
@rem SPDX-License-Identifier: BSD-3-Clause

@rem The script for writing the image into MCX N94x/N54x

@rem Environment variables - absolute paths simplifying re-use of the script on another machine
@rem - Absolute path to SPT workspace (it is recommended to copy/move all user files in this workspace)
SETLOCAL ENABLEDELAYEDEXPANSION
if "%SPT_WORKSPACE%"=="" (
  SET "SPT_WORKSPACE=%~dp0"
  SET "SPT_WORKSPACE=!SPT_WORKSPACE:~0,-1!"
)
ENDLOCAL & SET "SPT_WORKSPACE=%SPT_WORKSPACE%"
if not exist "%SPT_WORKSPACE%\" (
  @echo FAILURE: Directory not found "%SPT_WORKSPACE%"
  exit /B 2
)
@rem - Absolute path to SPT installation directory
if "%SPT_INSTALL_BIN%"=="" (
  SET "SPT_INSTALL_BIN=E:\NXP_SEC_PROV_TOOL\bin\_internal"
)
if not exist "%SPT_INSTALL_BIN%\" (
  @echo FAILURE: Directory not found "%SPT_INSTALL_BIN%"
  exit /B 2
)
@rem - SPSDK debug log, absolute path
if "%SPSDK_DEBUG_LOG_FILE%"=="" (
  SET "SPSDK_DEBUG_LOG_FILE=%SPT_WORKSPACE%\logs\spsdk-debug.log"
)

@rem Use parameter: "blhost_connect <connection_param>" to use custom connection parameters for blhost
@rem     <connection_param> should be in format "-p COMx[,baud]" or "-u VID,PID" and must be enclosed in quotes
@rem Use parameter: "manufacturing_task_no index" to set number/index of the manufacturing task (to avoid same filename created from two tasks)
@rem Use parameter: "erase_all" to perform an erase of the entire flash memory instead erasing only regions that will be written
@rem Use parameter: "pre_erase" to perform an erase of the first region in the bootable region to prevent potential application start after the reset in provisioning part of the script, the write script expects the processor stays in ISP mode
@rem Use parameter: "manufacturing_phase <n>" to specify manufacturing phase: 1 for fuse burning and reset, 2 for application download

@rem Default connection parameters
set blhost_connect=-u 0x1FC9,0x014F
set "manufacturing_task_no="

@echo ### Parse input arguments ###
:test_param_loop
if [%1]==[] (
  goto test_param_end
)
set param=%1
set known_param=0
if "%param%"=="blhost_connect" (
    set blhost_connect=%~2
    SHIFT
    set known_param=1
)
if "%param%"=="manufacturing_task_no" (
    set manufacturing_task_no=%~2
    SHIFT
    set known_param=1
)
if "%param%"=="erase_all" (
    set erase_all=1
    set known_param=1
)
if "%param%"=="pre_erase" (
    set pre_erase=1
    set known_param=1
)
if "%param%"=="manufacturing_phase" (
    set manufacturing_phase=%~2
    SHIFT
    set known_param=1
)
if %known_param%==0 (
    echo ERROR: unsupported argument "%param%"
    exit /B 2
)
@rem Check for further batch arguments
SHIFT
goto test_param_loop
:test_param_end

@rem Used command line utilities
SET "blhost=%SPT_INSTALL_BIN%\tools_scripts\blhost_spsdk_win_wrapper.bat"

@rem Call hook that can modify environment variables
call :hook_execute
if errorlevel 1 exit /B 2
@rem hook executed before any other command is executed
call :hook_execute started
if errorlevel 1 exit /B 2

if [%manufacturing_phase%] == [2] (
    goto manufacturing_phase_2
)

@rem ======================== MANUFACTURING PHASE 1 ========================
@rem === Phase 1: Provisioning: Apply security assets into processor and reset

@rem Ping the device to establish communication; Result is ignored as the communication sometime fails for the first time
call "%blhost%" %blhost_connect% -j -- get-property 1 0 > nul 2> nul

@echo ### Check connection ###
call "%blhost%" %blhost_connect% -j -- get-property 1 0
if errorlevel 2 exit /B 2

@rem === Handle processor in DEPLOYMENT mode ===
@echo ### Check if processor is in DEVELOPMENT mode ###
set "blhost_wrapper_expected_output=3275539260 (0xc33cc33c)"
call "%blhost%" %blhost_connect% -- get-property 17
set "blhost_wrapper_expected_output="
if errorlevel 2 exit /B 2
if errorlevel 1 (
    @echo ### Processor is in DEPLOYMENT mode; however the application still can be updated using SB file ###
    @echo ### WARNING - CFPA page is not included in the SB file if the workspace is not in SECURED life cycle ###

    @echo ### Load/Update bootable image using SB capsule ###
    call "%blhost%" %blhost_connect% -- receive-sb-file "%SPT_WORKSPACE%\bootable_images\zephyr.sb"
    if errorlevel 1 (
        echo Try to call receive-sb-file with parameter `--check-errors` to detect real problem description
        exit /B 2
    )
    @rem hook executed after processing of SB file is done
    call :hook_execute sb_file_processed
    if errorlevel 1 exit /B 2

    @rem hook executed after all steps of the script were executed
    call :hook_execute finished
    if errorlevel 1 exit /B 2
    exit /B 0
)

@rem === Erase ===
if [%erase_all%] == [1] (
    @echo ### Erase entire flash ###
    call "%blhost%" %blhost_connect% -j -- flash-erase-all 0
    if errorlevel 2 exit /B 2
) else (
    if [%pre_erase%] == [1] (
        @echo ### Pre erase flash to prevent potential application start after the reset when provisioning is done ###
        call "%blhost%" %blhost_connect% -j -- flash-erase-region 0x00000000 8192 0
        if errorlevel 1 exit /B 2
    )
)
@rem hook executed after erase of the memory is done
call :hook_execute erase_done
if errorlevel 1 exit /B 2


@rem === Apply device HSM SB file ===
@echo ### Install/update security assets [like CUST_MK_SK key, CMPA, CFPA, etc] using provisioning SB capsule ###
call "%blhost%" %blhost_connect% -- receive-sb-file "%SPT_WORKSPACE%\bootable_images\dev_hsm_provisioning.sb"
if errorlevel 1 (
    echo Try to call receive-sb-file with parameter `--check-errors` to detect real problem description
    exit /B 2
)

@echo ### Wait until processor restarts - 3 seconds ###
@echo ### Timeout wait value can be adjusted from Preferences ###
setlocal EnableDelayedExpansion
SET /A "timeout=3 + 1"
ping -n !timeout! 127.0.0.1 >NUL
endlocal

@rem hook executed after device provisioning SB file is processed
call :hook_execute device_provisioning_sb_processed
if errorlevel 1 exit /B 2

if [%manufacturing_phase%] == [1] (
    exit /B 0
)

@rem ======================== MANUFACTURING PHASE 2 ========================
@rem === Phase 2: Application image downloaded into target memory
:manufacturing_phase_2

@rem Test connection
call "%blhost%" %blhost_connect% -- get-property 1
if errorlevel 2 exit /B 2

@rem === CFPA ===
@echo ### Write Customer Field Programmable Area [CFPA] ###
call "%blhost%" %blhost_connect% -j -- write-memory 0x01000000 "%SPT_WORKSPACE%\configs\cfpa.bin"
if errorlevel 2 exit /B 2
if errorlevel 1 (
    @echo ### WARNING - CFPA page already written; check CFPA version to update the content ###
)
@rem hook executed after write of the CFPA is done
call :hook_execute cfpa_written
if errorlevel 1 exit /B 2

@rem === Load/update application using SB3 capsule ===
@echo ### Load/Update bootable image using SB3 capsule ###
call "%blhost%" %blhost_connect% -- receive-sb-file "%SPT_WORKSPACE%\bootable_images\zephyr.sb"
if errorlevel 1 (
    echo Try to call receive-sb-file with parameter `--check-errors` to detect real problem description
    exit /B 2
)
@rem hook executed after processing of SB file is done
call :hook_execute sb_file_processed
if errorlevel 1 exit /B 2
@rem hook executed after all steps of the script were executed
call :hook_execute finished
if errorlevel 1 exit /B 2
@rem Script finished successfully
exit /B 0


@rem SUBROUTINE hook script execution
:hook_execute
@rem call dummy command to ensure error level is cleared
@time /t > nul
if "%~1"=="" (
    if exist "%SPT_WORKSPACE%\hooks\write_context_win.bat" (
        call "%SPT_WORKSPACE%\hooks\write_context_win.bat"
    )
) else (
    if exist "%SPT_WORKSPACE%\hooks\write_win.bat" (
        call "%SPT_WORKSPACE%\hooks\write_win.bat" %~1
    )
)
goto :eof