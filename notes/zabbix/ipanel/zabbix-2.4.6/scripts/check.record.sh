#!/bin/bash
#
#这个脚本是获取录流的频道信息，为后面的监控提供监控的录流频道
#
#	wangdd 2015/12/17

#录流频道的信息位于homed_dtvs库的t_record_channel_info表中，并且f_record_udp_need_record=1表示启用录流功能
#信息的获取从dtvs的从库中获取，从库的Ip地址根据/homed/allip.sh文件过滤

#
dbip=`cat /homed/allips.sh | grep "export dtvs_mysql_ips" | awk -F '"' '{print $2}' | awk '{print $NF}'`
user="root"
password="123456"
sql="select f_record_udp_dir from t_record_channel_info where f_record_udp_need_record=1;"
channel_name=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$sql"`
en_name=`echo "$channel_name" | sed 's/ /\n/g' | grep -v "f_record_udp_dir" |sed 's/\n/ /g'`
for name in $en_name
do
        tmp_sql="set names utf8;select chinese_name from channel_store where english_name='$name'"
        tmp+=`mysql -B -u$user -p$password -h$dbip homed_dtvs -e "$tmp_sql"`
        #china_name+=`echo "$tmp," |grep -v "chinese_name"`
done
zb_name=`echo "$tmp" | sed 's/chinese_name/\n/g' | sed '/^$/d' | sed 's/\n/ /g'`
COUNT=`echo "$zb_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$zb_name" | while read LINE; 
		do
    			echo -n '{"{#CHANNELNAME}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

