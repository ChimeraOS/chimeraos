#! /bin/bash

set -e
set -x

source manifest

# Allow multiple downloads
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
# set archive date if specified and force update/downgrade builder
if [ -n "${ARCHIVE_DATE}" ]; then
	echo "
	Server=https://archive.archlinux.org/repos/${ARCHIVE_DATE}/\$repo/os/\$arch
	" > /etc/pacman.d/mirrorlist
fi
# download package overrides
mkdir /tmp/extra_pkgs
if [ -n "${PACKAGE_OVERRIDES}" ]; then
	wget --directory-prefix=/tmp/extra_pkgs ${PACKAGE_OVERRIDES}
fi

# Update system and install pikaur and other build dependencies
echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf
	pacman --noconfirm -Syyuu && \
	# install package overrides for use during build
	pacman --noconfirm -U --overwrite '*' /tmp/extra_pkgs/* && \
	pacman --noconfirm -S \
		arch-install-scripts \
		btrfs-progs \
		pyalpm sudo \
		wget \
		xcb-util-wm \
		fmt \
		python-markdown-it-py \
		python-wheel \
		python-build \
		python-installer \
		python-setuptools \
	pacman --noconfirm -S --needed git
	echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	useradd build -G wheel -m
	su - build -c "git clone https://aur.archlinux.org/pikaur.git /tmp/pikaur"
	su - build -c "cd /tmp/pikaur && makepkg -f"
	pacman --noconfirm -U /tmp/pikaur/pikaur-*.pkg.tar.zst

# Add a fake systemd-run script to workaround pikaur requirement.
echo -e "#!/bin/bash\nif [[ \"$1\" == \"--version\" ]]; then echo 'fake 244 version'; fi\nmkdir -p /var/cache/pikaur\n" >> /usr/bin/systemd-run
chmod +x /usr/bin/systemd-run

# Only run reflector when not using archive packages
if [ -z "${ARCHIVE_DATE}" ]; then
    pacman -S --noconfirm reflector
    reflector --verbose --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
fi