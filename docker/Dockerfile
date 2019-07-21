#Dockerfile for building VaporOS Desktop
#Based on Arch

FROM archlinux/base
MAINTAINER Wouter Wijsman

#Install archiso
RUN yes | pacman -Syuu grep file archiso
RUN mkdir -p /root/gamer-os/out

#set working dir, you'll have to mount something yourself here
WORKDIR /root/gamer-os

#Copy archiso files from this git repo
ADD gamer-os /root/gamer-os
