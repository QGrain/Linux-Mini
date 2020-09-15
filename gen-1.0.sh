#!/bin/sh
source ./my-utils.sh

cwd=`pwd`
target_path=$cwd/initrd-1.0
# KERNEL=2.6.32-431.el6.x86_64
KERNEL=5.3.9

prepare_100() {
    echo "Generating dir at $target_path"

    check_delete $target_path
    create_dir $target_path
    cd $target_path
    create_dir dev proc etc lib/modules sys root lib64 boot var/log var/run var/log var/lib var/empty var/lock/subsys temp home

    # copy /lib/modules
    cp -r /lib/modules/$KERNEL $target_path/lib/modules/

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
    ln -s /etc/rc.d/rc* $target_path/etc/
    cp /etc/system-release $target_path/etc/
    echo 'My microlinux based on CentOS6.5' > $target_path/etc/system-release

    # copy xtables and fix en_US.UTF-8 warning
    cp -r /lib64/xtables $target_path/lib64/
    echo "LC_ALL=C" >> $target_path/etc/sysconfig/i18n
    echo "export LC_ALL" >> $target_path/etc/sysconfig/i18n

    # copy network/ssh related
    cp -r /etc/dhcp $target_path/etc/
    cp /etc/protocols /etc/services $target_path/etc/
    cp -r /etc/ssh /etc/ld.so.cache /etc/ld.so.conf /etc/ld.so.conf.d /etc/profile.d $target_path/etc/
    create_dir var/empty/sshd
    cp -r /etc/NetworkManager /etc/profile $target_path/etc
    echo "export TERM=xterm" >> $target_path/etc/profile
    echo 'Port 22
ListenAddress 0.0.0.0
ListenAddress ::
PermitRootLogin yes' >> $target_path/etc/ssh/sshd_config


    echo '#!/bin/bash
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH
export PS1="[\u@\h][zzy-bash] \w # "
mount -t proc proc /proc
mount -t sysfs sysfs /sys

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
    echo -e "\tkernel /vmlinuz-$KERNEL ro root=UUID=$UUID" >> $grub_path
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