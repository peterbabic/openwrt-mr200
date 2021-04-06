#/bin/bash

sysupgradeUrl="http://downloads.openwrt.org/releases/19.07.7/targets/ramips/mt7620"
sysupgradeFile="openwrt-19.07.7-ramips-mt7620-ArcherMR200-squashfs-sysupgrade.bin"
bootloaderFile="ArcherMR200_bootloader.bin"
recoveryFile="ArcherC2V1_tp_recovery.bin"

dd bs=512 obs=512 skip=1 count=256 if=Archer\ MR200v1_0.9.1_1.2_up_boot_v004a.0\ Build\ 180502\ Rel.53881n.bin of="$bootloaderFile"
cat "$bootloaderFile" "$sysupgradeFile" > "$recoveryFile"

atftpDir="/srv/atftp"
sudo pacman -S atftp
sudo mkdir -p "$atftpDir"
sudo cp "$recoveryFile" "$atftpDir"
sudo chown -R atftp:atftp "$atftpDir"
sudo ifconfig enp0s31f6 192.168.0.66/23
sudo systemctl start atftpd.service

echo "Now connect the MR200 router via LAN1 and restart it while holding WPS button."

