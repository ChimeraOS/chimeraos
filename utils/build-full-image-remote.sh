#! /bin/bash
# This script will use the docker image already created on github.
# This saves the compiling of the pkgs folder.
set -e
# If you have a PR open, you could also use pr-<PR-NUMBER> to use that container if that has build before.
# Every release also has a container.txt which contains the container it was built on.
CONTAINER="ghcr.io/chimeraos/chimeraos:master"
docker pull ${CONTAINER}
# Since reflector is run upon building the container, that means the mirrors could be out of date. 
# Since reflector still exists in the container. You could update the scripts/entrypoints so that it would update the mirrors.

# Export the .cache folder from the docker container so future builds will be quicker
# Made the permissions so the container has access to it.
# You can always do a clean build by removing the .cache folder from the container
mkdir -p .cache
chmod 777 .cache
# Build the AUR packages with the github container
docker run -it --rm --entrypoint /workdir/aur-pkgs/build-aur-packages.sh -v $(pwd):/workdir:Z -v $(pwd)/.cache:/home/build/.cache:Z ${CONTAINER}
# Build chimera image using the AUR packages found in aur-pkgs.
# If the -e NO_COMPRESS=1 gets removed, the docker container will tar the ouput image
docker run -it --rm -u root --privileged=true --entrypoint /workdir/build-image.sh -e NO_COMPRESS=1 -v $(pwd):/workdir:Z -v $(pwd)/output:/output:z ${CONTAINER} $(echo local-$(git rev-parse HEAD | cut -c1-7))