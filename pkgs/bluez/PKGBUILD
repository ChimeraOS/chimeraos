# Maintainer: Andreas Radke <andyrtr@archlinux.org>
# Maintainer: Robin Candau <antiz@archlinux.org>
# Contributor: Tom Gundersen <teg@jklm.no>
# Contributor: Andrea Scarpino <andrea@archlinux.org>
# Contributor: Geoffroy Carrier <geoffroy@archlinux.org>

pkgbase=bluez
pkgname=('bluez' 'bluez-utils' 'bluez-libs' 'bluez-cups' 'bluez-hid2hci' 'bluez-plugins')
pkgver=5.69
pkgrel=1.1
url="http://www.bluez.org/"
arch=('x86_64')
license=('GPL2')
makedepends=('dbus' 'libical' 'systemd' 'alsa-lib' 'json-c' 'ell' 'python-docutils')
source=(https://www.kernel.org/pub/linux/bluetooth/${pkgname}-${pkgver}.tar.{xz,sign}
        bluetooth.modprobe
        AVRCP_TG_MDI_BV-04-C.patch         # SteamOS: For Bluetooth AVRCP certification test AVRCP/TG/MDI/BV-04-C, which requires a valid response from the get_element_attributes command.
        0001-valve-bluetooth-config.patch  # SteamOS: Enable compatibility with devices like AirPods Pro
        0002-valve-bluetooth-phy.patch     # SteamOS: Enable the phy
)
# see https://www.kernel.org/pub/linux/bluetooth/sha256sums.asc
sha256sums=('bc5a35ddc7c72d0d3999a0d7b2175c8b7d57ab670774f8b5b4900ff38a2627fc'
            'SKIP'
            '46c021be659c9a1c4e55afd04df0c059af1f3d98a96338236412e449bf7477b4'
            'd863bd52917e4f5819b23ae5e64a34c5b02a0cfdf3969290bfce0d26dfe137b4'
            'ebd6fe4a00f3bc81442885d43c12101a672fccdaf4379a1c4ebdc5e80282b18d'
            '5d291d833c234a14b6162e3cb14eeff41505f5c3bb7c74528b65cb10597f39cb')
validpgpkeys=('E932D120BC2AEC444E558F0106CA9F5D1DCF2659') # Marcel Holtmann <marcel@holtmann.org>

build() {
  cd "${pkgname}"-${pkgver}
  ./configure \
          --prefix=/usr \
          --mandir=/usr/share/man \
          --sysconfdir=/etc \
          --localstatedir=/var \
          --libexecdir=/usr/lib \
          --with-dbusconfdir=/usr/share \
          --disable-obex \
          --enable-btpclient \
          --enable-midi \
          --enable-sixaxis \
          --enable-mesh \
          --enable-hid2hci \
          --enable-experimental \
          --enable-library # this is deprecated
  make
}

check() {
  cd "$pkgname"-$pkgver
  make check
}

prepare() {
  patch -d "${pkgname}"-${pkgver} -p1 -i "${srcdir}"/AVRCP_TG_MDI_BV-04-C.patch
  patch -d "${pkgname}"-${pkgver} -p1 -i "${srcdir}"/0001-valve-bluetooth-config.patch
  patch -d "${pkgname}"-${pkgver} -p1 -i "${srcdir}"/0002-valve-bluetooth-phy.patch
}

package_bluez() {
  pkgdesc="Daemons for the bluetooth protocol stack"
  depends=('libical' 'dbus' 'glib2' 'alsa-lib' 'json-c' 'glibc')
  backup=('etc/bluetooth/main.conf')
  conflicts=('obexd-client' 'obexd-server')

  cd "${pkgbase}"-${pkgver}
  make DESTDIR=${pkgdir} \
       install-pkglibexecPROGRAMS \
       install-dbussessionbusDATA \
       install-systemdsystemunitDATA \
       install-systemduserunitDATA \
       install-dbussystembusDATA \
       install-dbusDATA \
       install-man8

  # ship upstream main config file
  install -dm555 "${pkgdir}"/etc/bluetooth
  install -Dm644 "${srcdir}"/"${pkgbase}"-${pkgver}/src/main.conf "${pkgdir}"/etc/bluetooth/main.conf

  # add basic documention
  install -dm755 "${pkgdir}"/usr/share/doc/"${pkgbase}"/dbus-apis
  cp -a doc/*.txt "${pkgdir}"/usr/share/doc/"${pkgbase}"/dbus-apis/
  # fix module loading errors
  install -dm755 "${pkgdir}"/usr/lib/modprobe.d
  install -Dm644 "${srcdir}"/bluetooth.modprobe "${pkgdir}"/usr/lib/modprobe.d/bluetooth-usb.conf
  # load module at system start required by some functions
  # https://bugzilla.kernel.org/show_bug.cgi?id=196621
  install -dm755 "$pkgdir"/usr/lib/modules-load.d
  echo "crypto_user" > "$pkgdir"/usr/lib/modules-load.d/bluez.conf
  
  # fix obex file transfer - https://bugs.archlinux.org/task/45816
  ln -fs /usr/lib/systemd/user/obex.service "${pkgdir}"/usr/lib/systemd/user/dbus-org.bluez.obex.service

  # FS#74157 - bluez systemd service fails without localstatedir present
  install -dm700 "${pkgdir}"/var/lib/bluetooth

  # cleanup  - these libs go into bluez-libs
  rm "${pkgdir}"/usr/lib/libbluetooth.so*
}

package_bluez-utils() {
  pkgdesc="Development and debugging utilities for the bluetooth protocol stack"
  depends=('dbus' 'systemd' 'systemd-libs' 'glib2' 'glibc' 'readline')
  optdepends=('ell: for btpclient'
              'json-c: for mesh-cfgclient')
  backup=('etc/bluetooth/mesh-main.conf')
  conflicts=('bluez-hcidump')
  provides=('bluez-hcidump')
  replaces=('bluez-hcidump' 'bluez<=4.101')

  cd "${pkgbase}"-${pkgver}
  make DESTDIR="${pkgdir}" \
       install-binPROGRAMS \
       install-dist_zshcompletionDATA \
       install-man1

  # add missing tools FS#41132, FS#41687, FS#42716
  for files in `find tools/ -type f -perm -755`; do
    filename=$(basename $files)
    install -Dm755 "${srcdir}"/"${pkgbase}"-${pkgver}/tools/$filename "${pkgdir}"/usr/bin/$filename
  done
  
  # ship upstream mesh config file
  install -dm555 "${pkgdir}"/etc/bluetooth
  install -Dm644 "${srcdir}"/"${pkgbase}"-${pkgver}/mesh/mesh-main.conf "${pkgdir}"/etc/bluetooth/mesh-main.conf
 
  # libbluetooth.so* are part of libLTLIBRARIES and binPROGRAMS targets
  #make DESTDIR=${pkgdir} uninstall-libLTLIBRARIES
  #rmdir ${pkgdir}/usr/lib
  rm -rf "${pkgdir}"/usr/lib

  # move the hid2hci man page out
  mv "${pkgdir}"/usr/share/man/man1/hid2hci.1 "${srcdir}"/
}

package_bluez-libs() {
  pkgdesc="Deprecated libraries for the bluetooth protocol stack"
  depends=('glibc')
  provides=('libbluetooth.so')
  license=('LGPL2.1')

  cd "${pkgbase}"-${pkgver}
  make DESTDIR="${pkgdir}" \
       install-pkgincludeHEADERS \
       install-libLTLIBRARIES \
       install-pkgconfigDATA
}

package_bluez-cups() {
  pkgdesc="CUPS printer backend for Bluetooth printers"
  depends=('cups' 'glib2' 'glibc' 'dbus')

  cd "${pkgbase}"-${pkgver}
  make DESTDIR="${pkgdir}" install-cupsPROGRAMS

  # cleanup  - these libs go into bluez-libs
  rm "${pkgdir}"/usr/lib/libbluetooth.so*
}

package_bluez-hid2hci() {
  pkgdesc="Put HID proxying bluetooth HCI's into HCI mode"
  depends=('systemd' 'systemd-libs' 'glibc')

  cd "${pkgbase}"-${pkgver}
  make DESTDIR=${pkgdir} \
       install-udevPROGRAMS \
       install-rulesDATA
  
  install -dm755 "${pkgdir}"/usr/share/man/man1
  mv "${srcdir}"/hid2hci.1 "${pkgdir}"/usr/share/man/man1/hid2hci.1

  # cleanup  - these libs go into bluez-libs
  rm "${pkgdir}"/usr/lib/libbluetooth.so*
}

package_bluez-plugins() {
  pkgdesc="bluez plugins (PS3 Sixaxis controller)"
  depends=('systemd' 'systemd-libs' 'glibc')

  cd "${pkgbase}"-${pkgver}
  make DESTDIR="${pkgdir}" \
       install-pluginLTLIBRARIES

  # cleanup  - these libs go into bluez-libs
  rm "${pkgdir}"/usr/lib/libbluetooth.so*
}
