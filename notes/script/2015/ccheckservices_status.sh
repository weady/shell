#!/bin/bash
#
#This script is used to check cluster's homed services status!!!
#
# by wangdd 2015/9/1
#
#
log_path="/var/log/homed_check"
[[ ! -d $log_path ]] && mkdir -p $log_path
status_report="$log_path/cluster_report`date +%H:%M:%S`.report"
find $log_path -mmin +20 -type f -exec rm {} \;
service="redis db_router db_writer dtvs iacs ias iclnd icore iis ilogclient ilogmaster ilogslave imsgs ipuis ipwed isas itimers itts iuds iusa iusm tsg ulogs"
path="homed"
source ./allips.sh
if [ $# -eq 0 ];then
	source ./service_status_check.sh
	for ip in $slave_ips
	do
		ssh $ip  "source $path/service_status_check.sh" | tee -a $status_report
	done
elif [ $1 == "homed" ];then
	for srv in $service
	do
		eval tmp="$""$srv"_ips
		ips=`echo $tmp |sed 's/ /\n/g' | sort -u |head -n 1`
		for ip in $ips
		do
			ssh $ip "source $path/service_status_check.sh $srv" | tee -a $status_report
		done
	done
			
else
	tmp_srv=`echo $service | sed 's/ /\n/g' | grep $1`
	if [ $? -eq 0 ];then
		for srv in $1
		do
			eval temp="$""$srv"_ips
			list=`echo $temp | sed 's/ /\n/g' | sort -u`
			for ip in $list
			do
				ssh $ip "source $path/service_status_check.sh $srv" | tee -a $status_report
			done
	 	done	
	else
		echo "$1 is not homed's service,please check!"
		exit 0
	fi
fi
#Statistical success and error
E_num=`cat $status_report | egrep "ERROR" | wc -l`
if [ "$E_num" -gt 0 ];then
	E_LIST=`cat $status_report | egrep "ERROR"`
	echo "-------------" |tee -a $status_report
        echo -e "\033[40;31;5m ERROR $E_num \033[0m" | tee -a $status_report
        echo "-------------" | tee -a $status_report
        echo -e "\033[40;31m ERROR LIST: \033[0m" | tee -a $status_report
        echo "$E_LIST"
        echo -e  "\033[4m The Report Located In $status_report \033[0m"
fi
