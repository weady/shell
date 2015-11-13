#!/bin/bash 
#
#
#This script used to backup mysql_database
#
#
#	by wangdd 2015/9/24
#
#
db_host="192.168.36.130"
bk_user="zabbix"
user_pass="zabbixpass"
date_time=`date +%y-%m-%d`
bk_dst_dir="/data1/backup/mysql"
log_file="/var/log/db_backup.log"
[[ ! -d $bk_dst_dir ]] && mkdir -p $bk_dst_dir
ignore_db="mysql information_schema"
DBS=`mysql -u$bk_user -h$db_host -p$user_pass -Bse "show databases"`
#bakup db function
function backup_mysqldb(){
for db in $DBS 
do
	skipdb=-1 
	if [ "$ignore_db" != "" ];then
		for i in $ignore_db
		do
			[ "$db" == "$i" ] && skipdb=1 && echo "$i does't need backup!" >> $log_file
		done
	fi
	if [ "$skipdb" == "-1" ] ; then
		FILE="$bk_dst_dir/$db_host.$date_time.$db.sql"
		mysqldump -u$bk_user -h$db_host -p$user_pass $db >$FILE
		echo "$db backup success!" >> $log_file
	fi
done
#tar backup file
	cd $bk_dst_dir
	tar -czf $date_time.$db_host.tar.gz $db_host.$date_time*.sql
	[[ $? -eq 0 ]] && rm -rf $bk_dst_dir/$db_host.$date_time*.sql >> $log_file
}
backup_mysqldb
#
success=`cat $log_file | grep success`
no_backup=`cat $log_file | grep does`
echo "$success"
echo "$no_backup"
rm -rf $log_file
