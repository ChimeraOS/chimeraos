#!/bin/bash

MOUNT_PATH=/
DEVICE_QUIRK_URL="https://raw.githubusercontent.com/ChimeraOS/gamescope-session/main/usr/share/gamescope-session-plus/device-quirks"
SYSTEM_FILE_DIR="/usr/share/gamescope-session-plus/device-quirks"
TMP_FILE="/tmp/device-quirks"

wget -O "$TMP_FILE" "$DEVICE_QUIRK_URL"
if diff "$TMP_FILE" "$SYSTEM_FILE_DIR" > /dev/null; then
    echo "Device quirks are already up-to-date. Exiting..."
    rm $TMP_FILE
    exit 1
fi

# Get locked state
RELOCK=0
LOCK_STATE=$(btrfs property get -fts "$MOUNT_PATH")
if [[ $LOCK_STATE == *"ro=true"* ]]; then
    btrfs property set -fts "$MOUNT_PATH" ro false
    RELOCK=1
else
    echo "Filesystem appears to be unlocked"
fi

mv "$TMP_FILE" "$SYSTEM_FILE_DIR"
if [[ $RELOCK == 1 ]]; then
    btrfs property set -fts "$MOUNT_PATH" ro true
fi

echo "Device-quirks script updated successfully"

