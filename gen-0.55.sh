#!/bin/sh
source ./my-utils.sh

cwd=`pwd`
target_path=$cwd/initrd-0.55

prepare_055() {
    echo "Generating dir at $target_path"

    check_delete $target_path
    create_dir $target_path
    cd $target_path
    create_dir dev proc etc lib/modules sys root var/log var/run

    # copy /lib/modules
    cp /lib/modules/2.6.32-431*/modules.* lib/modules/
    cp -r /lib/modules/2.6.32-431*/kernel lib/modules/

    echo '#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
export PS1="[\s-\v] \w \$ "
modprobe ext4
modprobe sd_mod
modprobe sr_mod

mount -t proc proc /proc
mount -t sysfs sysfs /sys

mknod -m 0666 /dev/sda b 8 0
mknod -m 0666 /dev/sda1 b 8 1
mknod -m 0666 /dev/sda2 b 8 2
mknod -m 0666 /dev/sda3 b 8 3

mount -t ext4 /dev/sda2 /root
/bin/bash' > $target_path/init

    chmod 755 $target_path/init
}

generate_055() {
    cd $cwd
    ./autocopy.sh $target_path
    ./autopack.sh $target_path

    UUID=$(ls -l /dev/disk/by-uuid | grep sda2 | awk '{print $9}')
    grub_path=/boot/grub/grub.conf
    imgname=$(echo $target_path | sed -e 's/\/[^ ]*\///g').img

    rm -f $grub_path
    cp /boot/grub/grub.conf.bak $grub_path
    echo -e "title CentOS (0.55 with disk mounted) [auto-gen]" >> $grub_path
    echo -e "\troot (hd0,0)" >> $grub_path
    echo -e "\tkernel /vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=$UUID" >> $grub_path
    echo -e "\tinitrd /$imgname" >> $grub_path
    cp $grub_path /boot/grub/grub0.55.conf
    
    echo -e "\nSuccessfully generate /boot/grub/grub.conf, now you can reboot to enjoy it:)"
}

prepare_055
generate_055