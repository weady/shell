#!/bin/bash
for ((i=1,i<4,i++)); 
do
	#if语句用于定义homed的服务IP
	if [ $i -eq 1 ]; then	
	#statements
		elif [ $i -eq 2 ]; then
			#statements
	else
		else语句
	fi
	#for循环用于检测homed服务的状态，通过api接口检测,要监控几个服务就定义几个for循环
	#eg:wget --tries=2 --timeout=5 -q "http://$srv:12690/getIaps" -O reiacs
	for srv in $srvlist; do
		#statements
	done



done
