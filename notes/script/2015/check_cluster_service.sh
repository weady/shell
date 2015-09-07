#!/bin/bash
#
#This script is used to check service locate which computer!
#
#	wangdd 2015/7/27
#	
#	soruce ./check_srv_id.sh "192.168.101.1-100" tsg/redis.....
#
homed_path="/homed"
source $homed_path/splitips.sh $1 --norepeat
myip="$last_split_ips"
for ip in $myip
do
	echo "==========Check $ip $2 Status=========="
	ssh $ip "source /etc/profile && ps -ef | grep -e $2 | grep -v grep"
done
