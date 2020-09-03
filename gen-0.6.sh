#!/bin/sh
source ./my-utils.sh

cwd=`pwd`
target_path=$cwd/initrd-0.6

prepare_060() {
    echo "Generating dir at $target_path"

    check_delete $target_path
    create_dir $target_path
    cd $target_path
    create_dir dev proc etc lib/modules sys root var/log var/run lib64

    # copy /lib/modules
    lib_list="scsi_transport_spi mptbase mptscsih mptspi cdrom sr_mod crc_t10dif sd_mod jbd2 mbcache ext4"
    for lib_mod in $lib_list
    do
        mod_path=`modinfo $lib_mod | awk '{print $2}' | sed -n '1,1p'`
        check_copy $mod_path $target_path
    done
    cp /lib/modules/2.6.32-431.el6.x86_64/modules.* $target_path/lib/modules/2.6.32-431.el6.x86_64/

    # copy /lib/udev, /etc/udev, /etc/nsswitch.conf, /lib/libnss*
    cp -r /lib/udev $target_path/lib/
    cp -r /etc/udev $target_path/etc/
    cp /etc/nsswitch.conf $target_path/etc/
    cp /lib64/libnss* $target_path/lib64/

    # fix some bugs of udev
    check_copy /etc/sysconfig/udev $target_path
    cp /etc/sysconfig/network $target_path/etc/sysconfig/
    cp -r /etc/rc.d/init.d $target_path/etc/
    cp /etc/passwd $target_path/etc/
    cp /etc/group $target_path/etc/
    
    echo '#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
export PS1="[\s-\v] \w \$ "

mknod /dev/null c 1 3
mknod /dev/console c 5 1
mount -t proc proc /proc > /dev/null 2>&1
mount -t sysfs sysfs /sys > /dev/null 2>&1

start_udev

mknod /dev/sda2 b 8 2
mount -t ext4 /dev/sda2 /root
/bin/bash' > $target_path/init

    chmod 755 $target_path/init
}

generate_060() {
    cd $cwd
    ./autocopy.sh $target_path
    ./autopack.sh $target_path

    UUID=$(ls -l /dev/disk/by-uuid | grep sda2 | awk '{print $9}')
    grub_path=/boot/grub/grub.conf
    imgname=$(echo $target_path | sed -e 's/\/[^ ]*\///g').img

    rm -f $grub_path
    cp /boot/grub/grub.conf.bak $grub_path
    echo -e "title CentOS (0.6 with udev) [auto-gen]" >> $grub_path
    echo -e "\troot (hd0,0)" >> $grub_path
    echo -e "\tkernel /vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=$UUID" >> $grub_path
    echo -e "\tinitrd /$imgname" >> $grub_path

    if [[ -f /boot/grub/grub0.6.conf ]]
    then
        rm -f /boot/grub/grub0.6.conf
    fi
    cp $grub_path /boot/grub/grub0.6.conf
    
    echo -e "\nSuccessfully generate /boot/grub/grub.conf, now you can reboot to enjoy it:)"
}

prepare_060
generate_060