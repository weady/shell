#!/bin/bash
#
#This script is used to put backup_file to ftp!
#
#	by wangdd 2015/9/18
#
#backupfile
backup_file="/etc /var/www"
dst_dir="/data2/wangdong/backup"
[[ ! -d $dst_dir ]] && mkdir -p $dst_dir
log_file="/var/log/back/`date +%Y-%m-%d-%T`_backup.log"
echo "Backup start at `date +%Y-%m-%d-%T` " |tee -a  $log_file
echo "------------------------------------------------" | tee -a $log_file
for dir in $backup_file
do
	cd $dst_dir
	pack_file=`date +%y-%m-%d`_${dir##*/}.tar.gz
	if [ -f $pack_file ];then
		echo "$dir haved been backup"
	else
		tar -Pczvf $pack_file $dir
	fi
done
echo "------------------------------------------------" |tee -a $log_file
echo "Backup finished at `date +%Y-%m-%d-%T`" | tee -a $log_file
##put backup_file to ftp
ftp_ip="ftp.xxx.cn"
username="xxxxxxx"
passwd="xxxxx"
cd $dst_dir
echo "Start put file to ftp at `date +%Y-%m-%d-%T`" | tee -a $log_file
echo "------------------------------------------------" |tee -a $log_file
ftp -ivn $ftp_ip  <<EOF 
user $username $passwd 
cd os
mput *.tar.gz
bye
EOF
echo "put ftp end at `date +%Y-%m-%d-%T`" | tee -a $log_file
##delete before N days files
#days=20
#find $dst_dir -type f -mtime +$days -name "*.tar.gz" | xargs rm -rf >/dev/null
#exit 0
##add to crontab
#echo "0 3 * * 6 /usr/local/src/script/put_backup_ftp.sh" >>/etc/crontab
#
