#!/bin/bash

ISO=$1
if [ -z $ISO ]; then
   echo "usage:  $0 <iso_filename>" >&2
   exit 1
fi
if [ ! -f ${ISO} ]; then
   echo "ERROR:  ISO file (${ISO}) not found!" >&2
   exit 1
fi
[ -d z ] || mkdir z
sudo mount -o loop ${ISO} z
[ -d y ] && rm -fr y; mkdir y
shopt -s dotglob
rsync -avz z/* y
shopt -u dotglob
[ -d z ] && sudo umount z && rmdir z 
