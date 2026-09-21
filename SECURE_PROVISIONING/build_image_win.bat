@echo off
@rem Copyright 2020-2026 NXP
@rem SPDX-License-Identifier: BSD-3-Clause
@rem Script to build MCX N94x/N54x Master Boot Image using nxpimage tool

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

@rem Use parameter: "no_dev_hsm_provi" to avoid creation and modification of dev_hsm_provisioning.sb file

@echo ### Parse input arguments ###
:test_param_loop
if [%1]==[] (
  goto test_param_end
)
set param=%1
set known_param=0
if "%param%"=="no_dev_hsm_provi" (
    set no_dev_hsm_provi=1
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
SET "nxpimage=%SPT_INSTALL_BIN%\tools\spsdk\nxpimage.exe"
SET "pfr=%SPT_INSTALL_BIN%\tools\spsdk\pfr.exe"
SET "nxpdevhsm=%SPT_INSTALL_BIN%\tools\spsdk\nxpdevhsm.exe"

if not exist "%SPT_WORKSPACE%\bootable_images\." (
    mkdir "%SPT_WORKSPACE%\bootable_images"
    if errorlevel 1 exit /B 2
)

@rem Call hook that can modify environment variables
call :hook_execute
if errorlevel 1 exit /B 2

@rem hook executed before any other command is executed
call :hook_execute started
if errorlevel 1 exit /B 2

@echo ### Create Master Boot Image using nxpimage tool ###
call "%nxpimage%" mbi export -c "%SPT_WORKSPACE%\configs\mbi_config.yaml"
if errorlevel 1 exit /B 2
@rem hook executed after build of bootable image is done
call :hook_execute build_image_done
if errorlevel 1 exit /B 2

@echo ### Create reset application Master Boot Image ###
call "%nxpimage%" mbi export -c "%SPT_WORKSPACE%\configs\mbi_cfg_4_reset_app.yaml"
if errorlevel 1 exit /B 2

@echo ### Create CFPA page - binary ###
@echo call "%pfr%" export -c "%SPT_WORKSPACE%\configs\cfpa.yaml" -o "%SPT_WORKSPACE%\configs\cfpa.bin"
call "%pfr%" export -c "%SPT_WORKSPACE%\configs\cfpa.yaml" -o "%SPT_WORKSPACE%\configs\cfpa.bin"
if errorlevel 1 exit /B 2

@echo ### Create CMPA page - binary ###
@echo call "%pfr%" export -c "%SPT_WORKSPACE%\configs\cmpa.yaml" -e "%SPT_WORKSPACE%\keys\IMG1_1_cert_block.bin" -o "%SPT_WORKSPACE%\configs\cmpa.bin"
call "%pfr%" export -c "%SPT_WORKSPACE%\configs\cmpa.yaml" -e "%SPT_WORKSPACE%\keys\IMG1_1_cert_block.bin" -o "%SPT_WORKSPACE%\configs\cmpa.bin"
if errorlevel 1 exit /B 2
@rem hook executed after CFPA or/and CMPA page generation is done
call :hook_execute pfr_generation_done
if errorlevel 1 exit /B 2

@echo ### Create SB file ###
call "%nxpimage%" sb31 export -c "%SPT_WORKSPACE%\configs\sb3_config.yaml"
if errorlevel 1 exit /B 2

if [%no_dev_hsm_provi%] == [1] (
    @rem hook executed after SB file generation is done
    call :hook_execute build_sb_done
    if errorlevel 1 exit /B 2
    @rem hook executed after all steps of the script were executed
    call :hook_execute finished
    if errorlevel 1 exit /B 2
    @echo Device HSM build skipped due to parameter.
    exit /B 0
)
@echo ### Create key-provisioning SB file installing CUST-MK-SK key into processor ###
if not exist "%SPT_WORKSPACE%\configs\nxpdevhsm\." (
    mkdir "%SPT_WORKSPACE%\configs\nxpdevhsm"
    if errorlevel 1 exit /B 2
)
@echo call "%nxpdevhsm%" generate -u 0x1FC9,0x014F -oc "containerOutputFile=%SPT_WORKSPACE%\bootable_images\dev_hsm_provisioning.sb" -c "%SPT_WORKSPACE%\configs\dev_hsm_provi_sb3.yaml"
call "%nxpdevhsm%" generate -u 0x1FC9,0x014F ^
    -oc "containerOutputFile=%SPT_WORKSPACE%\bootable_images\dev_hsm_provisioning.sb" ^
    -c "%SPT_WORKSPACE%\configs\dev_hsm_provi_sb3.yaml"
if errorlevel 1 (
    @echo Build of device HSM provisioning SB file failed; however rest of the build script passed and the application was built successfully.
    @echo Build of device HSM provisioning SB file usually fails if the board is not in ISP mode or processor is not in development life cycle.
    exit /B 2
)
@rem hook executed after SB file generation is done
call :hook_execute build_sb_done
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
    if exist "%SPT_WORKSPACE%\hooks\build_context_win.bat" (
        call "%SPT_WORKSPACE%\hooks\build_context_win.bat"
    )
) else (
    if exist "%SPT_WORKSPACE%\hooks\build_win.bat" (
        call "%SPT_WORKSPACE%\hooks\build_win.bat" %~1
    )
)
goto :eof