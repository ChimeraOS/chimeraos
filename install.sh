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

mkdir -p ${MOUNT_PATH}
if [ -d /sys/firmware/efi ]; then
	parted --script ${DISK} \
		mklabel gpt \
		mkpart primary 1mb 512mb \
		mkpart primary 512mb 100%

	mkfs.ext4 -F ${DISK}2
	mount ${DISK}2 ${MOUNT_PATH}

	mkfs.fat -F32 ${DISK}1
	mkdir -p ${MOUNT_PATH}/boot/efi
	mount ${DISK}1 ${MOUNT_PATH}/boot/efi
else
	parted --script ${DISK} \
		mklabel msdos \
		mkpart primary 1mb 100%

	mkfs.ext4 -F ${DISK}1
	mount ${DISK}1 ${MOUNT_PATH}
fi

# chroot into target
pacstrap ${MOUNT_PATH} base
arch-chroot ${MOUNT_PATH} /bin/bash
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# adding multilib to pacman mirror list
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist
" >> /etc/pacman.conf

# system update
pacman --noconfirm -Sy

# basic package installation
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
	vulkan-radeon \
	lib32-vulkan-radeon \
	efibootmgr \
	grub \
	steam

systemctl enable NetworkManager lightdm bluetooth

# gpu detection/driver installation

devices=$(lspci -v | grep -e 'VGA\|3D\|Display')

# NVIDIA
if echo "$devices" | grep -i 'NVIDIA Corporation' > /dev/null; then
 	echo "NVIDIA GPU detected, installing drivers..."
	pacman --noconfirm -S \
		nvidia-dkms \
		nvidia-utils \
		lib32-nvidia-utils

# AMD
elif echo "$devices" | grep -i 'AMD' > /dev/null; then
	echo "AMD GPU with radeon kernel detected, switching kernel module and installing drivers..."
	echo "blacklist radeon" > /etc/modprobe.d/blacklist.conf
	echo "options amdgpu si_support=1" > /etc/modprobe.d/amdgpu.conf
	echo "options amdgpu cik_support=1" >> /etc/modprobe.d/amdgpu.conf
	echo "options radeon si_support=0" > /etc/modprobe.d/radeon.conf
	echo "options radeon cik_support0" >> /etc/modprobe.d/radeon.conf
	pacman --noconfirm -S \
		vulkan-radeon mesa \
		vulkan-icd-loader \
		xf86-video-amdgpu \
		libva-mesa-driver \
		mesa-vdpau \
		lib32-libva-mesa-driver \
		lib32-mesa-vdpau \
		lib32-mesa \
		lib32-vulkan-radeon

# Intel
elif echo "$devices" | grep -i 'Intel Corporation' > /dev/null; then
	echo "Intel GPU detected, installing drivers..."
 	pacman --noconfirm -S \
		mesa \
		lib32-mesa \
		xf86-video-intel \
		vulkan-intel \
		lib32-vulkan-intel \
		libva-intel-driver \
		lib32-libva-intel-driver \
		intel-media-driver

fi

# font workaround for initial big picture mode startup
mkdir -p /usr/share/fonts/truetype/ttf-dejavu
ln -s /usr/share/fonts/TTF/DejaVuSans.ttf /usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf

# install steam compositor (no updates!)
curl -LO http://github.com/alkazar/steamos-compositor/releases/download/1.1.1/steamos-compositor-plus-1.1.1-1-x86_64.pkg.tar
pacman --noconfirm -U steamos-compositor-plus-1.1.1-1-x86_64.pkg.tar
rm steamos-compositor-plus-1.1.1-1-x86_64.pkg.tar

# disable root login
passwd -l root
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

TIMEZONE="$(curl -s https://ipapi.co/timezone)"
echo "Your timezone is: ${TIMEZONE}"
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock -systohc
echo "Your OS is configured to timezone: ${TIMEZONE}"

echo "${SYSTEM_NAME}" > /etc/hostname

# steam controller fix
echo "blacklist hid_steam" >> /etc/modprobe.d/blacklist.conf

# enable bluetooth connection for xbox one s controller
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="bluetooth.disable_ertm=1"/' /etc/default/grub

# install bootloader and rebuild RAMdisk
mkinitcpio -p linux

if [ -d /sys/firmware/efi ]; then
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${SYSTEM_NAME}
else
	grub-install --target=i386-pc ${DISK}
fi

grub-mkconfig -o /boot/grub/grub.cfg
