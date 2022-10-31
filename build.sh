#! /bin/bash

set -e
set -x

if [ $EUID -ne 0 ]; then
	echo "$(basename $0) must be run as root"
	exit 1
fi

BUILD_USER=${BUILD_USER:-}
OUTPUT_DIR=${OUTPUT_DIR:-}

export GNUPGHOME="/etc/pacman.d/gnupg"

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
VERSION_NUMBER=${VERSION}

if [ -n "$1" ]; then
	DISPLAY_VERSION="${VERSION} (${1})"
	VERSION="${VERSION}_${1}"
	LSB_VERSION="${LSB_VERSION}　(${1})"
	BUILD_ID="${1}"
fi

MOUNT_PATH=/tmp/${SYSTEM_NAME}-build
BUILD_PATH=${MOUNT_PATH}/subvolume
SNAP_PATH=${MOUNT_PATH}/${SYSTEM_NAME}-${VERSION}
BUILD_IMG=/output/${SYSTEM_NAME}-build.img

mkdir -p ${MOUNT_PATH}

fallocate -l ${SIZE} ${BUILD_IMG}
mkfs.btrfs -f ${BUILD_IMG}
mount -t btrfs -o loop,nodatacow ${BUILD_IMG} ${MOUNT_PATH}
btrfs subvolume create ${BUILD_PATH}

# bootstrap
pacstrap ${BUILD_PATH} base

# build AUR packages to be installed later
export GIT_ALLOW_PROTOCOL=file:https:git
PIKAUR_CMD="PKGDEST=/tmp/temp_repo pikaur --noconfirm -Sw ${AUR_PACKAGES}"
PIKAUR_RUN=(bash -c "${PIKAUR_CMD}")
if [ -n "${BUILD_USER}" ]; then
	PIKAUR_RUN=(su "${BUILD_USER}" -c "${PIKAUR_CMD}")
fi
"${PIKAUR_RUN[@]}"
mkdir ${BUILD_PATH}/extra_pkgs
cp /tmp/temp_repo/* ${BUILD_PATH}/extra_pkgs

# download package overrides
if [ -n "${PACKAGE_OVERRIDES}" ]; then
	wget --directory-prefix=${BUILD_PATH}/extra_pkgs ${PACKAGE_OVERRIDES}
fi

# copy files into chroot
cp -R manifest rootfs/. ${BUILD_PATH}/

# add chaotic-aur and copy keys into chroot
pacman-key --init
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman --noconfirm -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-'{keyring,mirrorlist}'.pkg.tar.zst'
rm -rf ${BUILD_PATH}/etc/pacman.d
cp -R /etc/pacman.d ${BUILD_PATH}/etc/

# chroot into target
mount --bind ${BUILD_PATH} ${BUILD_PATH}
arch-chroot ${BUILD_PATH} /bin/bash <<EOF
set -e
set -x

source /manifest

echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

# set archive date if specified
if [ -n "${ARCHIVE_DATE}" ]; then
	echo '
	Server=https://archive.archlinux.org/repos/${ARCHIVE_DATE}/\$repo/os/\$arch
	' > /etc/pacman.d/mirrorlist
fi

# Enable ParallelDownloads
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

# add multilib and chaotic-aur repos
echo '
[multilib]
Include = /etc/pacman.d/mirrorlist

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
' >> /etc/pacman.conf

# update package databases
pacman --noconfirm -Syy

# install kernel package
pacman --noconfirm -S "${KERNEL_PACKAGE}" "${KERNEL_PACKAGE}-headers"

# install packages
pacman --noconfirm -S --overwrite '*' ${PACKAGES}
rm -rf /var/cache/pacman/pkg

# install AUR & override packages
pacman --noconfirm -U --overwrite '*' /extra_pkgs/*
rm -rf /var/cache/pacman/pkg

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

# Add sudo permissions
sed -i '/%wheel ALL=(ALL:ALL) ALL/s/^# //g' /etc/sudoers
echo "${USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/dmidecode -t 11
" > /etc/sudoers.d/steam
echo "${USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/chimera-session-use-gamescope
${USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/chimera-session-use-lightdm
${USERNAME} ALL=(ALL) NOPASSWD: /usr/lib/media-support/format-media.sh*
" > /etc/sudoers.d/chimera

# set the default editor, so visudo works
echo "export EDITOR=/usr/bin/vim" >> /etc/bash.bashrc

echo "[Seat:*]
autologin-user=${USERNAME}
" > /etc/lightdm/lightdm.conf.d/00-autologin-user.conf

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

echo 'NAME="${SYSTEM_DESC}"
VERSION="${DISPLAY_VERSION}"
VERSION_ID="${VERSION_NUMBER}"
BUILD_ID="${BUILD_ID}"
PRETTY_NAME="${SYSTEM_DESC} ${DISPLAY_VERSION}"
ID=${SYSTEM_NAME}
ID_LIKE=arch
ANSI_COLOR="1;31"
HOME_URL="${WEBSITE}"
DOCUMENTATION_URL="${DOCUMENTATION_URL}"
BUG_REPORT_URL="${BUG_REPORT_URL}"' > /etc/os-release

# install extra certificates
trust anchor --store /extra_certs/*.crt

# run post install hook
postinstallhook

# record installed packages & versions
pacman -Q > /manifest

# preserve installed package database
mkdir -p /usr/var/lib/pacman
cp -r /var/lib/pacman/local /usr/var/lib/pacman/

# move kernel image and initrd to a defualt location if "linux" is not used
if [ ${KERNEL_PACKAGE} != 'linux' ] ; then
	mv /boot/vmlinuz-${KERNEL_PACKAGE} /boot/vmlinuz-linux
	mv /boot/initramfs-${KERNEL_PACKAGE}.img /boot/initramfs-linux.img
	mv /boot/initramfs-${KERNEL_PACKAGE}-fallback.img /boot/initramfs-linux-fallback.img
fi

# clean up/remove unnecessary files
rm -rf \
/extra_pkgs \
/extra_certs \
/home \
/var \

rm -rf ${FILES_TO_DELETE}

# create necessary directories
mkdir /home
mkdir /var
mkdir /frzr_root
EOF

# copy files into chroot again
cp -R rootfs/. ${BUILD_PATH}/
rm -rf ${BUILD_PATH}/extra_certs

echo "${SYSTEM_NAME}-${VERSION}" > ${BUILD_PATH}/build_info
echo "" >> ${BUILD_PATH}/build_info
cat ${BUILD_PATH}/manifest >> ${BUILD_PATH}/build_info
rm ${BUILD_PATH}/manifest

btrfs subvolume snapshot -r ${BUILD_PATH} ${SNAP_PATH}
btrfs send -f ${SYSTEM_NAME}-${VERSION}.img ${SNAP_PATH}

cp ${BUILD_PATH}/build_info build_info.txt

# clean up
umount -l ${BUILD_PATH}
umount -l ${MOUNT_PATH}
rm -rf ${MOUNT_PATH}
rm -rf ${BUILD_IMG}

IMG_FILENAME="${SYSTEM_NAME}-${VERSION}.img.tar.xz"

tar -c -I'xz -9 -T0' -f ${IMG_FILENAME} ${SYSTEM_NAME}-${VERSION}.img
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
