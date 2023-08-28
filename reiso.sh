#!/bin/bash

UNAME=$(whoami)
ISO=$1
if [ -z $ISO ]; then
   echo "usage:  $0 <new_custom_iso_filename_to_create>" >&2
   exit 1
fi
pushd y
sudo mkisofs -o ../${ISO} -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V "Custom ISO" .
popd
sudo chown ${UNAME}:${UNAME} ${ISO}
[ -d y ] && sudo rm -fr y 
