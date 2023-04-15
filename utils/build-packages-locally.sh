#! /bin/bash
set -e
docker pull archlinux:base-devel
docker build --no-cache -t chimeraos-local-base:latest -f ./utils/base-system.Dockerfile .
docker run -it --rm --entrypoint /workdir/pkgs/build-packages.sh -v $(pwd)/pkgs:/packages:Z -v $(pwd):/workdir:Z $(pwd)/.cache:/.cache chimeraos-local-base:latest
