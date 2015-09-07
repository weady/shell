#!/bin/bash
#
#This script is used to check config.xml
#
#
#	by wangddd 2015/8/24
#
#
path="/homed"
services="db_router db_writer dtvs iacs ias iclnd icore iis ilogclient ilogmaster ilogslave imsgs ipuis ipwed isas itimers itts iuds iusa iusm tsg ulogs"
redis_config=`ls -tl $path/redis/config/*.conf| awk -F' ' 'NR>1 {print $NF}'`
m_config="$path/config_comm.xml"
source $path/all_service_deploy.sh
function check_xml(){
	for srv in $@
	do
		m_srv_config=`md5sum $path/$srv/config/config.xml`
		m_modify_time=`stat $path/$srv/config/config.xml | grep Modify | awk -F. '{print $1}'`
		list=$"$srv"_srv_ips
		echo "***Start Check ${srv}'s config.xml,Through Compare To Master's By MD5***" | tee -a $ver_check_log
		for ip in ${!list}
		do
			s_srv_config=`ssh $ip "md5sum $path/$srv/config/config.xml"`
			s_modify_time=`ssh $ip "stat $path/$srv/config/config.xml | grep Modify | awk -F. '{print $'1'}'"`
			if [ "$m_srv_config" == "$s_srv_config" ];then
				echo "$ip ${srv}'s config.xml update SUCCESS!!" | tee -a $ver_check_log
			else
				echo "ERROR!!$ip ${srv}'s config.xml $s_modify_time ||Master's $m_modify_time" | tee -a $ver_check_log
			fi
		done
	done
	shift
}
function check_redis_conf(){
	for redis_file in $@
	do
		m_redis_md5=`md5sum $redis_file`
		m_redis_time=`stat $redis_file | grep Modify | awk -F'.' '{print $1}'`
		if [ "$redis_file" == "/homed/config_comm.xml" ];then
			list="all_running_srv_ips"
		else
			list="redis_srv_ips"
		fi
		echo "***Start Check redis's *.conf,Through Compare To Master's By MD5***" | tee -a $ver_check_log
		for redis_ip in ${!list}
		do
			s_redis_md5=`ssh $redis_ip "md5sum $redis_file"`
			s_redis_time=`ssh $redis_ip "stat $redis_file | grep Modify | awk -F'.' '{print $'1'}'"`
			if [ "$m_redis_md5" == "$s_redis_md5" ];then
				echo "$redis_ip ${redis_file##*/}  update SUCCESS!!" | tee -a $ver_check_log
			else
				echo "ERROR!!$redis_ip ${redis_file##*/} $s_redis_time | Master's $m_redis_time" | tee -a $ver_check_log
			fi
		done
	done
	shift
}
#
check_xml "$services"
check_redis_conf $m_config $redis_config 




#Statistical success and error
#S_num_config=`cat $ver_check_log | egrep "run.*SUCCESS" | wc -l`
E_num_config=`cat $ver_check_log | egrep "ERROR" | wc -l`
E_LIST_config=`cat $ver_check_log | egrep "ERROR"`
