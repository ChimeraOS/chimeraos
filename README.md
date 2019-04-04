# gamerOS

Experimental SteamOS alternative based on Arch Linux.

## Why gamerOS?

The project's main goal is to build a flexible, hassle-free gaming operating system that combines the best of both worlds.

gamerOS allows you to:
* easily add additional software, such as emulators, and keep them updated
* keep your drivers always updated
* use a modified SteamOS compositor which fixes some issues that the vanilla SteamOS comes with

## Getting started

These instructions will help you get gamerOS working on your main machine.

### Prerequisites

* A wired connection is highly recommended.
* **5GB** of free hard drive space is required for the base system.
* In order to ensure the smooth operation of gamerOS, **4GB or more** RAM is recommended.

### Installing
* Flash the Arch linux installation media on a USB drive.
* Make sure that you're connected to a network, consult the [Arch Linux Wiki](https://wiki.archlinux.org/index.php/Network_configuration) for help.
* Download the install script with the following command:

```bash
wget https://raw.githubusercontent.com/alkazar/gamer-os/master/install.sh && chmod +x install.sh`
```

* Run `./install.sh <target device>`. All the available devices can be seen by executing the command `fdisk -l`. 
* Once setup is complete, restart the computer.
* after restarting you will be presented with the SteamOS setup wizard and then Steam will start in big picture mode

You can open a TTY shell by using the keyboard combination `CTRL + ALT + F2` at any given moment. The default username is `gamer`, while the default password is `gamer`. You can switch back to Big Picture mode by pressing `CTRL + ALT + F7`.

## Discord

You can join our community Discord [here](https://discord.gg/brdNSUQ)!
