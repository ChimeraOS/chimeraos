#! /bin/bash

set -e
set -x

SYSTEM_NAME=gameros
USERNAME=gamer

if [ -z "$1" ]; then
  echo "channel must be specified"
  exit
fi

if [ -z "$2" ]; then
  echo "version must be specified"
  exit
fi

CHANNEL=$1
VERSION=$2
PROFILE=default

if [ ! -z "$3" ]; then
  PROFILE="$3"
fi

MOUNT_PATH=/tmp/${CHANNEL}-build
BUILD_PATH=${MOUNT_PATH}/subvolume
SNAP_PATH=${MOUNT_PATH}/${CHANNEL}-${VERSION}
BUILD_IMG=${CHANNEL}-build.img

mkdir -p ${MOUNT_PATH}

source profiles/${PROFILE}

fallocate -l ${SIZE} ${BUILD_IMG}
mkfs.btrfs -f ${BUILD_IMG}
mount -t btrfs -o loop,nodatacow ${BUILD_IMG} ${MOUNT_PATH}
btrfs subvolume create ${BUILD_PATH}

# bootstrap
pacstrap ${BUILD_PATH} base

# build AUR packages to be installed later
rm -rf /var/cache/pikaur/pkg/*
pikaur --noconfirm -Sw ${AUR_PACKAGES}
mkdir ${BUILD_PATH}/aur
mv /var/cache/pikaur/pkg/* ${BUILD_PATH}/aur/

# chroot into target
mount --bind ${BUILD_PATH} ${BUILD_PATH}
arch-chroot ${BUILD_PATH} /bin/bash <<EOF
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# initialize kernel module configuration file
echo > /etc/modprobe.d/${SYSTEM_NAME}.conf

# adding multilib to pacman mirror list
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist
" >> /etc/pacman.conf

# update package databases
pacman --noconfirm -Sy

# install packages
pacman --noconfirm -S ${PACKAGES}

# install AUR packages
pacman --noconfirm -U /aur/*
rm -rf /aur

# record installed packages & versions
pacman -Q > /manifest

# enable services
systemctl enable ${SERVICES}

# disable root login
passwd --lock root

# create user
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
" > /etc/polkit-1/rules.d/49-${SYSTEM_NAME}.rules

echo "${SYSTEM_NAME}" > /etc/hostname

# steam controller fix and amdgpu setup
echo "
blacklist hid_steam
blacklist radeon
options amdgpu si_support=1
options amdgpu cik_support=1
options radeon si_support=0
options radeon cik_support=0
" >> /etc/modprobe.d/${SYSTEM_NAME}.conf

echo "
LABEL=frzr_root /     btrfs subvol=deployments/${CHANNEL}-${VERSION},ro,noatime,nodatacow 0 0
LABEL=frzr_root /var  btrfs subvol=var,rw,noatime,nodatacow 0 0
LABEL=frzr_root /home btrfs subvol=home,rw,noatime,nodatacow 0 0
" > /etc/fstab

# clean up/remove unnecessary files
rm -rf /etc/pacman.d
rm /boot/initramfs*

rm -rf /var
mkdir /var

rm -rf /home
mkdir /home
EOF

# must do this outside of chroot for unknown reason
echo "
nameserver 8.8.8.8
nameserver 8.8.4.4
" > ${BUILD_PATH}/etc/resolv.conf

echo "${CHANNEL}-${VERSION}" > ${BUILD_PATH}/build_info
echo "" >> ${BUILD_PATH}/build_info
cat ${BUILD_PATH}/manifest >> ${BUILD_PATH}/build_info
rm ${BUILD_PATH}/manifest

btrfs subvolume snapshot -r ${BUILD_PATH} ${SNAP_PATH}
btrfs send -f ${CHANNEL}-${VERSION}.img ${SNAP_PATH}

cat ${BUILD_PATH}/build_info

# clean up
umount ${BUILD_PATH}
umount ${MOUNT_PATH}
rm -rf ${MOUNT_PATH}
rm -rf ${BUILD_IMG}

tar cjf ${CHANNEL}-${VERSION}.img.tar.xz ${CHANNEL}-${VERSION}.img
rm ${CHANNEL}-${VERSION}.img

sha256sum ${CHANNEL}-${VERSION}.img.tar.xz
