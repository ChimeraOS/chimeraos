FROM archlinux:base-devel
LABEL contributor="shadowapex@gmail.com"

# Allow multiple downloads
RUN sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

RUN echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /etc/pacman.conf && \
	pacman --noconfirm -Syyu && \
	pacman --noconfirm -S \
		arch-install-scripts \
		btrfs-progs \
		sudo \
		reflector \
		wget \
		xcb-util-wm \
		fmt \
		&& \
	pacman --noconfirm -S --needed git && \
	echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
	useradd build -G wheel -m

RUN reflector --verbose --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Run as the 'build' user
ENV BUILD_USER "build"

ENV GNUPGHOME  "/etc/pacman.d/gnupg"

# Built image will be moved here. This should be a host mount to get the output.
ENV OUTPUT_DIR /output

WORKDIR /workdir
ENTRYPOINT ["/workdir/build.sh"]
