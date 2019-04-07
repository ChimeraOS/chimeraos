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
if [[ -d /sys/firmware/efi && -z $FORCE_BIOS ]]; then
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


# detect gpu (cannot be done in chroot)
if lspci | grep -E -i '(vga|3d|display)' | grep -i nvidia > /dev/null; then
	GPU=nvidia
elif lspci | grep -E -i '(vga|3d|display)' | grep -i amd > /dev/null; then
	if lspci -nnk | grep -i vga -A3 | grep 'Kernel modules: radeon, amdgpu' > /dev/null; then
		GPU=amd_radeon
	elif lspci -nnk | grep -i vga -A3 | grep 'Kernel modules: amdgpu' > /dev/null; then
		GPU=amdgpu
	else
		GPU=amd_legacy
	fi
elif lspci | grep -E -i '(vga|3d|display)' | grep -i intel > /dev/null; then
	GPU=intel
fi


# chroot into target
pacstrap ${MOUNT_PATH} base
arch-chroot ${MOUNT_PATH} /bin/bash <<EOF
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# initialize kernel module configuration file
echo > /etc/modprobe.d/gameros.conf

# adding multilib to pacman mirror list
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist
" >> /etc/pacman.conf

# update package databases
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
	pulseaudio-alsa \
	sudo \
	python \
	efibootmgr \
	grub \
	steam

systemctl enable NetworkManager lightdm bluetooth

# gpu driver installation
if [ "$GPU" = "nvidia" ]; then
	echo "NVIDIA GPU detected, installing drivers..."
	pacman --noconfirm -S \
		nvidia \
		opencl-nvidia \
		lib32-opencl-nvidia \
		nvidia-utils \
		lib32-nvidia-utils
elif [ "$GPU" = "amd_radeon" ]; then
	echo "AMD graphics card with radeon kernel module detected, switching kernel module and installing drivers..."
	echo "blacklist radeon" >> /etc/modprobe.d/gameros.conf
	echo "options amdgpu si_support=1" >> /etc/modprobe.d/gameros.conf
	echo "options amdgpu cik_support=1" >> /etc/modprobe.d/gameros.conf
	echo "options radeon si_support=0" >> /etc/modprobe.d/gameros.conf
	echo "options radeon cik_support=0" >> /etc/modprobe.d/gameros.conf
	pacman --noconfirm -S \
		vulkan-icd-loader \
		lib32-vulkan-icd-loader \
		libva-mesa-driver \
		lib32-libva-mesa-driver \
		mesa-vdpau \
		lib32-mesa-vdpau \
		vulkan-radeon \
		lib32-vulkan-radeon \
		xf86-video-amdgpu
elif [ "$GPU" = "amdgpu" ]; then
	echo "AMD graphics card with amdgpu kernel module detected, installing drivers..."
	pacman --noconfirm -S \
		vulkan-icd-loader \
		lib32-vulkan-icd-loader \
		libva-mesa-driver \
		lib32-libva-mesa-driver \
		mesa-vdpau \
		lib32-mesa-vdpau \
		vulkan-radeon \
		lib32-vulkan-radeon \
		xf86-video-amdgpu
elif [ "$GPU" = "amd_legacy" ]; then
	echo "Legacy AMD/ATI GPU detected, installing drivers..."
	pacman --noconfirm -S \
		xf86-video-ati \
		mesa-vdpau \
		lib32-mesa-vdpau
elif [ "$GPU" = "intel" ]; then
	echo "Intel GPU detected, installing drivers..."
	pacman --noconfirm -S \
		vulkan-intel \
		lib32-vulkan-intel \
		libva-intel-driver \
		lib32-libva-intel-driver \
		xf86-video-intel \
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
useradd -m ${USERNAME} -G autologin,wheel
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

echo "
polkit.addRule(function(action, subject) {
	if ((action.id == \"org.freedesktop.timedate1.set-time\" ||
	     action.id == \"org.freedesktop.timedate1.set-timezone\" ||
	     action.id == \"org.freedesktop.login1.power-off\" ||
	     action.id == \"org.freedesktop.login1.reboot\") &&
	     subject.isInGroup(\"wheel\")) {
		return polkit.Result.YES;
	}
});
" > /etc/polkit-1/rules.d/49-gameros.rules

echo "${SYSTEM_NAME}" > /etc/hostname

# steam controller fix
echo "blacklist hid_steam" >> /etc/modprobe.d/gameros.conf

# enable bluetooth connection for xbox one s controller
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="bluetooth.disable_ertm=1"/' /etc/default/grub

# build initial ramdisk and install bootloader
mkinitcpio -p linux

if [[ -d /sys/firmware/efi && -z $FORCE_BIOS ]]; then
	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=${SYSTEM_NAME}
else
	grub-install --target=i386-pc ${DISK}
fi

grub-mkconfig -o /boot/grub/grub.cfg

EOF
