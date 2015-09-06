#!/bin/bash
#
#This script is used scp 192.168.101.104's file to 192.168.36.130
#
# wangdd 2015/7/10
#
des="/data1/wangdong"
source=$1
if [ ${source##*.} = "sh" ];then
	scp 192.168.101.104:$source $des/shell
else
	scp -r 192.168.101.104:$source $des
fi
