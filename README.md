# gamerOS: the definitive couch gaming experience

## What is it?
gamerOS is an experimental installer script that, when run, results in a minimal Arch Linux system capable of playing Steam games in big picture mode out of the box. gamerOS has aspirations to be its own distribution focused exclusively on gaming and can be thought of as an alternative to SteamOS. 

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
support for Xbox 360, Xbox One, DualShock 4, Switch Pro, Steam controllers and more (game dependent)

### play any game
out of the box support for playing NES, SNES, Genesis, N64, PlayStation, Wii, Steam, GOG, itch.io games and more (currently only Steam games work out of the box)


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
