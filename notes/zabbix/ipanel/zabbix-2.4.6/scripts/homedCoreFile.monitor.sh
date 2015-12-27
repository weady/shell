#!/bin/bash
#
#This scripts used to check homed core files
#
#	by liumz 2015/12/15
#
#这个脚本用于查找和发现homed程序的死机堆栈文件，提供数据源给zabbix监控。
#

process="$1"
path="/homed/$process/bin/"
if [ ! -d "$path" ];then
	echo "Search the dir does not exist!"
else
	result=`find $path -name "core.*"`
	COUNT=`echo $result | wc -l`
	if [ COUNT == 0 ];then
		echo "Did not find the core file!"
	else
		echo "find core file！"
	fi
fi

