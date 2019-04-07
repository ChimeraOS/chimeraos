# gamerOS

This is a fully automated install script that creates an immediately usable TV gaming experience based on Arch Linux. The only interface is Steam big picture mode.
It can be thought of as an alternative to SteamOS.

The ultimate goal of gamerOS is to be hands down the best and easiest way to play games with a controller on your TV. You should be able to play any Linux, Windows, or console game for which emulation is possible, out of the box with no configuration required.

gamerOS is nowhere near its stated goal and is currently highly experimental. After installing you will have a basic Arch Linux install that is able to play Steam games in Steam big picture mode.

### SteamOS is great, but gamerOS allows you to:
 - easily add additional software, like emulators and keep them up to date
 - fixes some issues with Proton that SteamOS exhibits, including mouse based games being unplayable
 - easy access to the latest graphics drivers
 - out of the box installation of a modified SteamOS compositor which fixes some Linux native games, including Dead Cells

### Some downsides compared to SteamOS:
 - there is some loss of compatibility for games; it is a trade off, same games work on SteamOS, but not on gamerOS, and vice versa
 - no desktop mode but you can of course install a desktop after the fact, however, switching to desktop mode through the SteamOS menus will not work
 - updating the system must be done manually through the command line as opposed to SteamOS where it is done automatically

## Requirements
 - a dedicated computer with a single hard disk
 - for easiest installation, a wired network connection is highly recommended
 - a single monitor/TV
 - at least 5GB of disk space for the base system, but you will need a lot more to install games
 - a 3D graphics card: Intel/AMD/NVIDIA; NVIDIA binary driver is installed automatically if an NVIDIA card is detected during installation, otherwise, open source drivers are used

## Installation instructions
 - download and boot the Arch linux install media
 - make sure networking is working, consult the Arch Linux wiki for help
 - download the install script with the following command:
	`wget https://raw.githubusercontent.com/alkazar/gamer-os/master/install.sh`
 - set executable permissions: `chmod +x install.sh`
 - run `./install.sh <target device>`, specifying the installation device
 - wait about 10 minutes or more depending on your internet connection for everything to install
 - once setup is complete, restart the computer
 - after restarting you will be presented with the SteamOS setup wizard and then Steam will start in big picture mode
 - to perform maintenance, you can open a terminal by connecting a keyboard and pressing `ctrl-alt-f2`
 - you can log in to the terminal with the user name `gamer` and the password `gamer`
 - switch back to big picture mode by pressing `ctrl-alt-f7`

## Planned improvements
 - fully automated and safe updates
 - a clean boot experience
 - automatic tweaks for native and proton games for out of the box usage in big picture mode
 - preinstalled emulators and automatic addition of emulated games to Steam

## Discord

https://discord.gg/brdNSUQ
