#!/bin/bash

version="19.07.7"
fprintUrl="https://openwrt.org/docs/guide-user/security/signatures"
dlUrl="https://downloads.openwrt.org/releases/$version/targets/ramips/mt7620/"
folderName="openwrt-imagebuilder-$version-ramips-mt7620.Linux-x86_64"

mkdir -p tmp/ build/
cd tmp/

sudo pacman -q -S --needed base-devel ncurses zlib gawk git gettext openssl libxslt wget unzip python gnupg

sumsFile="sha256sums"
ascFile="$sumsFile.asc"

rm $sumsFile*
wget -q "$dlUrl/$sumsFile"
wget -q "$dlUrl/$ascFile"

gpgOutput=$(gpg --status-fd 1 --auto-key-retrieve --with-fingerprint --verify "$ascFile") 

if [ $? -eq 0 ]; then
	echo "SIGNATURE VERIFIED"
else
	exit 1
fi

fprint=$(echo "$gpgOutput" | grep -m1 "KEY_CONSIDERED" | cut -d' ' -f3)
fprintFmt=$(echo "$fprint" | sed 's/.\{4\}/& /g' | xargs | sed 's/.\{25\}/& /g')

curl -s "$fprintUrl" | grep -o "$fprintFmt"

if [ $? -eq 0 ]; then
	echo "FINGERPRINT VERIFIED"
else
	exit 1
fi

sha256sum --ignore-missing -c "$sumsFile" 

if [ $? -eq 0 ]; then
	echo "SHA256SUM VERIFIED, no need to redownload"
else
	rm -rf $folderName*
	archive="$folderName.tar.xz"
	wget "$dlUrl/$archive"
	tar xJf "$archive"
fi

cd "$folderName"
ln -sf ../../files .
make image PROFILE=ArcherMR200 PACKAGES="curl" FILES=files/

imageName="openwrt-$version-ramips-mt7620-ArcherMR200-squashfs-sysupgrade.bin"
cp "bin/targets/ramips/mt7620/$imageName" ../../build/

cd ../../
 