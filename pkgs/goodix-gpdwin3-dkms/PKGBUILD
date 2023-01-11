# Maintainer: kylon

_pkgbase=goodix-gpdwin3
pkgname=${_pkgbase}-dkms
pkgver=1.2
pkgrel=1
pkgdesc="Goodix touchscreen driver hack for GPD WIN3"
arch=('any')
license=('GPL2')
depends=('dkms')
source=(
  "goodix.c"
  "goodix.h"
  "goodix_fwupload.c"
  "dkms.conf"
  "Makefile"
  "goodixgpdw3.conf"
)
md5sums=('ed4754824a1e72018e9b6b2cea3206fb'
	 'aec7f644a9a305c4102665137c7f248b'
	 '190deba40c822b9d4f89672bc4e610e9'
         'f514c2a1d6de0f50ea5ebc112447ff7d'
         'aa21936d9b3341c25761f7c4a827f39d'
         'ec3b28f8b4db703eaad235153d67ed80')

package() {
  cd "$srcdir"
  local install_dir="${pkgdir}"/usr/src/${_pkgbase}-${pkgver}
  install -Dm644 dkms.conf "${install_dir}/dkms.conf"

  # Set name and version
  sed -e "s/@_PKGBASE@/${_pkgbase}/" \
      -e "s/@PKGVER@/${pkgver}/" \
      -i "${install_dir}"/dkms.conf

  install -Dm644 goodix.c "${install_dir}/goodix.c"
  install -Dm644 goodix.h "${install_dir}/goodix.h"
  install -Dm644 goodix_fwupload.c "${install_dir}/goodix_fwupload.c"
  install -Dm644 Makefile "${install_dir}/Makefile"
  install -Dm644 goodixgpdw3.conf "${pkgdir}/etc/modprobe.d/goodixgpdw3.conf"
}

