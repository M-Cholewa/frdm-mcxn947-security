@echo off
@rem Copyright 2021-2026 NXP
@rem SPDX-License-Identifier: BSD-3-Clause
@rem Environment variables - absolute paths simplifying re-use of the script on another machine
@rem - Absolute path to SPT workspace (it is recommended to copy/move all user files in this workspace)
SETLOCAL ENABLEDELAYEDEXPANSION
if "%SPT_WORKSPACE%"=="" (
  SET "SPT_WORKSPACE=%~dp0"
  SET "SPT_WORKSPACE=!SPT_WORKSPACE:~0,-1!"
  FOR %%i in ("!SPT_WORKSPACE!") DO (
    SET "SPT_WORKSPACE=%%~dpi"
  )
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

chcp 65001 >nul
SET "nxpcrypto=%SPT_INSTALL_BIN%\tools\spsdk\nxpcrypto.exe"
SET "nxpimage=%SPT_INSTALL_BIN%\tools\spsdk\nxpimage.exe"

@rem Ensure target directories exists
if not exist "%SPT_WORKSPACE%\keys\." (
    mkdir "%SPT_WORKSPACE%\keys"
    if errorlevel 1 exit /B 2
)

@rem Switch to working directory
pushd "%SPT_WORKSPACE%\keys"

@rem Log tools info
if not exist spt_tools_versions.txt (
    echo This file contains version of the tools used for keys generation: > spt_tools_versions.txt
    echo. >> spt_tools_versions.txt
    echo Key set generated using: >> spt_tools_versions.txt
) else (
    echo. >> spt_tools_versions.txt
    echo Key added using: >> spt_tools_versions.txt
)
echo Secure Provisioning Tool Version 26.06.b260612 >> spt_tools_versions.txt
call "%nxpcrypto%" --version >> spt_tools_versions.txt

@rem ### Generate keys ###
@echo Generate key: ROT1_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT1_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT1_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo Generate key: IMG1_1_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG1_1_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG1_1_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo Generate key: ROT2_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT2_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT2_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo Generate key: IMG2_1_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG2_1_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG2_1_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo Generate key: ROT3_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT3_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT3_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo Generate key: IMG3_1_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG3_1_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG3_1_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo Generate key: ROT4_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT4_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\ROT4_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo Generate key: IMG4_1_p256
@echo call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG4_1_p256.pem"
call "%nxpcrypto%" key generate -k secp256r1 -o "%SPT_WORKSPACE%\keys\IMG4_1_p256.pem"
if errorlevel 1 (
    popd
    exit /B 2
)

@rem ### Generate cert blocks ###
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT1_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT1_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT2_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT2_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT3_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT3_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT4_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\ROT4_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG1_1_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG1_1_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG2_1_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG2_1_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG3_1_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG3_1_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)
@echo call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG4_1_cert_block.yaml"
call "%nxpimage%" cert-block export -c "%SPT_WORKSPACE%\keys\IMG4_1_cert_block.yaml"
if errorlevel 1 (
    popd
    exit /B 2
)

popd