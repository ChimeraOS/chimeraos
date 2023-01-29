#! /bin/bash

set -e
set -x

# build own PKGBUILDs and install them before anything else
mkdir -p /tmp/src
chown -R "${BUILD_USER}" /tmp/src

for package in /pkgs/*; do
    echo "Building ${package}"
    PIKAUR_CMD="PKGDEST=${package} SRCDEST=/tmp/src/ \
		pikaur --noconfirm -S -P ${package}/PKGBUILD"
    chown -R "${BUILD_USER}" "${package}"
    PIKAUR_RUN=(su "${BUILD_USER}" -c "${PIKAUR_CMD}")
	"${PIKAUR_RUN[@]}"
done
rm -rf /tmp/src