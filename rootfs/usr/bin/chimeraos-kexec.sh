#!/bin/sh

set -e

if [ -f /proc/cmdline ]; then
    if ! grep -Fqx "chimeraos=" "/proc/cmdline"; then
        echo "Image kernel not running -- Running kexec."
        /usr/bin/kexec -l /boot/vmlinuz-$1 --initrd=/boot/initramfs-$1.img --command-line="root=gpt-auto rw $(cat /usr/lib/frzr.d/bootconfig.conf) chimeraos="

        if /usr/bin/mokutil --sb-state | grep -F "SecureBoot" | grep -Fq "enabled"; then
            echo "SecureBoot is enabled -- Aborting."
        else
            echo "Reached kexec."
            systemctl kexec
        fi
    else
        echo "Image kernel already running."
    fi
else
    echo "An unsupported kernel has booted!"
fi