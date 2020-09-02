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