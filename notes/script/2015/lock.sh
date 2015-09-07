#!/bin/bash
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
