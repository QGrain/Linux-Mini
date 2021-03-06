#!/bin/sh
source ./my-utils.sh

cwd=`pwd`
target_path=$cwd/initrd-0.5

prepare_050() {
    echo "Generating dir at $target_path"

    check_delete $target_path
    create_dir $target_path
    cd $target_path
    create_dir dev proc etc lib sys root var/log var/run

    echo "#!/bin/sh" >> $target_path/init
    echo "export PATH=/bin:/sbin:/usr/bin:/usr/sbin:$PATH" >> $target_path/init
    echo "export PS1='[\s-\v] \w \$ '" >> $target_path/init
    echo "/bin/bash" >> $target_path/init
    chmod 755 $target_path/init
}

generate_050() {
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
    echo -e "title CentOS (0.5 with bash) [auto-gen]" >> $grub_path
    echo -e "\troot (hd0,0)" >> $grub_path
    echo -e "\tkernel /vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=$UUID" >> $grub_path
    echo -e "\tinitrd /$imgname" >> $grub_path

    if [[ -f /boot/grub/grub0.5.conf ]]
    then
        rm -f /boot/grub/grub0.5.conf
    fi
    cp $grub_path /boot/grub/grub0.5.conf

    echo -e "\n============================================================================\n"
    echo -e "Successfully generate /boot/grub/grub.conf, now you can reboot to enjoy it:)"
    echo -e "\n============================================================================\n"
}

prepare_050
generate_050