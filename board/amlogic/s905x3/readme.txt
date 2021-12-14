Amlogic S905X3

Intro
=====

Amlogic A95x F3 AIR is a low cost Android STB based around an Amlogic s905(x) SoC
(quad A55), 64GB eMMC and 4GB RAM.  

s905x3 is supported.

This default configuration will allow you to start experimenting with the
buildroot environment for the A95X.  With the current configuration it will
bring-up the board from microSD, and allow access through the serial
console.

How to build it
===============

Configure Buildroot:

    $ make amlogic_s905x3_defconfig

Compile everything and build the SD card image:

    $ make

How to write the SD card
========================

Once the build process is finished you will have an image called "sdcard.img"
in the output/images/ directory.

Copy the bootable "sdcard.img" onto a microSD card with "dd":

  $ sudo dd if=output/images/sdcard.img of=/dev/sdX

How to boot
===========

Insert microSD card and connect serial cable. Power board pressing reset button at the same time.
