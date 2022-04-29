#!/bin/bash

# Intantiate dirs and files for tracking, if needed.
FOLDER="/home/gamer/.chimera"
FILE="${FOLDER}/init-devs"
PART=$1

if [[ ! -d $FOLDER ]]; then
    echo "Creating $FOLDER"
    mkdir $FOLDER && chown gamer:gamer $FOLDER
fi
if [[ ! -f "${FILE}" ]]; then
    echo "Creating $FILE"
    touch ${FILE} && chown gamer:gamer $FILE
fi

# Mount service checks for UUID before adding the drive to steam.
echo "Initializing steam library."
PART_UUID=$(blkid -o value -s UUID /dev/${PART})
grep -qxF ${PART_UUID} ${FILE} || echo ${PART_UUID} >> ${FILE}
