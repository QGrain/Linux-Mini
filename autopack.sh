#!/bin/sh
source ./my-utils.sh

cwd=`pwd`
if [[ $1 ]]
then
    path=$1
    imgname=$(echo $path | sed -e 's/\/[^ ]*\///g').img
else
    path=$cwd/initrdv0.9
    imgname=initramfsv0-9.img
fi

check_delete /boot/$imgname

cd $path

find . -print0 | cpio --null -ov -H newc | gzip -9 > /boot/$imgname

size=`ls -lh /boot | grep $imgname | awk '{print $5}'`
echo "Packup Success at /boot/$imgname, with size of $size"