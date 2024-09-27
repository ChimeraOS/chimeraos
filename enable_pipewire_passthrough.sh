#!/bin/bash
set -e

# Function to enable PipeWire audio passthrough with Dolby Atmos support
enable_pipewire_passthrough() {
    local config_path_pipewire="audio/spatial_audio/pipewire.conf"
    local config_path_alsa="audio/spatial_audio/alsa_monitor.conf"

    echo "Enabling PipeWire passthrough configuration with Dolby Atmos support"

    # Check if configuration files exist
    if [ ! -f "$config_path_pipewire" ]; then
        echo "Error: pipewire.conf not found at $config_path_pipewire"
        exit 1
    fi

    if [ ! -f "$config_path_alsa" ]; then
        echo "Error: alsa_monitor.conf not found at $config_path_alsa"
        exit 1
    fi

    # Create PipeWire configuration directories if they do not exist
    mkdir -p /etc/pipewire /etc/pipewire/media-session.d

    # Copy the provided pipewire.conf to the system location
    cp "$config_path_pipewire" /etc/pipewire/pipewire.conf
    echo "Applied pipewire.conf from $config_path_pipewire"

    # Copy the provided alsa_monitor.conf to the system location
    cp "$config_path_alsa" /etc/pipewire/media-session.d/alsa_monitor.conf
    echo "Applied alsa_monitor.conf from $config_path_alsa"

    echo "PipeWire passthrough configuration with Dolby Atmos support applied successfully."
}

# Call the function
enable_pipewire_passthrough
