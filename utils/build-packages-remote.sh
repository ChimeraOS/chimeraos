#! /bin/bash
set -e
docker pull ghcr.io/chimeraos/chimeraos:master
docker run --rm --entrypoint /workdir/pkgs/build-packages.sh -v $(pwd):/workdir:Z ghcr.io/chimeraOS/chimeraos:master
