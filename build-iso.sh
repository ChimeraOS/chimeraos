#!/bin/bash

#Get the directory of this script
work_dir="$(realpath $0|rev|cut -d '/' -f2-|rev)"
dockerfile="docker/Dockerfile"
output_dir="output"

#Create output directory if it doesn't exist
mkdir -p ${work_dir}/${output_dir}

#Build the docker container
docker build -f ${work_dir}/${dockerfile} -t gamer-os-builder ${work_dir}

#Run container
exec docker run --privileged --rm -ti -v ${work_dir}/${output_dir}:/root/gamer-os/out -h gamer-os-builder gamer-os-builder ./build.sh -v
