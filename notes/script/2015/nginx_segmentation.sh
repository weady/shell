#!/bin/bash
#
#This is script is used to segmentation nginx's log
#
backup_log_dir="/usr/local/nginx/logs/back_log"
[[ ! -d $backup_log_dir ]] && mkdir -p $backup_log_dir
logrotate -vf /etc/logrotate.d/nginx >/dev/null
date_time=`date -d "1 day ago" +%Y%m%d`
logs=`ls $backup_log_dir`
for log in $logs
do
	file=${log%%.*}
	mv $backup_log_dir/$log $backup_log_dir/$file.$date_time
	rm -rf $backup_log_dir/$log
done

