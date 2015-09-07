#!/bin/bash
#
#This script is used to check start.sh file in cluster everyone computer!
#
#	wangdd 2015/8/2
#
#	bash check_srv_id.sh 192.168.35.99-100
#	
#
homed_path="/homed"
source $homed_path/splitips.sh $1 --norepeat
myip="$last_split_ips"
#list="s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15 s16 s17 s18 s19 s20 s21 s22 s23 s24 s25 s26 s27 s28 s29 s30 s31 s32 s33 s34"
for ip in $myip
do
	echo "==========Check $ip Status=========="
	ssh $ip "source /etc/profile && grep -e '^_restart' /homed/start.sh"
done
