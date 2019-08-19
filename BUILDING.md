# Building gamerOS

This document contains instructions on how to build, install and ship a new gamerOS image.

# Build requirements

Building the gamerOS image can currently only be done on **Arch Linux**.

The following packages will need to be installed to be able to build the gamerOS image:
- arch-install-scripts
- btrfs-progs
- [pikaur](https://aur.archlinux.org/packages/pikaur/) (not available in the official repo)

# Building the gamerOS image

To build run the following command:
```
./build.sh channel version
```
Replace channel and version with your own. Channel should be a name and version a version number.

# Preparing for installation of the image

To be able to install the generated image file (channel-version.img.tar.xz) it will need a location which is available to the gamerOS system on which it will be installed. This can be on webserver or on the gamerOS system itself. In addition to that a manifest file needs to be created.

The manifest file contains all the information required for the imaging tool [frzr](https://github.com/gamer-os/frzr) to install the image. It can only be read if it has the following format:
```
channel
version image_url   checksum
```

To summarize:

- The channel, or name of the image goes on the top line of the file. This has to match the channel used when building the image
- The version number comes first one the bottom line of the file. This has to match the version used when building the image
- The image_url should comes second on the bottom line of the file. Only .tar.xz compressed images are supported. It should either be the either a url or an absolute path formatted like file:///root/image.tar.xz
- The checksum of the image should comes third on the bottom line of the file. Generate this with the ``sha256sum`` command
- The version, img_url and checksum are seperated with tabs

So replace ``channel``, ``version``, ``image_url`` and ``checksum`` with the values for the image. Installing will only work if the version or channel is different from what is currently installed on the target machine.

# Installing the image

Installing the image on the target machine is done with the [frzr](https://github.com/gamer-os/frzr) tool. It can install from either a local manifest file or one which is hosted online. It is assumed here that these instructions are executed on a gamerOS machine.

The image can be installed with the following command (**Which can destroy all data on the machine! Don't run this if there is important data on the machine!**):
```
sudo frzr-deploy manifest_url
```
Replace ``manifest_url`` with either the url to the image or with ``"file:///path/to/manifest"``.

Now reboot the system and the new image should be used.

# Creating an ISO which installs the image

GamerOS ships an ISO which installs the latest gamerOS image on a system. This can be done for custom images as well.

Creating an ISO which uses a different image requires the following steps:

- Clone the [gamerOS install-media repo](https://github.com/gamer-os/install-media) with git
- Change url the following line in the file ``install-media/gamer-os/airootfs/root/install.sh`` to the location of the manifest file created in the previous step (adding it to the airootfs directory will make it available on the ISO):
```
if ! frzr-deploy https://gamer-os.github.io/gamer-os/repos/default; then
```
- Follow the instructions in the [README](https://github.com/gamer-os/install-media/blob/master/README.md) of the install-media repo to build the ISO
