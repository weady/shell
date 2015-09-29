#!/bin/bash
log_path="/usr/local/zabbix/logs"
process=$1
name=$2
case $2 in
mem)
echo "`tail -n +8 $log_path/top.txt | awk '{a[$NF]+=$6}END{for(key in a)print key,a[key]}' | grep $1 | awk '{print $2}'`"
;;
cpu)
echo "`tail -n +8 $log_path/top.txt | awk '{a[$NF]+=$9}END{for(key in a)print key,a[key]}' | grep $1 | awk '{print $2}'`"
;;
*)
echo "Error input:"
;;
esac
exit 0
