#!/bin/bash
# Modified from SteamOS 3 format-sdcard.sh

set -e
MEDIA=$1
PART=${MEDIA}1

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
  /usr/lib/media-support/init-media.sh ${PART}
  systemctl start media-mount@${PART}.service
  echo "Format complete"
  exit 0
fi

exit 1
