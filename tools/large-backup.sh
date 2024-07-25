#! /bin/bash

function help(){
echo "
Usage full: large-backup.sh [options...]

arg1:mode - [full] create backup include filestore and database
arg2:data_dir - [~/.local/share/Odoo] Filestore location
arg3:pg_hostname
arg4:pg_port
arg5:pg_user
arg6:pg_pass
arg7:pg_db
arg8:backup_dir - [./]

Example: 
large-backup.sh full /home/$USER/.local/share/Odoo localhost 4390 user pass db /backups

"
}
function full(){
    data_dir="$1"
    pg_hostname="$2"
    pg_port="$3"
    pg_user="$4"
    pg_pass="$5"
    pg_db="$6"
    backup_dir="${7:-/tmp}"

    export PGPASSWORD="$pg_pass"

    filestore="$data_dir/filestore/$pg_db"
    if [ ! -d "$filestore" ]; then
        echo "Filestore no exists $filestore"
        exit 0
    fi
    echo "Filestore: $filestore"

    tmp_dir="$backup_dir/$pg_db"    
    if [ -d $tmp_dir ]; then
       rm -r $tmp_dir
    fi 
    mkdir -p "$tmp_dir"
    echo "Backup tmp: $tmp_dir"
    
    tmp_dir_dump="$tmp_dir/dump.sql"
    backup_file="$pg_db-$(date +"%Y%m%d%H%M").tar.gz"

    echo "Dump: $tmp_dir_dump"

    pg_dump -v --host "$pg_hostname" --port "$pg_port" --username "$pg_user" -w  -F p "$pg_db" > "$tmp_dir_dump"

    cp -r  $filestore $tmp_dir/
    cd $tmp_dir
    tar czvf "$backup_file" $(basename $filestore) $(basename $tmp_dir_dump)
    cd -
    rm -vr "$tmp_dir/$pg_db"
    rm $tmp_dir_dump
    echo "Backup file: $backup_file"
    counter=0
    for item in $(ls -t $tmp_dir/*.tar.gz)
    do
        ((counter++))
        if [ $counter -le 5 ]; then 
            continue
        fi
        rm $item
        echo "Remove old backup ($counter): $item"
    done
}


case $1 in
    "full")
        full "$2" "$3" "$4" "$5" "$6" "$7" "$8"
        ;;

    *)
        help
        ;;
esac    