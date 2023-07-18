# Mantainer: marmis <tiagodepalves@gmail.com>
# Contributor: vitor_hideyoshi <vitor.h.n.batista@gmail.com>
# Contributor: katt <magunasu.b97@gmail.com>
# Contributor: Yangtse Su <i@yangtse.me>

_pkgname=xpadneo
_dkmsname=hid-${_pkgname}
pkgname=${_pkgname}-dkms
pkgver=0.9.5
_pkgver=v${pkgver}
pkgrel=3
pkgdesc="Advanced Linux Driver for Xbox One Wireless Gamepad"
arch=('any')
url='https://github.com/atar-axis/xpadneo'
license=('GPL3')
depends=('dkms' 'bluez' 'bluez-utils')
source=("${_pkgname}-${_pkgver}.tar.gz::${url}/archive/${_pkgver}.tar.gz"
        drop-etc-files.patch
        rename-marker.patch)
b2sums=('d04a3e1b626af1f1a9ec114f0a8ed44c50ec8cde9da71483491d1afd7688611fd7548186ea68ef8a144aecec06acba816e81e9f0708c8dceb96fa1d40985bb44'
        'e300dae73905e3223091fe2428c981ecce4c205262d1a5094e0a0b72e50fa37c85486de2c643e6206bf59cb6add727bf8a66c241e8a4674dab79e3109d673d9b'
        '7f4844b39131d1a8a07a0dc293fc5ef36bc577cc4dbef29479957ae65452191f2f492703e1c90a272f7033895a4df568bb7e716f1ceb6725fc9f84777e43fc03')

prepare() {
    cd "${_pkgname}-${pkgver}/${_dkmsname}"

    # Upstream uses dkms.post_install to create modprobe and udev files in
    # /etc. In Arch, it makes more sense to create these files in /usr/lib
    # and let pacman take care of them.
    patch -p1 -i "${srcdir}/drop-etc-files.patch"

    # Set the current version in DKMS config file.
    patch -p1 -i "${srcdir}/rename-marker.patch"
    sed "s/@PACKAGE_VERSION@/${_pkgver}/" dkms.conf.in > dkms.conf
}

check() {
    # Warning if missing linux-headers for current `uname -r` kernel
    if [ ! -f "/usr/lib/modules/$(uname -r)/build/Makefile" ]
    then
        _BOLDRED='\033[1;31m'
        _RED='\033[0;31m'
        _RESET='\033[0m'
        echo -e "${_BOLDRED}WARNING:${_RED} You may be missing headers for your current kernel, DKMS packages requires them."
        echo -e "Please refer to https://wiki.archlinux.org/title/Dynamic_Kernel_Module_Support for details.${_RESET}"
    fi
}

package() {
    cd "${_pkgname}-${pkgver}/${_dkmsname}"

    # Module source
    install -Dm0644 -t "${pkgdir}/usr/src/${_dkmsname}-${_pkgver}/src" src/*

    # DKMS files
    install -Dm0644 -t "${pkgdir}/usr/src/${_dkmsname}-${_pkgver}" Makefile dkms.conf dkms.post_install dkms.post_remove
    install -Dm0755 -t "${pkgdir}/usr/src/${_dkmsname}-${_pkgver}" dkms.post_install dkms.post_remove

    # modprobe aliases
    install -Dm0644 -t "${pkgdir}/usr/lib/modprobe.d" etc-modprobe.d/*

    # udev rules
    install -Dm0644 -t "${pkgdir}/usr/lib/udev/rules.d" etc-udev-rules.d/*
}
