FROM archlinux:base-devel
LABEL contributor="shadowapex@gmail.com"

# Freeze if required
COPY freeze.sh own-pkg.sh manifest /
COPY pkgs /pkgs

RUN chmod +x freeze.sh && ./freeze.sh
# Build pikaur packages as the 'build' user
ENV BUILD_USER "build"

ENV GNUPGHOME  "/etc/pacman.d/gnupg"
RUN chmod +x own-pkg.sh && ./own-pkg.sh

# Built image will be moved here. This should be a host mount to get the output.
ENV OUTPUT_DIR /output

WORKDIR /workdir
ENTRYPOINT ["/workdir/build.sh"]
