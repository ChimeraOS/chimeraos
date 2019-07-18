#! /bin/bash

FRZR_VERSION=0.0.2
FRZR_RELEASE=1

FRZR_PKG=frzr-${FRZR_VERSION}-${FRZR_RELEASE}-x86_64.pkg.tar


wget "https://github.com/gamer-os/frzr/releases/download/${FRZR_VERSION}/${FRZR_PKG}"

pacman -Sy
pacman --noconfirm -U ${FRZR_PKG}
rm ${FRZR_PKG}

if [ -z "$1" ]; then
	frzr-bootstrap
fi

frzr-bootstrap $1 gamer
frzr-deploy https://gamer-os.github.io/repo/gameros
