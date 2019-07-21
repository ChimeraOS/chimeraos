#!/bin/bash

#Configuration variables for the iso
iso_name="gamer-os"
iso_label="GAMER_OS_$(date +%Y%m)"
iso_publisher="Gamer OS <https://github.com/gamer-os/gamer-os>"
iso_application="Gamer OS Installer"
iso_version="$(date +%Y.%m.%d)"
install_script="install.sh"

dockerfile="docker/Dockerfile"
output_dir="output"

#Get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"

#Create output directory if it doesn't exist yet
mkdir -p ${work_dir}/${output_dir}

#Copy the install.sh script for inclusion on the iso
cp -pf ${install_script} gamer-os/airootfs/root/

#Build the docker container
docker build -f ${work_dir}/${dockerfile} -t gamer-os-builder ${work_dir}

#Make the container build the iso
exec docker run --privileged --rm -ti -v ${work_dir}/${output_dir}:/root/gamer-os/out -h gamer-os-builder gamer-os-builder ./build.sh -v -N ${iso_name} -L ${iso_label} -P ${iso_publisher} -A ${iso_application} -V ${iso_version}
