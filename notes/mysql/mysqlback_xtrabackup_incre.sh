#!/bin/bash
set -e

innobackupex='/usr/bin/innobackupex'
back_dir='/data/back'
back_history='/data/back_history'
user='bkpuser'
passwd='123456'
log='/var/log/innobackupex.log'
backup_list='/tmp/history.txt'

if [ ! -d "$back_dir" ];then
	mkdir $back_dir
fi

if [ ! -d "$back_history" ];then
    mkdir $back_history
fi

#首次全备
cd $back_dir
if [ `ls | wc -l` -eq 0 ];then
	rm -f $log
	innobackupex --user=$user --password=$passwd $back_dir 2>> $log
	tail -n 1  $log
	current_dir=`ls $back_dir`
	echo $current_dir >> /$backup_list
	/bin/cp -arp $current_dir $back_history/	
	cd $back_history
	tar zcf new1.tar.gz $current_dir
	rm -rf $current_dir

#获取历史备份中最新的那一个
else
	base_dir=`tail -n 1 $backup_list`
		
#增量备份
	innobackupex --user=$user --password=$passwd --incremental --incremental-basedir=$back_dir/$base_dir $back_dir 2>> $log
	rm -rf $base_dir
	current_dir=`ls $back_dir`
	echo $current_dir >> /$backup_list
	/bin/cp -arp $current_dir $back_history/
	cd $back_history
	num=`cat $backup_list| wc -l`	
	tar zcf new$num.tar.gz $current_dir
	rm -rf $current_dir
	
	tail -n 1  $log
	echo '历史备份记录'
	echo :`cat $backup_list`
fi