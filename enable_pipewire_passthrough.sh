#!/bin/bash
set -e

# Function to enable PipeWire audio passthrough with Dolby Atmos support
enable_pipewire_passthrough() {
    echo "Enabling PipeWire passthrough configuration with Dolby Atmos support"

    # Create PipeWire configuration directories if not exists
    mkdir -p /etc/pipewire /etc/pipewire/media-session.d

    # Update pipewire.conf to support passthrough
    cat <<EOF >/etc/pipewire/pipewire.conf
context.properties = {
    default.clock.rate          = 48000
    default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
    default.clock.quantum       = 1024
    default.clock.min-quantum   = 32
    default.clock.max-quantum   = 2048
    default.clock.force-rate    = false
}
EOF

    # Modify ALSA monitor configuration for passthrough with Dolby Atmos support
    cat <<EOF >/etc/pipewire/media-session.d/alsa-monitor.conf
rules = [
    {
        matches = [
            {
                node.name = "~.*hdmi.*"
            }
        ]
        actions = {
            update-props = {
                audio.format = "S32_LE"
                audio.rate = 192000  # Set the max rate that supports Atmos
                audio.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
                api.alsa.pcm.handle-passthrough = true
            }
        }
    },
    {
        matches = [
            {
                node.name = "~.*spdif.*"
            }
        ]
        actions = {
            update-props = {
                audio.format = "S32_LE"
                audio.rate = 192000
                audio.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
                api.alsa.pcm.handle-passthrough = true
            }
        }
    }
]
EOF

    echo "PipeWire passthrough configuration with Dolby Atmos support applied successfully."
}

# Call the function if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    enable_pipewire_passthrough
fi
