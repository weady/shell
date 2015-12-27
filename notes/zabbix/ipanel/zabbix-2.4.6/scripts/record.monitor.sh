#!/bin/bash
#
#这个脚本是获取录流频道的文件大小，然后让zabbix根据大小是否变化进行判断录流是否正常
#
#
#
#获取频道的中文名
channel="$1"
now_time=`date +%y-%m-%d`
function get_channel_name(){
	dbip=`cat /homed/allips.sh | grep "export dtvs_mysql_ips" | awk -F '"' '{print $2}' | awk '{print $NF}'`
	user="root"
	password="123456"
	sql="set names utf8;select english_name from channel_store where chinese_name='$1'"
	tmp=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$sql"`
	english=`echo "$tmp" |grep -v "english_name"`
	
}
function check_record(){
	dbip=`cat /homed/allips.sh | grep "export tsg_mysql_ips" | awk -F '"' '{print $2}' | awk '{print $NF}'`
	user="root"
	password="123456"
	sql="set names utf8;select file_name from tsg_total_idx_$1 where finish_flag=0"
	tmp=`mysql -B -u$user -p$password -h$dbip homed_tsg -e "$sql"`
	file_name=`echo "$tmp" | grep -v "file_name"`
	path="/hdfshttpdownload/video/record/$1/$file_name"	
	result=`export HADOOP_ROOT_LOGGER="-INFO,NullAppender";/usr/local/hadoop/hadoop-1.2.1/bin/hadoop dfs -ls $path | grep '^-.*' | awk '{print $6}'`
	echo $result
}
get_channel_name "$channel"
check_record "$english"
