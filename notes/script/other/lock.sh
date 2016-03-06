#!/bin/bash
#
#这个脚本是限定某个脚本文件，只有一个在运行
#	by wangdd 2016/03/07

lockfile="/tmp/$(basename $0).lockfile"
if [ -f $lockfile ];then
	mypid=$(cat $lockfile)
	ps -p $mypid | grep $mypid &>/dev/null
	[ $? -eq 0 ] && echo "the script is running" && exit 1
else
	echo $$ > $lockfile
fi
echo "running"
read
echo "stop"
rm -rf $lockfile
