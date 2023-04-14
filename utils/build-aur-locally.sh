#! /bin/bash 
set -e
docker pull archlinux:base-devel
docker build --no-cache -t chimera-full-local:latest .
docker run -it --rm --entrypoint /workdir/aur-pkgs/build-aur-packages.sh -v $(pwd):/workdir:Z chimera-full-local:latest