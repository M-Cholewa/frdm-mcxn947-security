# ============================================================
# FRDM-MCXN947 - Zephyr build / flash / monitor script
# ============================================================
#
# IMPORTANT:
# Before using this script on another computer, change the
# local paths below to match your environment.
#
# In particular, update:
#   - ZEPHYR_BASE
#   - LinkServer path
#
# These values are intentionally kept here so the project can
# be built without manually setting environment variables.
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# LOCAL PATHS - CHANGE THESE FOR YOUR ENVIRONMENT
# ------------------------------------------------------------

$env:ZEPHYR_BASE = "C:\Users\name\zephyrproject\zephyr"

$env:Path += ";E:\MCUXpressoIDE_25.6.136\ide\LinkServer"

# ------------------------------------------------------------
# PROJECT CONFIGURATION
# ------------------------------------------------------------

$BOARD = "frdm_mcxn947/mcxn947/cpu0"

$SERIAL_PORT = "COM3"
$BAUD_RATE = "115200"

# ------------------------------------------------------------
# COMMAND LINE
# ------------------------------------------------------------

if ($args.Count -eq 0) {
    Write-Host ""
    Write-Host "FRDM-MCXN947 Zephyr project"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\build.ps1 build"
    Write-Host "  .\build.ps1 flash"
    Write-Host "  .\build.ps1 monitor"
    Write-Host "  .\build.ps1 flash-monitor"
    Write-Host "  .\build.ps1 clean"
    Write-Host ""
    exit 0
}

switch ($args[0]) {

    # --------------------------------------------------------
    # BUILD
    # --------------------------------------------------------

    "build" {
        Write-Host ""
        Write-Host "=== Building Zephyr application ==="
        Write-Host ""

        west build -b $BOARD --sysbuild
    }

    # --------------------------------------------------------
    # FLASH
    # --------------------------------------------------------

    "flash" {
        Write-Host ""
        Write-Host "=== Building and flashing Zephyr application ==="
        Write-Host ""

        west build -b $BOARD --sysbuild
        west flash -d build
    }

    # --------------------------------------------------------
    # SERIAL MONITOR
    # --------------------------------------------------------

    "monitor" {
        Write-Host ""
        Write-Host "=== Starting serial monitor ==="
        Write-Host ""
        Write-Host "Port: $SERIAL_PORT"
        Write-Host "Baud: $BAUD_RATE"
        Write-Host ""
        Write-Host "Press Ctrl+] to exit miniterm."
        Write-Host ""

        python -m serial.tools.miniterm $SERIAL_PORT $BAUD_RATE
    }

    # --------------------------------------------------------
    # FLASH + SERIAL MONITOR
    # --------------------------------------------------------

    "flash-monitor" {
        Write-Host ""
        Write-Host "=== Building and flashing Zephyr application ==="
        Write-Host ""

        west build -b $BOARD --sysbuild
        west flash -d build

        Write-Host ""
        Write-Host "=== Starting serial monitor ==="
        Write-Host ""
        Write-Host "Port: $SERIAL_PORT"
        Write-Host "Baud: $BAUD_RATE"
        Write-Host ""
        Write-Host "Press Ctrl+] to exit miniterm."
        Write-Host ""

        python -m serial.tools.miniterm $SERIAL_PORT $BAUD_RATE
    }

    # --------------------------------------------------------
    # CLEAN
    # --------------------------------------------------------

    "clean" {
        Write-Host ""
        Write-Host "=== Removing build directory ==="
        Write-Host ""

        if (Test-Path "build") {
            Remove-Item -Recurse -Force "build"
            Write-Host "Build directory removed."
        }
        else {
            Write-Host "Build directory does not exist."
        }
    }

    # --------------------------------------------------------
    # UNKNOWN COMMAND
    # --------------------------------------------------------

    default {
        Write-Host ""
        Write-Host "Unknown command: $($args[0])"
        Write-Host ""
        Write-Host "Available commands:"
        Write-Host "  .\build.ps1 build"
        Write-Host "  .\build.ps1 flash"
        Write-Host "  .\build.ps1 monitor"
        Write-Host "  .\build.ps1 flash-monitor"
        Write-Host "  .\build.ps1 clean"
        Write-Host ""

        exit 1
    }
}