#!/bin/bash

set -e
set -x

cp -rv /packages /tmp/pkgs
sudo mkdir -p /pkgs
sudo chown build:build /pkgs
for package in /tmp/pkgs/*/; do
	echo "Building ${package}"
	PIKAUR_CMD="PKGDEST=/pkgs \
		pikaur --noconfirm -S -P ${package}/PKGBUILD"
	PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
	"${PIKAUR_RUN[@]}"
done
