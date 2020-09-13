#!/bin/sh
source ./my-utils.sh

cwd=`pwd`
target_path=$cwd/initrd-1.0

prepare_100() {
    echo "Generating dir at $target_path"

    check_delete $target_path
    create_dir $target_path
    cd $target_path
    create_dir dev proc etc lib/modules sys root lib64 boot var/log var/run var/log var/lib var/empty var/lock/subsys temp home

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
    cp -r /etc/rc.d $target_path/etc/
    ln -s /etc/rc.d/init.d/ $target_path/etc/
    cp /etc/passwd /etc/group $target_path/etc/

    # copy login-related
    cp -r /etc/sysconfig $target_path/etc/
    cp -r /etc/pam.d /etc/security $target_path/etc/
    cp -r /lib64/security $target_path/lib64/
    cp /etc/shadow /etc/securetty $target_path/etc/

    # copy /sbin/init related
    cp -r /etc/init $target_path/etc/
    cp /etc/fstab /etc/mtab $target_path/etc/
    cp /etc/inittab $target_path/etc/
    # echo -e "T2:1:respawn:/sbin/mingetty /dev/tty2" >> $target_path/etc/inittab
    # echo -e "T1:134:respawn:/bin/login" >> $target_path/etc/inittab
    ln -s /etc/rc.d/rc* $target_path/etc/
    cp /etc/system-release $target_path/etc/

    # copy xtables
    cp -r /lib64/xtables $target_path/lib64/

    # copy network related
    cp -r /etc/dhcp $target_path/etc/
    cp /etc/protocols /etc/services $1/etc/
    
    echo '#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
export PS1="[\s-\v] \w \$ "

mknod /dev/null c 1 3
mount -t proc proc /proc > /dev/null 2>&1
mount -t sysfs sysfs /sys > /dev/null 2>&1

exec /sbin/init' > $target_path/init

    chmod 755 $target_path/init
}

generate_100() {
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
    echo -e "title CentOS (1.0 with all) [auto-gen]" >> $grub_path
    echo -e "\troot (hd0,0)" >> $grub_path
    echo -e "\tkernel /vmlinuz-5.3.9-mini ro root=UUID=$UUID" >> $grub_path
    echo -e "\tinitrd /$imgname" >> $grub_path

    if [[ -f /boot/grub/grub1.0.conf ]]
    then
        rm -f /boot/grub/grub1.0.conf
    fi
    cp $grub_path /boot/grub/grub1.0.conf
    
    echo -e "\n============================================================================\n"
    echo -e "Successfully generate /boot/grub/grub.conf, now you can reboot to enjoy it:)"
    echo -e "\n============================================================================\n"
}

prepare_100
generate_100