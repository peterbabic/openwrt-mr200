#!/bin/bash

version="19.07.7"
fprintUrl="https://openwrt.org/docs/guide-user/security/signatures"
dlUrl="https://downloads.openwrt.org/releases/$version/targets/ramips/mt7620/"
folderName="openwrt-imagebuilder-$version-ramips-mt7620.Linux-x86_64"
archive="$folderName.tar.xz"

mkdir -p tmp/ build/
cd tmp/

sudo pacman -q -S --needed base-devel ncurses zlib gawk git gettext openssl libxslt wget unzip python gnupg

sumsFile="sha256sums"
ascFile="$sumsFile.asc"

wget -q "$dlUrl/$ascFile" -O "$ascFile"
wget -q "$dlUrl/$sumsFile" -O "$sumsFile"

gpgOutput=$(gpg --status-fd 1 --auto-key-retrieve --with-fingerprint --verify "$ascFile") 

if [ $? -eq 0 ]; then
	echo "SIGNATURE VERIFIED"
else
	echo "SIGNATURE INVALID. Exiting."
	exit 1
fi

fprint=$(echo "$gpgOutput" | grep -m1 "KEY_CONSIDERED" | cut -d' ' -f3)
fprintFmt=$(echo "$fprint" | sed 's/.\{4\}/& /g' | xargs | sed 's/.\{25\}/& /g')

curl -s "$fprintUrl" | grep -o "$fprintFmt"

if [ $? -eq 0 ]; then
	echo "FINGERPRINT VERIFIED"
else
	echo "FINGERPRINT INVALID. Exiting."
	exit 1
fi

sysupgradeFile="openwrt-$version-ramips-mt7620-ArcherMR200-squashfs-sysupgrade.bin"

## Note: it is possible to download a release sysupgrade file here,
## and consecutively get sha256sums verified,
## but it will later get replaced by `cp "bin/targets/ ...`
# wget -nc "$dlUrl/$sysupgradeFile" -O "$sysupgradeFile"
wget -nc "$dlUrl/$archive" -O "$archive"

sha256sum --ignore-missing -c "$sumsFile" 

if [ $? -eq 0 ]; then
	echo "SHA256SUM VERIFIED"
else
	echo "SHA256SUM INVALID. Exiting."
	rm -rf "$folderName"
	exit 1
fi

if [ ! -d "$folderName" ]; then
	tar xJf "$archive"
fi

cd "$folderName"
ln -sf ../../files .
make image PROFILE=ArcherMR200 PACKAGES="curl luci" FILES=files/

cp "bin/targets/ramips/mt7620/$sysupgradeFile" ../../build/
cd ../../build/

bootloaderFile="ArcherMR200_bootloader.bin"
recoveryFile="ArcherC2V1_tp_recovery.bin"
stockFirmware="../firmware/Archer MR200v1_0.9.1_1.2_up_boot_v004a.0 Build 180502 Rel.53881n.bin"

dd bs=512 obs=512 skip=1 count=256 if="$stockFirmware" of="$bootloaderFile"
cat "$bootloaderFile" "$sysupgradeFile" > "$recoveryFile"

atftpDir="/srv/atftp"
sudo pacman -S --needed atftp
sudo mkdir -p "$atftpDir"
sudo cp "$recoveryFile" "$atftpDir"
sudo chown -R atftp:atftp "$atftpDir"
sudo ifconfig enp0s31f6 192.168.0.66/23
sudo systemctl start atftpd.service

echo "Now connect the MR200 router via LAN1 and restart it while holding WPS button."

 
