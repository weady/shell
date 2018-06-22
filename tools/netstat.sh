#!/bin/bash

netstat() {
	if [ $1 = "established_total" ];then
		established_total=$(/bin/netstat -nat | awk '{print $6}' | sort | uniq -c | sort -rn | head -n1 | awk '{print $1}')
		if [ -n "$established_total" ];then
			echo "$established_total"
		else
			echo 0
		fi
	elif [ $1 = "established_tcp" ];then
		established_tcp=$(/bin/netstat -an | awk '/^tcp/ {++S[$NF]};END {for(a in S) print a, S[a]}' | sort -n | awk '{print $2}' | head -n1)
		if [ -n "$established_tcp" ];then
			echo "$established_tcp"
		else
			echo 0
		fi
	elif [ $1 = "time_wait" ];then
		time_wait=$(/bin/netstat -nat | grep "TIME_WAIT" | awk '{print $5}' | awk -F: '{print $1}' | awk -F: '{++S[$1]};END {for(a in S) print a, S[a]}' | awk '{print $2}' | sort -rn | head -n1)
		if [ -n "$time_wait" ];then
			echo "$time_wait"
		else
			echo 0
		fi
	elif [ $1 = "tcp_80" ];then
		tcp_80=$(/bin/netstat -anlp|grep 80|grep tcp|awk '{print $5}'|awk -F: '{print $1}'|sort|uniq -c|sort -nr|head -n1 | awk '{print $1}')
		if [ -n "$tcp_80" ];then
			echo "$tcp_80"
		else
			echo 0
		fi
	elif [ $1 = "syn" ];then
		syn=$(/bin/netstat -an | grep SYN | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -n1 | awk '{print $1}')
		if [ -n "$syn" ];then
			echo "$syn"
		else
			echo 0
		fi
	else
		echo 0
	fi
}


netstat $1