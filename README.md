**## Security Testing**

The security testing phase has started with MCUboot-based firmware authentication.

**### MCUboot**

MCUboot has been integrated into the Zephyr application using Sysbuild.

The configuration enables MCUboot with:

```text
SB_CONFIG_BOOTLOADER_MCUBOOT=y
```

MCUboot was successfully flashed to the MCXN947 and verified to chainload the application.

The bootloader reports the application chainload address:

```text
Bootloader chainload address offset: 0x14000
```

and successfully starts the Zephyr application.

**### Firmware Signing**

Firmware signing has been enabled.

A project-specific RSA-2048 key pair was generated using the MCUboot `imgtool` utility.

The private signing key is stored locally in:

```text
keys/mcuboot-rsa-2048.pem
```

The private key is not intended to be stored in the firmware image or committed to the repository.

Private key files are excluded from Git using:

```text
*.pem
*.key
```

The project configuration points to the project-specific signing key:

```text
SB_CONFIG_BOOT_SIGNATURE_KEY_FILE="C:/Users/name/Desktop/mateus/PROJEKTY/FRDM-MCXN947/keys/mcuboot-rsa-2048.pem"
```

The generated application image includes the MCUboot image header and signature data:

```text
FW/build/FW/zephyr/zephyr.signed.bin
```

The build configuration confirms that the project-specific key is used for image signing.

**### Signature Verification**

The signed firmware was flashed together with MCUboot.

After programming, MCUboot successfully processed the image and chainloaded the application:

```text
I: Bootloader chainload address offset: 0x14000
I: Image version: v0.0.0
I: Jumping to the first image slot

*** Booting Zephyr OS build ...

Hello World from my own MCXN947 project!
```

This confirms the positive boot path:

```text
Build
  ↓
Firmware signing
  ↓
MCUboot
  ↓
Image validation
  ↓
Application
```

**### Modified Firmware Rejection**

A negative security test was performed to verify that modification of a signed firmware image is detected by MCUboot.

First, the known-good signed firmware image was preserved:

```text
FW/build/FW/zephyr/zephyr.signed.original.bin
```

A copy of the signed firmware was then modified by changing a single byte.

The modified image was flashed without rebuilding the application.

During the subsequent boot attempt, MCUboot rejected the modified image:

```text
E: Image in the primary slot is not valid!
E: Unable to find bootable image
```

The application was therefore not chainloaded from the modified image.

The original signed image was then restored. Its SHA-256 hash was verified against the backup:

```text
6B032496CBCE4F0E9768B0731C3957DB6F750B0CD4B30391C7468A909D17810C
```

Both files produced the same hash, confirming that the original signed image had been restored correctly.

**Result: PASS**

This test demonstrates that modifying a signed firmware image causes MCUboot image validation to fail and prevents the modified image from being booted.

**### Root of Trust**

The next stage of the security investigation is the Root of Trust.

The project distinguishes between:

1. The private signing key used to create firmware signatures.
2. The trusted public-key material used by MCUboot to verify firmware signatures.
3. MCUboot as the software boot stage responsible for validating the application image.
4. Hardware security mechanisms that may provide a hardware-enforced trust anchor.

The private signing key remains outside the firmware image and should not be embedded into the application or committed to the repository.

The next investigation will determine how the MCXN947 establishes and protects the initial trust anchor and whether the device provides hardware-enforced Secure Boot functionality.

No irreversible security configuration, OTP programming, lifecycle transition, or security fuse programming will be performed until the available mechanisms and recovery implications are fully understood.

**### Security Tests — Planned**

The following tests are planned:

* Sign firmware with a different RSA key and verify that MCUboot rejects it
* Test an invalid or corrupted signature
* Investigate image version and downgrade protection
* Investigate cryptographic hardware features
* Investigate memory protection mechanisms
* Investigate access control mechanisms
* Investigate debug security and lifecycle states
* Investigate hardware security / Secure Boot capabilities of the MCXN947
* Investigate the hardware Root of Trust and its relationship with the software boot chain
* Document other relevant security features available on the MCXN947

Each security mechanism will be investigated and tested individually.

The results, configuration, test procedure, expected behavior, observed behavior, and conclusions will be documented in this repository.

**## Project Status**

* [x] MCUXpresso IDE
* [x] LinkServer
* [x] Zephyr RTOS
* [x] Zephyr SDK
* [x] Zephyr sample application
* [x] Custom Zephyr application
* [x] Build
* [x] Flash
* [x] UART
* [x] MCUboot
* [x] Firmware signing
* [x] Project-specific RSA-2048 signing key
* [x] Signed firmware successfully booted through MCUboot
* [x] Modified firmware rejection test
* [ ] Invalid signature test
* [ ] Wrong public key / wrong signing key test
* [ ] Image downgrade protection test
* [ ] Hardware cryptographic feature testing
* [ ] Memory protection testing
* [ ] Access control testing
* [ ] Debug/security lifecycle testing
* [ ] Hardware Root of Trust investigation
* [ ] Hardware Secure Boot investigation
* [ ] Other MCXN947 security feature testing
