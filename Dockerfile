FROM archlinux:base-devel
LABEL contributor="shadowapex@gmail.com"

# Freeze if required
COPY freeze.sh manifest /

RUN chmod +x freeze.sh && ./freeze.sh

# Build pikaur packages as the 'build' user
ENV BUILD_USER "build"

ENV GNUPGHOME  "/etc/pacman.d/gnupg"

# Built image will be moved here. This should be a host mount to get the output.
ENV OUTPUT_DIR /output

WORKDIR /workdir
ENTRYPOINT ["/workdir/build.sh"]
