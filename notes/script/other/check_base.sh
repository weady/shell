#!/bin/bash
#
#This script is used to detection homed_base/bin/*.so and homed_base/bin/*.a file
#
#
#	by wangdd 2015/8/19
#
#
path="/homed"
source $path/all_service_deploy.sh
m_so_file=`find $path/homed_base/bin -maxdepth 1 -type f -name "lib*.so"`
#m_a_file=`find $path/homed_base/bin -maxdepth 1 -type f -name "lib*.a"`
m_bin_dir=`find $path/homed_base/bin -maxdepth 1 -type d | sed -n '2,$p'`

function check_base(){
	for file in $@
	do
		m_modify_time=`stat $file | grep Modify | awk -F. '{print $1}'`	
		for slave_ip in $all_running_srv_ips
		do
			s_modify_time=`ssh $slave_ip "stat $file | grep Modify | awk -F. '{print $'1'}'"`
			echo "***Start Check ${slave_ip}'s homed_base Status***" | tee -a $ver_check_log
			if [ "$m_modify_time" == "$s_modify_time" ];then
				echo "${slave_ip}'s $file Is Same With Master's!! updated" | tee -a $ver_check_log
			else
				if [ -z "$s_modify_time" ];then
					echo "ERROR!! ${slave_ip}'s $file is not exist!!" | tee -a $ver_check_log
				else
					echo "ERROR!! ${slave_ip}'s $file $s_modify_time || Master's $m_modify_time" | tee -a $ver_check_log
				fi
			fi
		done
	done
	shift
}
#
check_base "$m_so_file" "$m_bin_dir"

#Statistical success and error
#S_num_base=`cat $ver_check_log | egrep "updated" | wc -l`
E_num_base=`cat $ver_check_log | grep -e "ERROR" | wc -l`
E_LIST_base=`cat $ver_check_log | grep -e "ERROR"`
