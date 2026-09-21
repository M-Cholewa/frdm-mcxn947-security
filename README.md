# FRDM-MCXN947 — Zephyr Security Project

Firmware project for the NXP FRDM-MCXN947 development board based on Zephyr RTOS.

The goal of this project is to develop a custom firmware application and systematically investigate and test the security features available on the MCXN947 microcontroller.

## Hardware

* NXP FRDM-MCXN947
* MCU: NXP MCXN947

## Development Environment

* Windows
* NXP MCUXpresso IDE
* NXP LinkServer
* Zephyr RTOS
* Zephyr SDK
* VS Code
* Python
* West

## Initial Setup

### 1. MCUXpresso

NXP MCUXpresso IDE was installed together with the required NXP development and debugging tools.

LinkServer is used for programming and communicating with the development board.

### 2. Zephyr

Zephyr RTOS was installed following the official Zephyr documentation.

The Zephyr workspace is kept separately from the application source code.

The application project is maintained independently in:

```text
FW/
```

This keeps the application source code separate from the Zephyr workspace.

### 3. Zephyr SDK

The Zephyr SDK was installed and configured to provide the required toolchain for building Zephyr applications.

### 4. First Test

The Zephyr `blinky` sample application was built and flashed first to verify that the development environment was working correctly.

This verified:

* Zephyr installation
* Toolchain
* Zephyr SDK
* Board support
* Build process
* Flashing process
* Communication with the development board

The test was successful.

### 5. Custom Zephyr Application

After verifying the development environment, a custom Zephyr application was created from scratch without using an existing application example as the project base.

Current project structure:

```text
FW/
├── .gitignore
├── README.md
├── CMakeLists.txt
├── prj.conf
├── sysbuild.conf
├── build.ps1
└── src/
    └── main.c
```

The application is built for:

```text
frdm_mcxn947/mcxn947/cpu0
```

The firmware was successfully compiled and flashed to the MCXN947.

### 6. UART

UART communication with the development board was verified.

Current serial configuration:

```text
COM3
115200 baud
8N1
```

The firmware successfully outputs the Zephyr boot message and the application message:

```text
Hello World from my own MCXN947 project!
```

## Configuration

The `build.ps1` script contains local paths required by the development environment.

Before using this project on another computer, update the following values in `build.ps1`:

```powershell
$env:ZEPHYR_BASE = "C:\Users\name\zephyrproject\zephyr"

$env:Path += ";E:\MCUXpressoIDE_25.6.136\ide\LinkServer"
```

`ZEPHYR_BASE` must point to the local Zephyr repository.

The LinkServer path must point to the `LinkServer` directory installed with MCUXpresso.

The serial port can also be changed if the development board is assigned a different COM port:

```powershell
$SERIAL_PORT = "COM3"
```

The default baud rate is:

```powershell
$BAUD_RATE = "115200"
```

These settings are intentionally kept in the script so the project can be built, flashed and monitored without manually configuring environment variables in every terminal session.

## Build

Build the project using:

```powershell
.\build.ps1 build
```

## Flash

Build and flash the firmware:

```powershell
.\build.ps1 flash
```

## Serial Monitor

Start the UART monitor:

```powershell
.\build.ps1 monitor
```

The monitor uses:

```text
COM3
115200 8N1
```

The terminal is provided by Python `pyserial`.

## Flash and Monitor

The complete development cycle can be performed with:

```powershell
.\build.ps1 flash-monitor
```

This command:

1. Builds the application.
2. Flashes the firmware to the board.
3. Starts the serial monitor.

To exit the serial monitor, press:

```text
Ctrl+]
```

## Clean Build

To remove the generated build directory:

```powershell
.\build.ps1 clean
```

## Security Testing

The next stage of the project is to systematically investigate and test the security features available on the MCXN947.

The planned work includes:

* Secure Boot
* MCUboot
* Firmware signing
* Signature verification
* Protection against modified firmware
* Invalid signature testing
* Wrong public key testing
* Cryptographic hardware features
* Memory protection mechanisms
* Access control mechanisms
* Debug and security lifecycle features
* Other security features available on the MCXN947

Each security mechanism will be investigated and tested individually.

The results, configuration, test procedure, and observations will be documented in this repository.

## Project Status

* [x] MCUXpresso IDE
* [x] LinkServer
* [x] Zephyr RTOS
* [x] Zephyr SDK
* [x] Zephyr sample application
* [x] Custom Zephyr application
* [x] Build
* [x] Flash
* [x] UART
* [ ] MCUboot
* [ ] Firmware signing
* [ ] Secure Boot
* [ ] Security feature testing
