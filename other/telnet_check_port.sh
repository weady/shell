#!/bin/bash
#
#	by wangdd 2018/03/26
#	这个脚本用于telnet 检测端口通讯情况

dest_ip=$1
dest_port=$2

local_ip=$(hostname -i)

check_result="/tmp/checkPort_result.log"

checkPort()
{
telnet $2 $3 <<! 1>$check_result 2>/dev/null
^]
close
!
ss=`cat $check_result | grep "Escape character is"`
if [ "A$ss" = "A" ]
then
printf "$1 登录 $2 的 $3 端口 "
printf '\033[7m'
printf "不可连接\n"
printf '\033[m'
return 1
else
printf "$1 登录 $2 的 $3 端口 "
printf "可连接\n"
return 0
fi
}

checkPort $local_ip $dest_ip $dest_port
if [ -f "$check_result" ];then
	rm -f $check_result
fi
