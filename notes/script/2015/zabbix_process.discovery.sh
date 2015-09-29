#!/bin/bash
log_path="/usr/local/zabbix/logs"
pro_name=`tail -n +8 $log_path/top.txt | sed '/^$/d' | awk '{name[$NF]+=$9}END{for(key in name) print key,name[key]}' | sort -gr -k 2 | head |awk '{print $1}'`
COUNT=`echo "$pro_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$pro_name" | while read LINE; 
		do
    			echo -n '{"{#TABLENAME}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

