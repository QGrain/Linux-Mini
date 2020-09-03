create_dir() {
    for arg in $@
    do
        if [[ ! -d $arg ]]
        then
            mkdir -p $arg
        fi
    done
}

create_file() {
    for arg in $@
    do
        if [[ ! -f $arg ]]
        then
            create_dir ${arg%/*}
            touch $arg
        fi
    done
}

check_delete() {
    for arg in $@
    do
        if [[ -d $arg ]]
        then
            rm -rf $arg
        elif [[ -f $arg ]]
        then
            rm -f $arg
        fi
    done
}

check_copy() {
    last_str=${1: -1}
    if [[ $last_str == '/' ]]
    then
        src_path=${1%?}
    else
        src_path=$1
    fi
    base_path=${src_path%/*}

    if [[ -d $src_path ]]
    then
        create_dir $2/$base_path
        cp -r $src_path $2/$base_path/
    elif [[ -f $src_path ]]
    then
        create_dir $2/$base_path
        cp $src_path $2/$base_path/
    fi
}