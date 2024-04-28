# Maintainer: Daniel Bermond <dbermond@archlinux.org>

pkgname=python-leveldb
pkgver=0.201
pkgrel=3
branch="patch-1"
pkgdesc='Python bindings for leveldb database library'
arch=('x86_64')
url='https://github.com/ruineka/py-leveldb/'
license=('BSD')
depends=('python')
makedepends=('git' 'python-build' 'python-installer' 'python-setuptools' 'python-wheel')
checkdepends=('python-nose')
source=("git+https://github.com/ruineka/py-leveldb.git#branch=${branch}"
        'git+https://github.com/google/leveldb.git')
sha256sums=('SKIP'
            'SKIP')

prepare() {
    git -C py-leveldb submodule init
    git -C py-leveldb config --local submodule.leveldb.url "${srcdir}/leveldb"
    git -C py-leveldb -c protocol.file.allow='always' submodule update
}

build() {
    cd py-leveldb
    python -m build --wheel --no-isolation
}

check() {
    local _pyver
    _pyver="$(python -c 'import sys; print("%s.%s" %sys.version_info[0:2])')"
    cd py-leveldb
    PYTHONPATH="$(pwd)/build/lib.linux-${CARCH}-cpython-${_pyver/./}" nosetests
}

package() {
    python -m installer --destdir="$pkgdir" py-leveldb/dist/*.whl
    
    local _sitepkgs
    local _sitepkgs=$(python -c "import site; print(site.getsitepackages()[0])")
    install -d -m755 "${pkgdir}/usr/share/licenses/${pkgname}"
    ln -s "../../../${_sitepkgs/\/usr\//}/leveldb-${pkgver::-1}.dist-info/LICENSE" \
        "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
