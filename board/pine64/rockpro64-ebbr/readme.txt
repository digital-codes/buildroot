Introduction
============

The rockpro64_ebbr_defconfig is meant to illustrate some aspects of the Arm EBBR
specification[1] and the Arm SystemReady Devicetree band[2].
It allows building an AArch64 disk image with a U-Boot based firmware
implementing the subset of UEFI defined by EBBR, as well as a Linux OS booting
with UEFI, to run on the PINE64 ROCKPro64. [3]

Building
========

  $ make rockpro64_ebbr_defconfig
  $ make

Generated files under output/images:

* disk.img: An eMMC or SD card disk image comprising TF-A, OP-TEE, the U-Boot
  bootloader, the GRUB bootloader, the Linux kernel and the root filesystem.

* u-boot-rockchip-spi.bin: A firmware image suitable for flashing in SPI NOR
  comprising TF-A, OP-TEE and the U-Boot bootloader (also included in the
  root filesystem).

Running
=======

Create a bootable SD card:

  # dd if=output/images/disk.img of=<sdcard device> ; sync

Connect to the UART console; the pin layout for serial console on PI-2 GPIO Bus
is as follows:

  Pin  Signal
  ---  ------
    6  GND
    8  Tx out of RK3399
   10  Rx into RK3399

Voltage is 3V3, baudrate is 1500000.

If necessary, connect a jumper between pins 23 and 25 to force SD card boot. [4]

Flashing the firmware to SPI NOR
--------------------------------

It is possible to flash the firmware into the embedded SPI NOR, which makes the
SD card fully available to the OS and also allows to boot from USB2 or NVMe.

The SPI image and the mtd tools are included in the root filesystem; flash the
firmware from Linux with the following command:

  # flashcp -v /lib/firmware/u-boot-rockchip-spi.bin /dev/mtd0

With the firmware in SPI NOR, it is possible to install or run another OS
supporting the EBBR specification.

The image generated by the aarch64_efi_defconfig, the images from Linux
distributions such as Debian, Fedora, openSUSE or Ubuntu, and the Arm ACS
Devicetree images[5] are examples of compatible OS images.

Firmware details
================

Noteworthy firmware features:

- TF-A, OP-TEE & U-Boot
- UEFI, with EFI variables stored on disk in the ESP
- Support for ethernet, USB2 and NVMe
- RTC emulation
- U-Boot environment in SPI NOR

Architecture diagram:

              Non-Secure       :   Secure
                               :
       +---------------------+ :
  EL0  |       Busybox       | :
       +---------------------+ : +--------+
  EL1  | U-Boot, GRUB, Linux | : | OP-TEE |  S-EL1
       +---------------------+ : +--------+
  .............................:
       +----------------------------------+
       |    ROM, U-Boot TPL, SPL, TF-A    |  EL3
       +----------------------------------+

Boot flow:

  ROM -+-> TPL
       `-> SPL -> TF-A -+-> OP-TEE
                        `-> U-Boot -> GRUB -> Linux -> Busybox

The ROM loads U-Boot TPL and SPL. [7][8]
U-Boot TPL does the DRAM setup, goes back to the ROM, which calls SPL.
U-Boot SPL loads the fit image with TF-A, OP-TEE, U-Boot and the Devicetree.
OP-TEE amends the Devicetree, calls back TF-A to go to normal world.
U-Boot loads GRUB with UEFI, boots Linux.

Miscellaneous
=============

This configuration is inspired by the rockpro64_defconfig, the other
configurations related with EBBR and the Arm SystemReady Devicetree Band
Integration and Testing Guide[6].

Firmware update, eMMC and battery-backed RTC are currently not supported.

[1] https://github.com/ARM-software/ebbr
[2] https://www.arm.com/architecture/system-architectures/systemready-compliance-program/systemready-devicetree-band
[3] https://www.pine64.org/rockpro64/
[4] https://pine64.org/documentation/ROCKPro64/Getting_started/
[5] https://github.com/ARM-software/arm-systemready/tree/main/SystemReady-devicetree-band/prebuilt_images
[6] https://developer.arm.com/documentation/DUI1101/latest/
[7] https://wiki.pine64.org/wiki/RK3399_boot_sequence
[8] https://opensource.rock-chips.com/wiki_Boot_option
