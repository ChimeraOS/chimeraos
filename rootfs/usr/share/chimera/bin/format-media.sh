#!/bin/bash
# Modified from SteamOS 3 format-sdcard.sh

set -e
MEDIA=$1
PART=${MEDIA}1

# Intantiate dirs and files for tracking, if needed.
FOLDER="/home/gamer/.chimera"
FILE="${FOLDER}/init-devs"
if [[ ! -d $FOLDER ]]; then
    echo "Creating $FOLDER"
    mkdir $FOLDER && chown gamer:gamer $FOLDER
fi
if [[ ! -f "${FILE}" ]]; then
    echo "Creating $FILE"
    touch ${FILE} && chown gamer:gamer $FILE
fi
if [[ -e /dev/$MEDIA ]]
then
  # Stop the service to remove the drive from steam. 
  systemctl stop media-mount@${PART}.service
  
  # Create the new filesystem.
  parted --script /dev/${MEDIA} mklabel gpt mkpart primary 0% 100%
  sync
  mkfs.ext4 -m 0 -O casefold -F /dev/${PART}
  sync

  # Initialize a steam library.
  # Mount service checks for UUID before adding the drive to steam.
  echo "Initializing steam library."
  PART_UUID=$(blkid -o value -s UUID /dev/${PART})
  grep -qxF ${PART_UUID} ${FILE} || echo ${PART_UUID} >> ${FILE}
  systemctl start media-mount@${PART}.service
  echo "Format complete"
  exit 0
fi

exit 1
