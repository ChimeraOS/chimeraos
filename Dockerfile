FROM archlinux:base-devel
LABEL contributor="shadowapex@gmail.com"
COPY rootfs/etc/pacman.conf /etc/pacman.conf
RUN echo -e "keyserver-options auto-key-retrieve" >> /etc/pacman.d/gnupg/gpg.conf && \
    pacman --noconfirm -Syyuu && \
    pacman --noconfirm -S \
    arch-install-scripts \
    btrfs-progs \
    fmt \
    xcb-util-wm \
    wget \
    pyalpm \
    python-build \
    python-installer \
    python-hatchling \
    python-markdown-it-py \
    python-setuptools \
    python-wheel \
    sudo \
    reflector \
    && \
    pacman --noconfirm -S --needed git && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd build -G wheel -m && \
    su - build -c "git clone https://aur.archlinux.org/pikaur.git /tmp/pikaur" && \
    su - build -c "cd /tmp/pikaur && makepkg -f" && \
    pacman --noconfirm -U /tmp/pikaur/pikaur-*.pkg.tar.zst

# Add a fake systemd-run script to workaround pikaur requirement.
RUN echo -e "#!/bin/bash\nif [[ \"$1\" == \"--version\" ]]; then echo 'fake 244 version'; fi\nmkdir -p /var/cache/pikaur\n" >> /usr/bin/systemd-run && \
    chmod +x /usr/bin/systemd-run

COPY manifest /manifest
# Freeze packages and overwrite with overrides when needed
RUN source /manifest; if [ -n "${ARCHIVE_DATE}" ]; then echo "Server=https://archive.archlinux.org/repos/${ARCHIVE_DATE}/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist; else reflector --verbose --age 2 --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; fi && \
    pacman --noconfirm -Syyuu; if [ -n "${PACKAGE_OVERRIDES}" ]; then wget --directory-prefix=/tmp/extra_pkgs ${PACKAGE_OVERRIDES}; pacman --noconfirm -U --overwrite '*' /tmp/extra_pkgs/*; fi

USER build
ENV BUILD_USER "build"
ENV GNUPGHOME  "/etc/pacman.d/gnupg"
# Built image will be moved here. This should be a host mount to get the output.
ENV OUTPUT_DIR /output

COPY pkgs /packages
RUN /packages/build-packages.sh

WORKDIR /workdir