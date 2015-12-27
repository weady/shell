#!/bin/bash
#
#这个脚本用于检测homed各服务的api是否可以使用
#
# 	by wangdd 2015/12/16
#
#
#ports="11160 11190 11290 11390 11490 11690 11790 11890 11990 12390 12490 12690 12790 12890 12990 13150 13160 13190 13390 13590 17090"

function api_check(){
	path="/homed/$1/config"
	port=`cat $path/config.xml | grep local_port | sort -u | sed 's/.*>\(.*\)<.*$/\1/'`
	url="http://127.0.0.1:$port/monitorqueryprocessstatus"
	tmp="`curl -s $url`"
	result=`echo "$tmp" | grep ok`
	if [ -n "$result" ];then
		echo "$1 API is OK"
	else
		echo "$1 API Error"
	fi
}
if [[ ! "$1" =~ redis|db_* ]];then
	api_check "$1"
fi
