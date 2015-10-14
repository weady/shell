#!/bin/bash
#
#this script used to get monitor items name
#
#	wangdd 2015/10/9

#pro_name=`ps -e -o 'comm,pcpu,rsz' | awk '{print $1}' | sort -u | awk -F".exe" '{print $1}'`

pro_name=`ps -e -o 'comm,pcpu,rsz' | awk -F '.' '{print $1}' | sort -u | awk '{print $1}'`
COUNT=`echo "$pro_name" |wc -l`
INDEX=0
echo {'"data"':[
	echo "$pro_name" | while read LINE; 
		do
    			echo -n '{"{#HOMEDNAME}":"'$LINE'"}'
    			INDEX=`expr $INDEX + 1`
    			if [ $INDEX -lt $COUNT ]; then
        			echo ","
    			fi
		done
	echo ]}

