#!/usr/bin/env bash

args=('--force' '--strip' '--aggressive-strip' '--reproducible')

while read -r line; do
	if [[ "$line" == 'usr/lib/modules/'+([^/])'/pkgbase' ]]; then
		read -r pkgbase < "/${line}"
		kver="${line#'usr/lib/modules/'}"
		kver="${kver%'/pkgbase'}"

		install -Dm0644 "/${line%'/pkgbase'}/vmlinuz" "/boot/vmlinuz-${pkgbase}"
		dracut --no-hostonly --no-hostonly-cmdline "${args[@]}" "/boot/initramfs-${pkgbase}.img" --kver "$kver"
		#dracut --no-hostonly "${args[@]}" "/boot/initramfs-${pkgbase}-fallback.img" --kver "$kver"
	fi
done