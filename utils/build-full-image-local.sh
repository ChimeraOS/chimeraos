#! /bin/bash
# This script will build the full image on your local machine.
# It will do this via a base archlinux docker image and compiling everything on top.
set -e
# Pull base image
docker pull archlinux:base-devel
# Create local docker container with chimera-full-local tag
# This will build all PKGBUILDS in the pkgs folder and put them in the docker container.
# Remove the --no-cache if you don't need a clean build everytime.
docker build --no-cache -t chimera-full-local:latest .
# Export the .cache folder from the docker container so future builds will be quicker.
# You can always do a clean build by removing the .cache folder from the container.
# Made the permissions so the container has access to it.
mkdir -p .cache
chmod 777 .cache
# Build AUR packages from manifest locally and put them in aur-pkgs folder
docker run -it --rm --entrypoint /workdir/aur-pkgs/build-aur-packages.sh -v $(pwd):/workdir:Z -v $(pwd)/.cache:/home/build/.cache:Z chimera-full-local:latest
# Build chimera image using the AUR packages found in aur-pkgs.
# If the -e NO_COMPRESS=1 gets removed, the docker container will tar the ouput image
docker run -it --rm -u root --privileged=true --entrypoint /workdir/build-image.sh -e NO_COMPRESS=1 -v $(pwd):/workdir:Z -v $(pwd)/output:/output:z chimera-full-local:latest $(echo local-$(git rev-parse HEAD | cut -c1-7))
