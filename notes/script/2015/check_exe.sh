#!/bin/bash
#
#
#
#This is script is used to check Homed's *.exe file
#
#       by wangdd 2015/8/15
#
#
path="/homed"
srv="redis db_router db_writer dtvs iacs ias iclnd icore iis ilogclient ilogmaster ilogslave imsgs ipuis ipwed isas itimers itts iuds iusa iusm tsg ulogs"
redis_exe="redis-cli redis-sentinel redis-server"
source $path/all_service_deploy.sh
function md5_compare(){
        for file in $@
        do
			if [ "$file" == "redis" ];then
				for redis_file in $redis_exe
				do
					m_modify_time=`stat $path/redis/bin/$redis_file.exe | grep Modify | awk -F. '{print $1}'`
					md5_m_redis=`md5sum $path/redis/bin/$redis_file.exe`
					    echo "***Start Check ${file}'s *.exe file ,Through Compare To Master's By MD5***" |tee -a $ver_check_log
                       			 for redis_ip in $redis_srv_ips
                                		do
							s_modify_time=`ssh $redis_ip "stat $path/redis/bin/$redis_file.exe | grep Modify | awk -F. '{print $'1'}'"`
                                        		md5_s_redis=`ssh $redis_ip "md5sum $path/redis/bin/$redis_file.exe"`
                                        		if [ "$md5_m_redis" == "$md5_s_redis" ];then
                                                		echo "  ${redis_ip}'s $redis_file.exe update SUCCESS!!   " |tee -a $ver_check_log
                                        		else
                                                		echo "ERROR!!${redis_ip}'s $redis_file.exe $s_modify_time || Master's $m_modify_time " |tee -a $ver_check_log
                                        		fi
                                		done
				done
			else
				m_exe_time=`stat  $path/$file/bin/$file.exe | grep Modify | awk -F. '{print $1}'`
                        	md5_master=`md5sum $path/$file/bin/$file.exe`
                        	list=$"$file"_srv_ips
                        	echo "***Start Check ${file}'s exe file ,Through Compare To Master's By MD5***" | tee -a $ver_check_log
                       		for ip in ${!list}
                                	do
						s_exe_time=`ssh $ip "stat $path/$file/bin/$file.exe | grep Modify | awk -F. '{print $'1'}'"`
                                        	md5_slave=`ssh $ip "md5sum $path/$file/bin/$file.exe"`
                                        	if [ "$md5_master" == "$md5_slave" ];then
                                                	echo "  ${ip-$file}'s $file.exe update SUCCESS!!       " | tee -a $ver_check_log
                                        	else
                                        	        echo "ERROR!!${ip-$file}'s $file.exe $s_exe_time ||Master's $m_exe_time" | tee -a $ver_check_log
                                        	fi
                                	done
			fi
        done
        shift
}

#Compare *.exe file through md5

md5_compare "$srv"


#Statistical success and error
#S_num_exe=`cat $ver_check_log | egrep "exe.*SUCCESS" | wc -l`
E_num_exe=`cat $ver_check_log | egrep "ERROR" | wc -l`
E_LIST_exe=`cat $ver_check_log | egrep "ERROR"`
