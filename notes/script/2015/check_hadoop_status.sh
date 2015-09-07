#!/bin/bash
#
#This script is used to check Hadoop Stauts!
#
#	wangdd 2015/7/27
#	
# 	bash check_hadoop_status.sh 192.168.1.1-10
#
homed_path="/homed"
source $homed_path/splitips.sh $1 --norepeat
myip="$last_split_ips"
for ip in $myip
do
	echo "==========Check $ip Hadoop Status=========="
	ssh $ip "source /etc/profile && jps | grep '[a-z]$'"
done
