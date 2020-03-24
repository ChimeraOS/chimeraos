#! /bin/bash

set -e
set -x

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

SYSTEM_DESC=${SYSTEM_NAME:-GamerOS}
SYSTEM_NAME=${SYSTEM_NAME:-gameros}
USERNAME=${USERNAME:-gamer}
BUILD_USER=${BUILD_USER:-}
OUTPUT_DIR=${OUTPUT_DIR:-}

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
PIKAUR_CMD="pikaur --noconfirm -Sw ${AUR_PACKAGES}"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
PIKAUR_CACHE="/var/cache/pikaur/pkg"
if [ -n "${BUILD_USER}" ]; then
	PIKAUR_RUN=(su - "${BUILD_USER}" -c "${PIKAUR_CMD}")
	PIKAUR_CACHE="$(eval echo ~${BUILD_USER})/.cache/pikaur/pkg"
fi
rm -rf ${PIKAUR_CACHE}/*.pkg.tar.xz
"${PIKAUR_RUN[@]}"
mkdir ${BUILD_PATH}/aur
cp ${PIKAUR_CACHE}/* ${BUILD_PATH}/aur/

# copy files into chroot
cp -R rootfs/. ${BUILD_PATH}/

# chroot into target
mount --bind ${BUILD_PATH} ${BUILD_PATH}
arch-chroot ${BUILD_PATH} /bin/bash <<EOF
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

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
echo "
root ALL=(ALL) ALL
${USERNAME} ALL=(ALL) ALL
#includedir /etc/sudoers.d
" > /etc/sudoers

# set the default editor, so visudo works
echo "export EDITOR=/usr/bin/vim" >> /etc/bash.bashrc

# set default session in lightdm
echo "
[LightDM]
run-directory=/run/lightdm
[Seat:*]
session-wrapper=/etc/lightdm/Xsession
autologin-user=${USERNAME}
autologin-session=steamos
" > /etc/lightdm/lightdm.conf

echo "${SYSTEM_NAME}" > /etc/hostname

# enable multicast dns in avahi
sed -i "/^hosts:/ s/resolve/mdns resolve/" /etc/nsswitch.conf

# configure ssh
echo "
AuthorizedKeysFile	.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
PrintMotd no # pam does that
Subsystem	sftp	/usr/lib/ssh/sftp-server
" > /etc/ssh/sshd_config

echo "
LABEL=frzr_root /          btrfs subvol=deployments/${CHANNEL}-${VERSION},ro,noatime,nodatacow 0 0
LABEL=frzr_root /var       btrfs subvol=var,rw,noatime,nodatacow 0 0
LABEL=frzr_root /home      btrfs subvol=home,rw,noatime,nodatacow 0 0
LABEL=frzr_root /frzr_root btrfs subvol=/,rw,noatime,nodatacow 0 0
LABEL=frzr_efi  /boot      vfat  rw,noatime,nofail  0 0
" > /etc/fstab

echo "
LSB_VERSION=1.4
DISTRIB_ID=${SYSTEM_NAME}
DISTRIB_RELEASE=${VERSION}
DISTRIB_DESCRIPTION=${SYSTEM_DESC}
" > /etc/lsb-release

# disable retroarch menu in joypad configs
find /usr/share/libretro/autoconfig -type f -name '*.cfg' | xargs -d '\n' sed -i '/input_menu_toggle_btn/d'

# preserve installed package database
mkdir -p /usr/var/lib/pacman
cp -r /var/lib/pacman/local /usr/var/lib/pacman/

# install extra certificates
trust anchor --store /extra_certs/*.crt

# clean up/remove unnecessary files
rm -rf \
/aur \
/extra_certs \
/home \
/var \
/boot/initramfs-linux-fallback.img \
/boot/syslinux \
/usr/share/gtk-doc \
/usr/share/man \
/usr/share/doc \
/usr/share/ibus \
/usr/share/help \
/usr/share/jack-audio-connection-kit \
/usr/share/SFML \
/usr/share/libretro/autoconfig/udev/Xbox_360_Wireless_Receiver_Chinese01.cfg

# create necessary directories
mkdir /home
mkdir /var
mkdir /frzr_root
EOF

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

tar caf ${CHANNEL}-${VERSION}.img.tar.xz ${CHANNEL}-${VERSION}.img
rm ${CHANNEL}-${VERSION}.img

sha256sum ${CHANNEL}-${VERSION}.img.tar.xz

# Move the image to the output directory, if one was specified.
if [ -n "${OUTPUT_DIR}" ]; then
	mkdir -p "${OUTPUT_DIR}"
	mv ${CHANNEL}-${VERSION}.img.tar.xz ${OUTPUT_DIR}
fi
