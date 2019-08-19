# Building gamerOS

To building and making changes to gamerOS is possible. This document contains some instructions on how to do so

# Build requirements

To be able to build gamer-os you to run **Arch Linux** on your system. Currently there are no plans to enable this on any other operating system.

The following packages will need to be installed to be able to build the gamer-os image:
- arch-install-scripts
- btrfs-progs
- [pikaur](https://aur.archlinux.org/packages/pikaur/)

# Building the gamerOS image

To build run the following command:
```
./build.sh channel version
```
Replace channel and version with your own. Channel should be a name and version a version number.
