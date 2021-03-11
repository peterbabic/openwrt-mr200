# OpenWRT for TP-Link MR200v1

Turn on the device while pushing the WPS button until the WPS light turns
on. At that point, the bootloaders integrated tftp client with the ip
address of 192.168.1.1, tries to connect to a tftp server running at
address 192.168.0.66 and getting the file named ArcherC2V1_tp_recovery.bin.
so you need to be running a tftp server with the ip/netmask of
192.168.0.66/23 and connect it to lan port1. It is vital that your firmware
includes the bootloader at the very beginning (without any extra tp-link
header) as the bootloader will start writing the firmware to flash with the
starting address of 0x00000000.

```bash
cd firmware
dd bs=512 obs=512 skip=1 count=256 if=Archer\ MR200v1_0.9.1_1.2_up_boot_v004a.0\ Build\ 180502\ Rel.53881n.bin of=ArcherMR200_bootloader.bin
cat ArcherMR200_bootloader.bin openwrt-19.07.6-ramips-mt7620-ArcherMR200-squashfs-sysupgrade.bin > ArcherC2V1_tp_recovery.bin
```

More at MR200 OpenWRT
[manual](https://openwrt.org/toh/tp-link/archer-mr200).

## Revert to TP-Link stock firmware

**Important:** Always revert back to the same version in which you switched
from.

```bash
cd firmware
dd bs=512 obs=512 skip=257 count=15744 if=Archer\ MR200v1_0.9.1_1.2_up_boot_v004a.0\ Build\ 180502\ Rel.53881n.bin of=extracted_firmware.bin
scp extracted_firmware.bin root@openwrt:/tmp
/usr/bin/ssh root@openwrt
mtd -r write stock.bin firmware
```

## 4G signal LED integration

OpenWRT does not enable working LED's for 4G signal by default. Manual
method:

```bash
cd files
scp -r root etc root@openwrt:/
/usr/bin/ssh root@openwrt
opkg update
opkg install curl
reboot
```

## Custom image with built in LED signal integration

```bash
pacman -S --needed base-devel ncurses zlib gawk git gettext openssl libxslt wget unzip python
wget https://downloads.openwrt.org/snapshots/targets/ramips/mt7620/openwrt-imagebuilder-ramips-mt7620.Linux-x86_64.tar.xz
tar xJf openwrt-imagebuilder-ramips-mt7620.Linux-x86_64.tar.xz
cd openwrt-imagebuilder-ramips-mt7620.Linux-x86_64
ln -s ../files .
make image PROFILE=tplink_archer-mr200 PACKAGES="curl" FILES=files/
```

The sysupgrade
[file](./openwrt-imagebuilder-ramips-mt7620.Linux-x86_64/bin/targets/ramips/mt7620/openwrt-ramips-mt7620-tplink_archer-mr200-squashfs-sysupgrade.bin)
is available at
`openwrt-imagebuilder-ramips-mt7620.Linux-x86_64/bin/targets/ramips/mt7620/openwrt-ramips-mt7620-tplink_archer-mr200-squashfs-sysupgrade.bin`
and includes `curl` and the LED script.

## Credit

The authors of the LED script are users **asenac** and **spamcop**,
published ad OpenWRT
[forum](https://forum.openwrt.org/t/signal-strength-and-4g-leds-on-tp-link-mr200/65978)
