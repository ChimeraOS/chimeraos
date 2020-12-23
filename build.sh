#! /bin/bash

set -e
set -x

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

BUILD_USER=${BUILD_USER:-}
OUTPUT_DIR=${OUTPUT_DIR:-}

source manifest

if [ -z "${SYSTEM_NAME}" ]; then
  echo "SYSTEM_NAME must be specified"
  exit
fi

if [ -z "${VERSION}" ]; then
  echo "VERSION must be specified"
  exit
fi

DISPLAY_VERSION=${VERSION}
LSB_VERSION=${VERSION}

if [ -n "$1" ]; then
	DISPLAY_VERSION="${VERSION} (${1})"
	VERSION="${VERSION}_${1}"
	LSB_VERSION="${LSB_VERSION}　(${1})"
fi

MOUNT_PATH=/tmp/${SYSTEM_NAME}-build
BUILD_PATH=${MOUNT_PATH}/subvolume
SNAP_PATH=${MOUNT_PATH}/${SYSTEM_NAME}-${VERSION}
BUILD_IMG=${SYSTEM_NAME}-build.img

mkdir -p ${MOUNT_PATH}

fallocate -l ${SIZE} ${BUILD_IMG}
mkfs.btrfs -f ${BUILD_IMG}
mount -t btrfs -o loop,nodatacow ${BUILD_IMG} ${MOUNT_PATH}
btrfs subvolume create ${BUILD_PATH}

# bootstrap
pacstrap ${BUILD_PATH} base

# build AUR packages to be installed later
PIKAUR_CMD="pikaur --noconfirm -Sw ${AUR_PACKAGES}"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
PIKAUR_CACHE="/var/cache/pikaur"
if [ -n "${BUILD_USER}" ]; then
	PIKAUR_RUN=(su - "${BUILD_USER}" -c "${PIKAUR_CMD}")
	PIKAUR_CACHE="$(eval echo ~${BUILD_USER})/.cache/pikaur"
fi
rm -rf ${PIKAUR_CACHE}
"${PIKAUR_RUN[@]}"
mkdir ${BUILD_PATH}/aur
cp ${PIKAUR_CACHE}/pkg/* ${BUILD_PATH}/aur/
rm -rf ${PIKAUR_CACHE}

# copy files into chroot
cp -R rootfs/. ${BUILD_PATH}/

# chroot into target
mount --bind ${BUILD_PATH} ${BUILD_PATH}
arch-chroot ${BUILD_PATH} /bin/bash <<EOF
set -e
set -x

echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

# set archive date if specified
if [ -n "${ARCHIVE_DATE}" ]; then
	echo '
	Server=https://archive.archlinux.org/repos/${ARCHIVE_DATE}/\$repo/os/\$arch
	' > /etc/pacman.d/mirrorlist
fi

# add multilib and chaotic-aur repos
echo '
[multilib]
Include = /etc/pacman.d/mirrorlist

[chaotic-aur]
Server = https://builds.garudalinux.org/repos/\$repo/\$arch
Server = https://repo.kitsuna.net/\$arch
Server = https://chaotic.tn.dedyn.io/\$arch
Server = https://repo.jkanetwork.com/repo/\$repo/\$arch
Server = http://chaotic.bangl.de/\$repo/\$arch
Server = https://mirror.maakpain.kro.kr/garuda/\$repo/\$arch
' >> /etc/pacman.conf

# add trust for chaotic-aur
pacman-key --init
pacman-key --keyserver hkp://keyserver.ubuntu.com -r 3056513887B78AEB 8A9E14A07010F7E3
pacman-key --lsign-key 3056513887B78AEB
pacman-key --lsign-key 8A9E14A07010F7E3

# update package databases
pacman --noconfirm -Syy

# install packages
pacman --noconfirm -S ${PACKAGES}

# install AUR packages
pacman --noconfirm -U /aur/*

# record installed packages & versions
pacman -Q > /manifest

# enable services
systemctl enable ${SERVICES}

# enable user services
systemctl --global enable ${USER_SERVICES}

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
LABEL=frzr_root /          btrfs subvol=deployments/${SYSTEM_NAME}-${VERSION},ro,noatime,nodatacow 0 0
LABEL=frzr_root /var       btrfs subvol=var,rw,noatime,nodatacow 0 0
LABEL=frzr_root /home      btrfs subvol=home,rw,noatime,nodatacow 0 0
LABEL=frzr_root /frzr_root btrfs subvol=/,rw,noatime,nodatacow 0 0
LABEL=frzr_efi  /boot      vfat  rw,noatime,nofail  0 0
" > /etc/fstab

echo "
LSB_VERSION=1.4
DISTRIB_ID=${SYSTEM_NAME}
DISTRIB_RELEASE=\"${LSB_VERSION}\"
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
/usr/include \
/usr/share/gtk-doc \
/usr/share/man \
/usr/share/doc \
/usr/share/ibus \
/usr/share/help \
/usr/share/jack-audio-connection-kit \
/usr/share/SFML \
/usr/share/applications \
/usr/share/libretro/autoconfig/udev/Xbox_360_Wireless_Receiver_Chinese01.cfg

# create necessary directories
mkdir /home
mkdir /var
mkdir /frzr_root
EOF

echo "${SYSTEM_NAME}-${VERSION}" > ${BUILD_PATH}/build_info
echo "" >> ${BUILD_PATH}/build_info
cat ${BUILD_PATH}/manifest >> ${BUILD_PATH}/build_info
rm ${BUILD_PATH}/manifest

btrfs subvolume snapshot -r ${BUILD_PATH} ${SNAP_PATH}
btrfs send -f ${SYSTEM_NAME}-${VERSION}.img ${SNAP_PATH}

cp ${BUILD_PATH}/build_info build_info.txt

# clean up
umount ${BUILD_PATH}
umount ${MOUNT_PATH}
rm -rf ${MOUNT_PATH}
rm -rf ${BUILD_IMG}

IMG_FILENAME="${SYSTEM_NAME}-${VERSION}.img.tar.xz"

tar caf ${IMG_FILENAME} ${SYSTEM_NAME}-${VERSION}.img
rm ${SYSTEM_NAME}-${VERSION}.img

sha256sum ${SYSTEM_NAME}-${VERSION}.img.tar.xz > sha256sum.txt
cat sha256sum.txt

# Move the image to the output directory, if one was specified.
if [ -n "${OUTPUT_DIR}" ]; then
	mkdir -p "${OUTPUT_DIR}"
	mv ${IMG_FILENAME} ${OUTPUT_DIR}
	mv build_info.txt ${OUTPUT_DIR}
	mv sha256sum.txt ${OUTPUT_DIR}
fi

# set outputs for github actions
echo "::set-output name=version::${VERSION}"
echo "::set-output name=display_version::${DISPLAY_VERSION}"
echo "::set-output name=display_name::${SYSTEM_DESC}"
echo "::set-output name=image_filename::${IMG_FILENAME}"
