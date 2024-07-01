#!/usr/bin/env bash

while read -r line; do
	if [[ "$line" == 'usr/lib/modules/'+([^/])'/pkgbase' ]]; then
		read -r pkgbase < "/${line}"
		rm -f "/boot/vmlinuz-${pkgbase}"
		rm -f "/boot/initramfs-${pkgbase}.img"
		#rm -f "/boot/initramfs-${pkgbase}-fallback.img"
	fi
done
