#!/bin/bash
#
#
#
#This is script is used to check run.sh file
#
#       by wangdd 2015/8/15
#
#
path="/homed"
srv="redis db_router db_writer dtvs iacs ias iclnd icore iis ilogclient ilogmaster ilogslave imsgs ipuis ipwed isas itimers itts iuds iusa iusm tsg ulogs"
source $path/all_service_deploy.sh
function md5_compare(){
        for file in $@
        do
		if [ "$file" == "redis" ];then
			md5_redis_mrun=`md5sum $path/$file/bin/run-master.sh`
			md5_redis_srun=`md5sum $path/$file/bin/run-slave.sh`
			num_m_run=`ls $path/$file/bin/run*.sh  | wc -l`
                        echo "***Start Check ${file}'s run-*.sh,Through Compare To Master's By MD5***" | tee -a $ver_check_log
		 	for redis_ip in $redis_srv_ips
			do
				md5_s_redis_mrun=`ssh $redis_ip "md5sum $path/$file/bin/run-master.sh"`
				md5_s_redis_srun=`ssh $redis_ip "md5sum $path/$file/bin/run-slave.sh"`
				num_s_run=`ssh $redis_ip "ls $path/$file/bin/run*.sh  | wc -l"`
				if [ "$md5_redis_mrun" == "$md5_s_redis_mrun" -a "$md5_redis_srun" == "$md5_s_redis_srun" -a "$num_m_run" == "$num_s_run" ];then
					echo "	${redis_ip}'s run-*.sh update SUCCESS!!" | tee -a $ver_check_log
				else
					echo "ERROR!!${redis_ip}'s run-*.sh is not update! " | tee -a $ver_check_log
				fi
			done
		else
			m_run_time=`stat $path/$file/bin/run.sh | grep Modify | awk -F. '{print $1}'`
                        md5_master=`md5sum $path/$file/bin/run.sh`
                        list=$"$file"_srv_ips
                        echo "***Start Check ${file}'s run.sh,Through Compare To Master's By MD5***" | tee -a $ver_check_log
                        for ip in ${!list}
                                do
					s_run_time=`ssh $ip "stat $path/$file/bin/run.sh | grep Modify | awk -F. '{print $'1'}'"`
                                        md5_slave=`ssh $ip "md5sum $path/$file/bin/run.sh"`
                                        if [ "$md5_master" == "$md5_slave" ];then
                                                echo "  $ip-$file run.sh update SUCCESS!!       " | tee -a $ver_check_log
                                        else
                                                echo "ERROR!!$ip-$file run.sh $s_run_time ||Master's $m_run_time" | tee -a $ver_check_log
                                        fi
                                done
		fi
        done
        shift
}

#Compare run.sh through md5

md5_compare "$srv"

#Statistical success and error
#S_num_run=`cat $ver_check_log | egrep "run.*SUCCESS" | wc -l`
E_num_run=`cat $ver_check_log | egrep "ERROR" | wc -l`
E_LIST_run=`cat $ver_check_log | egrep "ERROR"`
