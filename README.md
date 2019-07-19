### WARNING
This is pre-release software and is not stable. Things may change at any time requiring a full re-install. Only install this at this point if you want to help with testing or are curious.

### KNOWN LIMITATIONS/ISSUES
 - cannot change user password
 - cannot set timezone
 - cannot connect via wifi
 - no support for intel graphics
 - support only for AMD gpus that work with the amdgpu driver

# gamerOS: the definitive couch gaming experience

## What is it?
gamerOS is an operating system focused exclusively on a couch gaming experience and can be thought of as an alternative to SteamOS.

## Features

### easy to install
boot into your new gaming system within minutes (work in progress)

### minimal
only what you need to play games and nothing more

### out of the box
start gaming right away with zero configuration

### always up to date
frequent updates delivering the latest drivers and software for an optimal experience

### seamless updates
fully automatic updates that run in the background without disrupting gameplay

### controller first
fully controller compatible interface with no mouse or keyboard required (but you can still use a mouse and keyboard if you like)

### use any controller
support for Xbox 360, Xbox One, DualShock 4, Switch Pro, Steam controllers and more (compatibility depends on game)

### play any game
out of the box support for playing NES, SNES, Genesis, N64, PlayStation, Wii, Steam, GOG, itch.io games and more (currently only Steam games are supported out of the box)


## Requirements
 - a wired internet connection
 - **10GB** or larger dedicated hard disk
 - **4GB** or more RAM


## Installation
 - [download](https://www.archlinux.org/download) and boot into the Arch Linux installer
 - make sure you are connected to the internet, consult the [Arch Linux Wiki](https://wiki.archlinux.org/index.php/Network_configuration) for help
 - download the gamerOS install script with the following command:
	`wget https://raw.githubusercontent.com/gamer-os/gamer-os/frzr/install.sh`
 - set executable permissions: `chmod +x install.sh`
 - run `./install.sh <target device>`; for a list of installation targets run `lsblk`
 - once setup is complete, restart the computer
 - after restarting you will be presented with the SteamOS setup wizard and then Steam will start in big picture mode
 - you can open a terminal by using the keyboard combination `ctrl + alt + f2` and log in with username `gamer` and password `gamer`; switch back to big picture mode by pressing `ctrl + alt + f7`


## Discord

You can join our community [here](https://discord.gg/brdNSUQ)!
