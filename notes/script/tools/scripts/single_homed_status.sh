#!/bin/bash
#
#	by wangdd 2015/6/25 
#这个脚本主要是监测单机版Homed服务是否正常启动
path="/homed"
find_start_process=`grep "^_.*" $path/start.sh | awk -F" " '{print $5}' | awk -F"['.]" '{print $2}' | sed '/^$/d' | sort -u`
#---------------------------------------------------------------------------------------------------
function process_status(){
for process in $@
do
        command01=`ps -ef | grep "$process.*exe" | awk -F' ' '{print $8}' | awk -F'/' '{print $2}'`
	command02=`netstat -unltp | grep -E "LI.*$process"`
	proc_count=`netstat -unltp | grep -E "LI.*$process" | wc -l`
        if [ ! -z "$command01" ] && [ ! -z "$command02" ] && [ $proc_count -gt 1 ];then
		echo "----------------------------------------------------"
		echo "	Hostname is `hostname`|The $process process is running	  "  
                #echo "$command02"
        else
                echo "ERROR! `hostname` $process is not running,Please Check!"
        fi
done
shift
}
#---------------------------------------------------------------------------------------------------
#
if [ $# -eq 0 ];then
	process_status $find_start_process 
else
	process_status $@
fi	
