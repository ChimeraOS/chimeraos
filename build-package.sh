#! /bin/bash

set -e
set -x
chown -R "${BUILD_USER}" /output
PIKAUR_CMD="PKGDEST=/output pikaur --noconfirm -Sw ${1}"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
if [ -n "${BUILD_USER}" ]; then
	PIKAUR_RUN=(su "${BUILD_USER}" -c "${PIKAUR_CMD}")
fi
"${PIKAUR_RUN[@]}"
chown -R root /output/*
# remove any epoch (:) in name, replace with -- since not allowed in artifacts
find output/*.pkg.tar* -type f -name '*:*' -execdir bash -c 'mv "$1" "${1//:/--}"' bash {} \;