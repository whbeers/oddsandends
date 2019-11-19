A few scripts I threw together to automate portions of setting up a pile of Raspberry Pi 4s with an SSD rootfs. 

I'm guessing none of this will be necessary anymore once the RPI4 firmware is updated to support boot from USB devices.

Assumptions:
 - Scripts are run from a workstation running a modern Ubuntu with automount at `/media/$USERNAME/[label]`.
 - Raspbian is being used on the Raspberry Pis.
 - Raspberry Pis are using automatic DHCP-based wired addresses. These scripts don't assist in any way with network configuration.

Equipment needed for each RPI:
 - SD Card
 - SSD
 - Your favorite USB3-SATA (or USB3-NVME) adapter. Tip: Try it out under Raspbian beforehand, and tweak the usb-storage.quirks kernel parameter and/or modprobe blacklist file to suit if you run into issues (poor performance, errors in dmesg) with UAS.


Before running these scripts:
 1. Write a Raspbian image to each SSD and SD card (using dd or whatnot).
 1. Use gparted to remove the `boot` partition from the SSD, relabel the `rootfs` partition to `ssdroot`, and resize it to fill the disk. [TODO: script this part.]

Running the scripts (for each SSD+SD card pair):
 1. Unplug and plug in the SSD and SD card to ensure the kernel has re-read the partition tables.
 1. Run both `update-partuuid-sdcard.sh` and `update-partuuid-ssd.sh` to generate and write random PARTUUIDs.
 1. Unplug/plug in again, and ensure all three partitions are mounted (`boot` and `rootfs` from the SD card; `ssdroot` from the SSD)
 1. Run `bind-ssd-to-sdcard.sh`
 1. Insert the SD card and attach the SSD to the RPI. Because the cmdline.txt on the SDCard references the PARTUUID of the SSD, mismatched SSD/SD cards will not boot.
