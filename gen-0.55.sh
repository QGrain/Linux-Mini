#!/bin/sh
source ./my-utils.sh

cwd=`pwd`
target_path=$cwd/initrd-0.55

prepare_055() {
    echo "Generating dir at $target_path"

    check_delete $target_path
    create_dir $target_path
    cd $target_path
    create_dir dev proc etc lib/modules/kernel sys root var/log var/run

    # copy /lib/modules
    lib_list="scsi_transport_spi mptbase mptscsih mptspi cdrom sr_mod crc_t10dif sd_mod jbd2 mbcache ext4"
    for lib_mod in $lib_list
    do
        mod_path=`modinfo $lib_mod | awk '{print $2}' | sed -n '1,1p'`
        check_copy $mod_path $target_path/lib/modules/kernel
    done
    cp /lib/modules/2.6.32-431.el6.x86_64/modules.* $target_path/lib/modules/2.6.32-431.el6.x86_64/

    echo '#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
export PS1="[\s-\v] \w \$ "

insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/drivers/scsi/scsi_transport_spi.ko
insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/drivers/message/fusion/mptbase.ko
insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/drivers/message/fusion/mptscsih.ko
insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/drivers/message/fusion/mptspi.ko

insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/drivers/cdrom/cdrom.ko
insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/drivers/scsi/sr_mod.ko

insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/lib/crc-t10dif.ko
insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/drivers/scsi/sd_mod.ko

insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/fs/mbcache.ko
insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/fs/jbd2/jbd2.ko
insmod /lib/modules/2.6.32-431.el6.x86_64/kernel/fs/ext4/ext4.ko

mknod /dev/null c 1 3
mknod /dev/console c 5 1
mount -t proc proc /proc > /dev/null 2>&1
mount -t sysfs sysfs /sys > /dev/null 2>&1

mknod /dev/sda2 b 8 2

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

    if [[ ! -f /boot/grub/grub.conf.bak ]]
    then
        /bin/cp -f $grub_path /boot/grub/grub.conf.bak
    fi
    /bin/cp -f /boot/grub/grub.conf.bak $grub_path
    echo -e "title CentOS (0.55 with disk mounted) [auto-gen]" >> $grub_path
    echo -e "\troot (hd0,0)" >> $grub_path
    echo -e "\tkernel /vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=$UUID" >> $grub_path
    echo -e "\tinitrd /$imgname" >> $grub_path

    if [[ -f /boot/grub/grub0.55.conf ]]
    then
        rm -f /boot/grub/grub0.55.conf
    fi
    cp $grub_path /boot/grub/grub0.55.conf
    
    echo -e "\n============================================================================\n"
    echo -e "Successfully generate /boot/grub/grub.conf, now you can reboot to enjoy it:)"
    echo -e "\n============================================================================\n"
}

prepare_055
generate_055