#!/bin/bash
#
#This scripts used to monitor physical disk status
#
#	by wangdd 2015/11/26
#
#
path="/usr/local/zabbix/logs"
#check raid status
function raid_status(){
online=`cat $path/online.log | grep "Online"`
fail=`cat $path/fail.log | egrep "Failed|Rebuild"`
if [ -z "$fail" ];then
	echo "$online"
else
	echo "Error:$fail"
fi
}
#check physical disk status
OK=""
Error=""
function P_disk_status(){
Error=`cat $path/disk.error.log`
OK=`cat $path/disk.ok.log`
		if [ -n "$Error" ];then
			echo "$Error"
		else	
			echo "$OK"
		fi
	
}
#main
case $1 in
	raid)
		raid_status
		;;
	disk)
		P_disk_status
		;;
	*)
		echo "Error Input:"
esac
