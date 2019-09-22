# Building GamerOS

This document contains instructions on how to build, install and ship a new GamerOS image.

# Build requirements

Building the GamerOS image can currently only be done on **Arch Linux**.

The following packages will need to be installed to be able to build the GamerOS image:
- arch-install-scripts
- btrfs-progs
- [pikaur](https://aur.archlinux.org/packages/pikaur/) (not available in the official repo)

Additionally the multilib repository needs to be enabled in ``/etc/pacman.conf``.

# Building the GamerOS image

To build the image, run the following command:
```
./build.sh <channel> <version>
```
Replace `<channel>` and `<version>` with your own values. Channel should be a name and version, the version number. Neither the name nor the version should include a hyphen (`-`) character.

# Preparing for installation of the image

To be able to install the generated image file (`<channel>-<version>.img.tar.xz`) it will need to be uploaded to a location which is accessible to the GamerOS system on which it will be installed. This can be a webserver or on the GamerOS system itself. In addition, a manifest file needs to be created.

The manifest file contains all the information required for the imaging tool [frzr](https://github.com/gamer-os/frzr) to install the image. It can only be read if it has the following format:
```
channel
version image_url checksum
```

- The channel, or name of the image goes on the top line of the file. This has to match the channel name used when building the image.
- Each subsequent line is made up of the version number, the image url and the image checksum, separated by a single tab.
- The version number has to match the version used when building the image.
- The image_url should point to the tar.xz compressed image. It must either be a url or an absolute path formatted like file:///root/image.tar.xz
- The checksum is generated with the ``sha256sum`` command.
- The frzr autoupdate script determines the version to install by looking at the last line in the manifest file. An update only happens if the channel or version does not match the currently running frzr deployment.

# Installing the image

Installing the image on the target machine is done with the [frzr](https://github.com/gamer-os/frzr) tool. It can install from either a local manifest file or one which is hosted online. It is assumed here that these instructions are executed on a GamerOS machine.

The image can be installed with the following command (**Which can destroy all your data! Don't run this if there is important data on your machine!**):
```
sudo frzr-deploy manifest_url
```
Replace ``manifest_url`` with either the url to the image or with ``"file:///path/to/manifest"``.

Now reboot the system and the new image should be used.

# Creating an ISO which installs the image

GamerOS ships an ISO which installs the latest GamerOS image on a system. Installing custom images is also possible.

Creating an ISO which uses a different image requires the following steps:

- Clone the [GamerOS install-media repo](https://github.com/gamer-os/install-media) with git
- Change the url in the following line of the file ``install-media/gamer-os/airootfs/root/install.sh`` to the location of the manifest file created in the previous step (adding it to the airootfs directory will make it available on the ISO):
```
if ! frzr-deploy https://gamer-os.github.io/gamer-os/repos/default; then
```
- Follow the instructions in the [README](https://github.com/gamer-os/install-media/blob/master/README.md) of the install-media repo to build the ISO
