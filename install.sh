#! /bin/bash

set -e

export USERNAME=gamer
export SYSTEM_NAME=gamer-os

export MOUNT_PATH=/tmp/${SYSTEM_NAME}

if [ -z $1 ]; then
	echo "No install disk specified. Please specify a disk from one of the following:"
	lsblk -p | grep disk | tr -s ' ' | cut -d' ' -f 1
	exit
fi

export DISK=$1

if ! file ${DISK} | grep block > /dev/null; then
	echo "${DISK} is not a valid disk. Please specify a disk from one of the following:"
	lsblk -p | grep disk | tr -s ' ' | cut -d' ' -f 1
	exit
fi

read -p "WARNING: ${DISK} will now be formatted. All data on the disk will be lost. Do you wish to proceed? (y/n)" -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "Aborting install"
	exit
fi

if find /sys/firmware/efi -mindepth 1 | read; then
	parted --script ${DISK} \
	mklabel gpt \
	mkpart primary 1MiB 512MiB \
	mkpart primary 512MiB 100%
	mkfs.ext4 -F ${DISK}2
	mkfs.fat -F32 ${DISK}1
	mkdir -p ${MOUNT_PATH}
	mount ${DISK}2 ${MOUNT_PATH}
	mkdir -p ${MOUNT_PATH}/boot/efi
	mount ${DISK}1 ${MOUNT_PATH}/boot/efi
else
	 echo 'label: mbr' | sfdisk ${DISK}
	 echo 'start=2048, type=83' | sfdisk ${DISK}
	 mkfs.ext4 -F ${DISK}1
	 mkdir -p ${MOUNT_PATH}
	 mount ${DISK}1 ${MOUNT_PATH}
fi

pacstrap ${MOUNT_PATH} base ntfs-3g ntp linux-headers-$(uname -r)
arch-chroot ${MOUNT_PATH} /bin/bash <<EOF
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

mkinitcpio -p linux

if find /sys/firmware/efi -mindepth 1 | read; then
	pacman --noconfirm -S \
	efibootmgr \
	grub
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gamer_OS
	grub-mkconfig -o /boot/grub/grub.cfg
else
	pacman --noconfirm -S \
	grub
	grub-install --target=i386-pc ${DISK}
	grub-mkconfig -o /boot/grub/grub.cfg
fi

# enable bluetooth connection for xbox one s controller
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="bluetooth.disable_ertm=1"/' /etc/default/grub


echo "
[multilib]
Include = /etc/pacman.d/mirrorlist
" >> /etc/pacman.conf

pacman --noconfirm -Sy
pacman --noconfirm -S \
	lightdm \
	accountsservice \
	xorg-server \
	bluez \
	bluez-utils \
	lib32-freetype2 \
	lib32-curl \
	lib32-libgpg-error \
	ttf-dejavu \
	networkmanager \
	pulseaudio \
	lib32-libpulse \
	sudo \
	python \
	vulkan-icd-loader \
	lib32-vulkan-icd-loader \
	steam

# install NVIDIA graphics driver
if lspci | grep -E -i '(vga|3d)' | grep -i nvidia > /dev/null; then
	pacman --noconfirm -S nvidia nvidia-utils lib32-nvidia-utils
fi

# install AMD graphics driver with support for video acceleration
if lspci | grep -E -i '(vga|3d)' | grep -i AMD > /dev/null; then
	pacman --noconfirm -S mesa vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu lib32-mesa libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau
fi

# install Intel graphics driver with support for video acceleration
if lspci | grep -E -i '(vga|3d)' | grep -i Intel Corporation > /dev/null; then
	pacman --no-confirm -S mesa lib32-mesa xf86-video-intel vulkan-intel lib32-vulkan-intel libva-intel-driver lib32-libva-intel-driver intel-media-driver
fi


systemctl enable NetworkManager lightdm bluetooth ntpd

TIMEZONE="$(curl -s https://ipapi.co/timezone)"
echo "Your timezone is: ${TIMEZONE}"
timedatectl set-timezone ${TIMEZONE}
timedatectl set-ntp 1
echo "Your OS is configured to timezone: ${TIMEZONE}"


# font workaround for initial big picture mode startup
mkdir -p /usr/share/fonts/truetype/ttf-dejavu
ln -s /usr/share/fonts/TTF/DejaVuSans.ttf /usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf

# install steam compositor (no updates!)
curl -LO http://github.com/alkazar/steamos-compositor/releases/download/1.1.1/steamos-compositor-plus-1.1.1-1-x86_64.pkg.tar
pacman --noconfirm -U steamos-compositor-plus-1.1.1-1-x86_64.pkg.tar
rm steamos-compositor-plus-1.1.1-1-x86_64.pkg.tar

passwd -l root # disable root login
groupadd -r autologin
useradd -m ${USERNAME} -G autologin
echo "${USERNAME}:${USERNAME}" | chpasswd
echo "${USERNAME}   ALL=(ALL) ALL" >> /etc/sudoers

echo "
[LightDM]
run-directory=/run/lightdm
[Seat:*]
session-wrapper=/etc/lightdm/Xsession
autologin-user=${USERNAME}
autologin-session=steamos
" > /etc/lightdm/lightdm.conf

echo "${SYSTEM_NAME}" > /etc/hostname

# steam controller fix
echo "blacklist hid_steam" > /etc/modprobe.d/blacklist.conf

#Rebuild RAMdisk and bootloader with fixes

mkinitcpio -p linux
grub-mkconfig -o /boot/grub/grub.cfg

EOF
