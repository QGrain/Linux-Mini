#!/bin/sh
cwd=`pwd`
ld_x86_64=/lib64/ld-linux-x86-64.so.2
source ./my-utils.sh

if [[ $1 ]]
then
    path=$1
else
    path=$cwd/initrdv0.9
fi

cp_lib() {
    ldd $1 | sed '1d' | awk '/\/lib64\//{print $3}' | while read lib
    do
        if [[ $lib ]]
        then
            if [[ ! -f $path$lib && $lib == *lib* ]]
            then
                echo "  copy $lib"
                cp $lib $path$lib
                cp_lib $lib
            else
                echo "  $lib is already copyed"
            fi
        fi
    done
    echo "finish dependency of $1"
}


create_dir $path/bin $path/sbin $path/usr/bin $path/usr/sbin $path/lib64 $path/usr/lib64


echo -e "copy ld-linux-x86_64.so.2"
if [[  ! -f $path$ld_x86_64 ]]
then
    echo "cp $ld_x86_64 $path$ld_x86_64"
    cp $ld_x86_64 $path$ld_x86_64
else
    echo "$path$ld_x86_64 already exist"
fi


cat $cwd/copy.list | while read one
do
    if [[ $one && ! -f $path/bin/$one && ! -f $path/sbin/$one && ! -f $path/usr/bin/$one && ! -f $path/usr/sbin/$one ]]
    then
        if [[ -f /bin/$one ]]
        then
            echo "copy /bin/$one ...... done"
            cp /bin/$one $path/bin/$one
            cp_lib /bin/$one
        elif [[ -f /sbin/$one ]]
        then
            echo "copy /sbin/$one ...... done"
            cp /sbin/$one $path/sbin/$one
            cp_lib /sbin/$one
        elif [[ -f /usr/bin/$one ]]
        then
            echo "copy /usr/bin/$one ...... done"
            cp /usr/bin/$one $path/usr/bin/$one
            cp_lib /usr/bin/$one
        elif [[ -f /usr/sbin/$one ]]
        then
            echo "copy /usr/sbin/$one ...... done"
            cp /usr/sbin/$one $path/usr/sbin/$one
            cp_lib /usr/sbin/$one
        else
            echo "cannot solve file: $one"
        fi
    else
        echo "*/$one is blank or already copyed"
    fi
done



echo -e "\ncheck dependency of /lib/udev/*"
ls $path/lib/udev | while read udevline
do
    if [[ $udevline == *.so* ]]
    then
         cp_lib $path/lib/udev/$udevline
    fi
done


echo -e "\ncheck the dependency of lib64/security files"
ls $path/lib64/security | while read secline
do
    cp_lib $path/lib64/security/$secline

done

#todo pam.d?

echo -e "\nCopy Finished Successfully!"