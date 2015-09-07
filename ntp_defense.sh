#
#This script is used to Defensive attack (NTP)
#
# by wangdd 2015/9/6
#

#!/bin/bash
source /homed/allips.sh
eval list="$"allips
ips=`echo $list | sed 's/ /\n/g' | sort -u`
for ip in $ips
do
	echo "-----------$ip------------------"
	ssh $ip "grep 'disable monitor' /etc/ntp.conf >/dev/null && echo "disable monitor Has been added" || echo "disable monitor" >>/etc/ntp.conf"
	if [ $? -eq 0 ];then
		echo "ok"
	else
		echo "false"
	fi
done

