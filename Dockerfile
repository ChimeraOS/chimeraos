FROM archlinux:base-devel
LABEL contributor="shadowapex at gmail dot com"

RUN echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf && \
	pacman --noconfirm -Syu && \
	pacman --noconfirm -S arch-install-scripts btrfs-progs pyalpm sudo reflector python-commonmark wget xcb-util-wm fmt && \
	pacman --noconfirm -S --needed git && \
	echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
	useradd build -G wheel -m && \
	su - build -c "git clone https://aur.archlinux.org/pikaur.git /tmp/pikaur" && \
	su - build -c "cd /tmp/pikaur && makepkg -f" && \
	pacman --noconfirm -U /tmp/pikaur/pikaur-*.pkg.tar.zst

# Add a fake systemd-run script to workaround pikaur requirement.
RUN echo -e "#!/bin/bash\nif [[ \"$1\" == \"--version\" ]]; then echo 'fake 244 version'; fi\nmkdir -p /var/cache/pikaur\n" >> /usr/bin/systemd-run && \
	chmod +x /usr/bin/systemd-run

RUN reflector --verbose --latest 20 --country "United States" --sort rate --save /etc/pacman.d/mirrorlist

# Add the project to the container.
ADD . /workdir

# Build pikaur packages as the 'build' user
ENV BUILD_USER "build"

ENV GNUPGHOME  "/etc/pacman.d/gnupg"

# Built image will be moved here. This should be a host mount to get the output.
ENV OUTPUT_DIR /output

WORKDIR /workdir
ENTRYPOINT ["/workdir/build.sh"]
CMD [$1, $2]
