#!/bin/bash
#
#This is script is used to segmentation nginx's log
#
backup_log_dir="/usr/local/nginx/logs/back_log"
[[ ! -d $backup_log_dir ]] && mkdir -p $backup_log_dir
logrotate -vf /etc/logrotate.d/nginx >/dev/null 2>&1
date_time=`date -d "1 day ago" +%Y%m%d%T`
logs=`ls -l $backup_log_dir | grep "\.[0-9]$" | awk '{print $NF}'`
for log in $logs
do
	file=${log%.*}
	mv $backup_log_dir/$log $backup_log_dir/$file.$date_time
	rm -rf $backup_log_dir/$log
done

