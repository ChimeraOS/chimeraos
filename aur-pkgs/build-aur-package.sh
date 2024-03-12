#!/bin/bash

set -e
set -x

source manifest;

sudo mkdir -p /temp/package
sudo chown build:build /temp/package
sudo chown build:build /workdir/aur-pkgs

git clone --depth=1 https://aur.archlinux.org/${1}.git /temp/package

PIKAUR_CMD="PKGDEST=/workdir/aur-pkgs pikaur --noconfirm --build-gpgdir /etc/pacman.d/gnupg -S -P /temp/package/PKGBUILD"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
"${PIKAUR_RUN[@]}"
# if aur package is not successfully built, exit
if [ $? -ne 0 ]; then
    echo "Build failed. Stopping..."
    exit -1
fi
# remove any epoch (:) in name, replace with -- since not allowed in artifacts
find /workdir/aur-pkgs/*.pkg.tar* -type f -name '*:*' -execdir bash -c 'mv "$1" "${1//:/--}"' bash {} \;