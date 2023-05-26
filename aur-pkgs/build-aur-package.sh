#!/bin/bash

set -e
set -x

source manifest;

sudo mkdir -p /workdir/aur-pkgs
sudo chown build:build /workdir/aur-pkgs

PIKAUR_CMD="PKGDEST=/workdir/aur-pkgs pikaur --noconfirm -Sw ${1}"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
"${PIKAUR_RUN[@]}"
# remove any epoch (:) in name, replace with -- since not allowed in artifacts
find /workdir/aur-pkgs/*.pkg.tar* -type f -name '*:*' -execdir bash -c 'mv "$1" "${1//:/--}"' bash {} \;