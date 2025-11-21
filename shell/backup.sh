#! /bin/bash

set -e


if [ $# -lt 3 ]; then
    echo $0: Missing arguments
    echo usage: $0 restic-repo-passwd b2-account-key b2-account-id 
    exit 1
fi
export RESTIC_CACHE_DIR=/mnt/md0/nas/backup/.cache/restic
export TMPDIR="/mnt/md0/nas/backup/tmp/"
export RESTIC_PASSWORD=$1
export B2_ACCOUNT_KEY=$2
export B2_ACCOUNT_ID=$3

function log(){
	export log_path=$1
	export msg=$2
	echo "${msg}" >> $log_path 2>&1
	echo ${msg}
}

function log_start(){
	export log_path=$1
	export bucket=$2
	log $log_path ""
	log $log_path "=================================================="
	log $log_path " Backup started at: `date`"
	log $log_path " Backing up to ${bucket}..."
	log $log_path "=================================================="
}

function log_finish(){
	export log_path=$1
	log $log_path "=================================================="
	log $log_path " Backup finished at: `date`"
	log $log_path "=================================================="
	log $log_path ""
}

function do_backup(){
	export log_file=$1
	export bucket=$2
	export src_dir=$3
	export log_path=/mnt/md0/nas/backup/logs/$log_file
	log_start $log_path $bucket
	/opt/restic --cache-dir ${RESTIC_CACHE_DIR}  -r b2:$bucket backup $src_dir >> $log_path 2>&1
	log_finish $log_path 
}

# log '/tmp/who.txt' "This is who I am: [`whoami`]"

do_backup james-backup.log bucket-james /mnt/md0/nas/james/

do_backup photo-backup.log bucket-photo /mnt/md0/nas/photo/

do_backup music-backup.log bucket-music /mnt/md0/nas/music/

do_backup home-movies-backup.log bucket-home-movies /mnt/md0/nas/video/home_movies/

do_backup rachel-backup.log bucket-rachel /mnt/md0/nas/rachel/


# anacron

# sort the perms on rae's home dir
# sort the logging for crontab jobs - logs to nas dir

# https://askubuntu.com/questions/56683/where-is-the-cron-crontab-log/121560#121560

# 1 0 * * * /mnt/md0/nas/backup/backup.sh >> /mnt/md0/nas/backup/logs/backup.log 2>&1


