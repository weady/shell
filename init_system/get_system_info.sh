#!/bin/bash
#
#This scripts used to get system base info
#
#       by wangdd 2018/04/08
#



# kernel 2.x    获取基本信息

function get_base_info_v_2(){
        Hostname=$(/bin/hostname)
        Host_ip=$(/bin/hostname -i 2>/dev/null | awk '{print $1}' || /bin/hostname -I | awk '{print $1}')
        Host_bind_ips=$(/sbin/ip addr | grep 'inet\>' | grep -v 'lo\>' | awk 'BEGIN{ORS=","}{print $2,$NF}')
	Host_interface_info=$(/sbin/ip link | grep 'UP' | grep -v 'lo' | awk -F':' 'BEGIN{ORS=","}{print $2}' | tr -d ' ')
	
	#cpu info
	Host_cpu_type=$(cat /proc/cpuinfo | grep name | uniq | awk -F':' '{print $NF}')
	Host_cpu_num=$(cat /proc/cpuinfo | grep processor | wc -l)
	
	#host type 虚拟机 or 物理机
	Host_type_info=$(/sbin/lspci |grep -i vmware | wc -l)
	if [ $Host_type_info -gt 2 ];then
		Host_type="vmware"
	else
		Host_type="physical"
	fi

	#mem info 1021857
	Host_mem_total_size=$(free -m | grep '^Mem' | awk '{print $2}')
	Host_swap_total_size=$(free -m | grep '^Swap' | awk '{print $2}')
	Host_mem_total=$(awk -v mem_total=$Host_mem_total_size 'BEGIN{printf ("%.1f\n",mem_total/1000)}')
	Host_swap_total=$(awk -v swap_total=$Host_swap_total_size 'BEGIN{printf ("%.1f\n",swap_total/1000)}')	

	#host kernel
	Host_kernerl_type=$(uname -r)
	Host_os_version=$(cat /etc/redhat-release)
	
	#host disk info
	Host_disk_info=$(df -lhP | grep -vE 'tmpfs|Mounted' | awk 'BEGIN{ORS=","}{print $0}' | sed 's/\s\{1,\}/ /g')	
	

	#机器类型|主机名|主机IP|主机绑定IP信息|主机网卡信息|CPU类型|CPU核数|内存大小|Swap大小|系统内核|系统版本|磁盘信息	

	host_info=$Host_type'|'$Hostname'|'$Host_ip'|'$Host_bind_ips'|'$Host_interface_info'|'$Host_cpu_type'|'$Host_cpu_num'|'$Host_mem_total'|'$Host_swap_total'|'$Host_kernerl_type'|'$Host_os_version'|'$Host_disk_info	

}



#获取中间件的基本信息

function get_mid_info(){
	Hostname=$(/bin/hostname)
        Hostip=$(/bin/hostname -i 2>/dev/null | awk '{print $1}' || /bin/hostname -I | awk '{print $1}')

	if [[ $Hostname =~ .*jboss.* ]];then
		jboss_war_list=$(ls -l /app/war/ | awk '$1 ~ /^d/{print $NF}')
		jboss_tag=$(ls -l /app/war/ | awk '$1 ~ /^d/{print $NF}' | wc -l )
		jboss_config_file="/app/jboss/jboss-as/server"
		if [ $jboss_tag -gt 0 ];then
			for war in $jboss_war_list
			do
				if [ -f $jboss_config_file/$war/run.conf ];then
					jboss_jvm=$(grep '\-Xms' $jboss_config_file/$war/run.conf | grep -v '#JAVA_OPTS' | awk '{print $1,$2}' | awk -F'=' '{print $2}' | tr -d '"')
					instance_bind_ip=$(grep -vE '#|^$' $jboss_config_file/$war/run.conf | grep 'hostname' | awk -F'=' '{print $2}' | awk '{print $1}')
					instance_jmxremote_port=$(grep -vE '#|^$' $jboss_config_file/$war/run.conf | grep 'jmxremote.port' | awk -F'=' '{print $2}' | awk '{print $1}')
					instance_status_tag=$(/usr/sbin/ss -na | grep 'LIST' | grep "$instance_bind_ip" | wc -l)
					instance_soft_name=$(ls -l /app/war/$war/pkg | awk '$NF ~ /\.war$/ {print $NF}' | grep -v '\<mwmonitor.war\>')
					if [ $instance_status_tag -gt 2 ];then
						instance_status="running"
					else
						instance_status="stop"
					fi
					#容器名|项目|软件包|主机IP|实例IP|jvm信息|jvm接口|实例状态
					instance_list+="jboss"'|'$war'|'$instance_soft_name'|'$Hostip'|'$instance_bind_ip'|'$jboss_jvm'|'$instance_jmxremote_port'|'$instance_status','
				fi
			done
		fi

	elif [[ $Hostname =~ .*tomcat.*|.*tom.* ]];then
		tomcat_config_file="/app/tomcat/server"
		tomcat_war_list=$(ls -l /app/war/ | awk '$1 ~ /^d/{print $NF}')
		tomcat_tag=$(ls -l /app/war/ | awk '$1 ~ /^d/{print $NF}' | wc -l)
		if [ $tomcat_tag -gt 0 ];then
			for war in $tomcat_war_list
			do
				if [ -f $tomcat_config_file/$war/conf/server.xml ];then
					tomcat_max_thread=$(grep -A 5 '<Connector port="8080"' $tomcat_config_file/$war/conf/server.xml | grep 'maxThreads' | awk -F'=' '{print $2}' | tr -d '"')
					tomcat_jmxremote_port=$(grep 'jmxremote.port'  $tomcat_config_file/$war/bin/setenv.sh | sed -n 's/\(.*\)jmxremote.port=\([0-9]*\).*/\2/p')
					tomcat_bind_ip=$(grep 'jmxremote.port'  $tomcat_config_file/$war/bin/setenv.sh | sed -n 's/\(.*\)hostname=\(.*\)\s/\2/p' | awk '{print $1}')
					tomcat_bind_ip=$(grep -w address $tomcat_config_file/$war/conf/server.xml | awk -F'[=|"]' '{print $3}')
					tomcat_jvm=$(grep '\-Xms' $tomcat_config_file/$war/bin/setenv.sh |awk '{print $2,$3}')
					instance_status_tag=$(/usr/sbin/ss -an | grep 'LIST' | grep "$tomcat_bind_ip" | wc -l)
					instance_soft_name=$(ls -l /app/war/$war/pkg 2>/dev/null | awk '$NF ~ /\.war$/ {print $NF}' | grep -v '\<mwmonitor.war\>' 2>/dev/null)
					
					if [ $instance_status_tag -gt 2 ];then
                                        	instance_status="running"
                                	else
                                        	instance_status="stop"
                                	fi

					#容器名|项目|软件包|主机IP|实例IP|jvm信息|jvm接口|实例状态
					instance_list+="tomcat"'|'$war'|'$instance_soft_name'|'$Hostip'|'$tomcat_bind_ip'|'$tomcat_jvm'|'$tomcat_jmxremote_port'|'$instance_status','
				fi
			done
		fi

	elif [[ $Hostname =~ .*spring.* ]];then
		spring_war_list=$(ls -l /app/war/ | awk '$1 ~ /^d/{print $NF}')
                spring_tag=$(ls -l /app/war/ | awk '$1 ~ /^d/{print $NF}' | wc -l)
		if [ $spring_tag -gt 0 ];then
			for war in $spring_war_list
			do
				if [ -f /app/spring-boot/scripts/${war}.sh ];then
					instance_name=$war
					spring_jvmremote_port=$(grep 'JMX_PORT=' /app/spring-boot/scripts/${war}.sh | awk -F'\"' '{print $2}')
					spring_bind_ip=$(grep 'LISTEN_IP=' /app/spring-boot/scripts/${war}.sh | awk -F'\"' '{print $2}')
					spring_jvm=$(grep 'JVM_OPTS=' /app/spring-boot/scripts/${war}.sh | grep -v '^#' | awk '{print $1,$2}' | awk -F'=' '{print $2}' | tr -d '"')
					spring_instance_tag=$(/usr/sbin/ss -an | grep 'LIST' | grep "$spring_bind_ip" | wc -l)	
					instance_soft_name=$(ls -l /app/war/$war/pkg | awk '$NF ~ /\.war$/ {print $NF}' | grep -v '\<mwmonitor.war\>')

					if [ $spring_instance_tag -gt 2 ];then
						instance_status="running"
					else
						instance_status="stop"
					fi
					
					#容器名|项目|软件包|主机IP|实例IP|jvm信息|jvm接口|实例状态
					instance_list+="spring-boot"'|'$instance_name'|'$instance_soft_name'|'$Hostip'|'$spring_bind_ip'|'$spring_jvm'|'$spring_jvmremote_port'|'$instance_status','
				fi
			
			done
		fi

	elif [[ $Hostname =~ .*kafka.* ]];then
		kafka_confile=$(find /app -type f -name "server.properties" 2>/dev/null)
		if [ -f $kafka_confile ];then
                        broker_id=$(grep '^broker.id\>' $kafka_confile | awk -F '=' '{print $2}')
                        log_dir=$(grep -vE '#|^$' $kafka_confile | grep 'log.dirs\>' | awk -F '=' '{print $2}')
                        listen_ip=$(grep -vE '#|^$' $kafka_confile | grep 'listeners\>' | awk -F '/' '{print $NF}')
                        partitions_num=$(grep -vE '#|^$' $kafka_confile | grep 'num.partitions\>' | awk -F '=' '{print $2}')
                        replica_num=$(grep -vE '#|^$' $kafka_confile | grep 'num.replica.fetchers\>' | awk -F '=' '{print $2}')
                        zk_connect=$(grep -vE '#|^$' $kafka_confile | grep 'zookeeper.connect\>' | awk -F '=' '{print $2}')
                        kafka_tag=$(netstat -unltp | grep "$listen_ip")
                        [[ -n "$kafka_tag" ]] && kafka_status="running" || kafka_status="stoped"

                        #中间件名|主机IP|broker_id|监听IP|日志目录|分片数|副本数|zk_info|状态
                        instance_list='kafka''|'$Hostip'|'$broker_id'|'$listen_ip'|'$log_dir'|'$partitions_num'|'$replica_num'|'$zk_connect'|'$kafka_status
		fi
		
	elif [[ $Hostname =~ .*redis.* ]];then
                redis_config="/app/redis/conf"
                instance_name=$(ls -1 /app/redis/data | grep '\.rdb'  |awk -F'.' '{print $1}')
		for line in $instance_name
		do
			tag=$(ls -1 /app/redis/run/ | grep $line 2>/dev/null)
			if [[ -n $tag ]];then
			instance_tag=$(echo "$line" | awk -F'_' 'BEGIN{OFS="_"}{print $1,$2}')

	                svr_max_mem=$(grep 'maxmemory\s\{1,\}' $redis_config/${line}.conf | awk '{print $2}')
        	        svr_max_client=$(grep '^maxclients' $redis_config/${line}.conf | awk '{print $2}')
               		svr_listen_port=$(grep '^port' $redis_config/${line}.conf | awk '{print $2}')
                	svr_bind_ip=$(grep '^bind' $redis_config/${line}.conf | awk '{print $2}')
                	svr_status=$(/usr/sbin/ss -an | grep  'LI' |grep $svr_listen_port >/dev/null && echo "running" || echo "stop")

                	#sential
			sen_config_file=$(echo "${line}.conf" | sed 's/_SVR_/_SEN_/g')
                	sen_instance_name=$(ls -1 $redis_config | grep "$instance_tag" | grep 'SEN' | awk -F '.' '{print $1}')
                	sen_listen_port=$(grep '^port' $redis_config/$sen_config_file | awk '{print $2}')
                	sen_bind_ip=$(grep '^bind' $redis_config/$sen_config_file | awk '{print $2}')
                	sen_max_client=$(grep '^maxclients' $redis_config/$sen_config_file | awk '{print $2}')
                	sen_status=$(/usr/sbin/ss -an | grep  'LI' |grep $sen_listen_port >/dev/null && echo "running" || echo "stop")

			cluster_tag=$(grep '^cluster-enabled yes' $redis_config/${line}.conf | grep -v '#')
			if [ -n "$cluster_tag" ];then
				cluster_name=$line
				auth_passwd="-"
			else
				cluster_name=$(grep -vE '#|^$' $redis_config/$sen_config_file | grep '^sentinel monitor' | awk '{print $3}')
				auth_passwd=$(grep -vE '#|^$' $redis_config/${line}.conf | grep 'requirepass' | awk -F'"' '{print $2}')
			fi

               		#中间件名|集群名|实例名|主机IP|bind_ip|max_mem|max_client|监听端口|实例状态|认证密码
                	instance_list+='redis''|'$cluster_name'|'$line'|'$Hostip'|'$svr_bind_ip'|'$svr_max_mem'|'$svr_max_client'|'$svr_listen_port'|'$svr_status'|'$auth_passwd'#''redis''|'$cluster_name'|'$sen_instance_name'|'$Hostip'|'$sen_bind_ip'|''-''|'$sen_max_client'|'$sen_listen_port'|'$sen_status'|'$auth_passwd','
			fi
		done

	elif [[ $Hostname =~ .*nginx.*|.*ngx.* ]];then
		nginx_dir="/app/nginx/conf/servers"
		nginx_config=$(ls -1 $nginx_dir | egrep '*.conf$' | grep -v 'https')
		for line in $nginx_config
		do
		        upstream_config=$(sed -n '/^upstream/,/^server/p' $nginx_dir/$line | grep -v '[{}]' | tr -d ';' | sed 's/^[ \t]*//g')
        		upstream_method=$(sed -n '/^upstream/,/^server/p' $nginx_dir/$line | grep -v '[{}]' | tr -d ';' | sed 's/^[ \t]*//g' | grep -vE '^#|server')
        		backend_svr_ip=$(sed -n '/^upstream/,/^server/p' $nginx_dir/$line | grep -v '[{}]' | tr -d ';' | sed 's/^[ \t]*//g' | grep '^server' | awk '{print $NF}')
        		listen_ip=$(grep 'listen' $nginx_dir/$line | tr -d ';' | sed 's/^[ \t]*//g' | awk '{print $NF}')
        		port_status=$(/usr/sbin/ss -an | grep 'LIS' | grep "$listen_ip")
        		[[ -n $port_status ]] && svr_status="running" || echo svr_status="stop"

			#中间件名|主机ip|业务名|upstream方法|后端服务IP|监听ip|服务状态
        		instance_list+='nginx''|'$Hostip'|'$line'|'$upstream_method'|'$backend_svr_ip'|'$listen_ip'|'$svr_status','
		done
	elif [[ $Hostname =~ .*haproxy.* ]];then

		ha_config="/app/haproxy/conf/haproxy.cfg"
		server_list=$(grep 'use_backend' $ha_config | grep -v '#' | sed 's/^[ \t]*//g' |sed 's/ /|/g')
		last_tag=$(grep use_backend $ha_config | grep -v '#' | tail -n 1 | awk '{print $2}')

		for line in $server_list
		do

		        svr=$(echo "$line" | awk -F '|' '{print $2}')
		        svr_acl=$(grep -v '^$' $ha_config | grep -B 1 "use_backend ${svr}\>")
        		domain_info=$(echo "$svr_acl" | grep -vE '#|^$' | grep '\<acl\>'|awk '{for(i=4;i<=NF;i++) printf $i""FS;print ""}')
			if [[ $domain_info =~ ^-i.*|^1.* ]];then
               			domain=$(echo $domain_info | awk '{print $2}')
        		else

                		domain=$(echo $domain_info | awk '{print $1}')
       			fi
			
			if [[ ! $domain =~ .*\.com|.*\.cn ]];then
				domain=$(echo "$svr_acl" | grep -vE '#|^$' | sed -n 's/acl\(.*[com|cn]\).*/\1/p' | awk '{print $NF}')
			fi

        		if [ "$svr" == "$last_tag" ];then
                		server_ip=$(grep -vE '#|^$' $ha_config | sed -n 's/[ \t]*//p' | sed -n "/^backend ${svr}\>/,/server+/p" | grep '^server' | awk '{print $3}')
       	 		else
                		server_ip=$(grep -vE '#|^$' $ha_config | sed -n 's/[ \t]*//p' | sed -n "/^backend ${svr}\>/,/^frontend/p" | grep '^server' | awk '{print $3}')
        		fi
			ha_proc_num=$(ps -ef | grep haproxy.cfg | grep -v 'grep' | wc -l)
			[[ $ha_proc_num -gt 0 ]] && ha_status="running" || ha_status="stoped"
			#中间件名|主机IP|业务名|域名信息|服务端ip
                	instance_list+='ha''|'$Hostip'|'$svr'|'$domain'|'$server_ip'|'$ha_status','
		done

	elif [[ $Hostname =~ .*mysql.* ]];then
		mysql_instance_num=$(ls -l /data | grep -v '^total' | awk '{if($4=="mysql") print}' | awk '{print $NF}')
		for line in $mysql_instance_num
		do
			mysql_config_file=$(ls -1 /data/$line | egrep '*.cnf$' | grep -vE '\<backup*|\<my.cnf')
			mysql_cnf="/data/$line/$mysql_config_file"
			if [[ -f "$mysql_cnf" ]];then
				instance_name=$line
				mysql_instance_ip=$(grep -vE '#|^$' $mysql_cnf | grep '^bind_address' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
				mysql_instance_port=$(grep -vE '#|^$' $mysql_cnf |grep '^port' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
				data_dir=$(grep -vE '#|^$' $mysql_cnf |grep '^datadir' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
				db_list=$(ls -l $data_dir | grep '^d' | awk '{print $NF}' | grep -vE 'mysql|performance_schema|sys|test')
				role_type=$(grep -vE '#|^$' $mysql_cnf |grep '^read_only' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
				max_conn=$(grep -vE '#|^$' $mysql_cnf |grep '^max_connections' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
				mysql_status=$(/usr/sbin/ss -an | grep '^LIS' | grep "$mysql_instance_port")
				

				[[ -n "$mysql_instance_ip" ]] && instance_ip=$mysql_instance_ip || instance_ip="$Hostip"
				[[ -n "$mysql_status" ]] && instance_status="running" || instance_status="stop"
				
				#中间件名|主机IP|实例名|实例IP|实例端口|数据目录|数据库列表|实例角色|最大连接数|实例状态
				instance_list+='mysql''|'$Hostip'|'$instance_name'|'$instance_ip'|'$mysql_instance_port'|'$data_dir'|'$db_list'|'$role_type'|'$max_conn'|'$instance_status','
			fi

			
		done

	elif [[	$Hostname =~ .*mongo.* ]];then
		mongo_dir="/app/mongodb/conf"
		mongo_config=$(ls -1 $mongo_dir | grep '.conf$')
		instance_ip=$(grep -vE '#|^$' $mongo_dir/mongod.conf | grep '^bind_ip' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
		instance_port=$(grep -vE '#|^$' $mongo_dir/mongod.conf | grep '^port' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
		max_conn=$(grep -vE '#|^$' $mongo_dir/mongod.conf | grep '^maxConns' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
		data_dir=$(grep -vE '#|^$' $mongo_dir/mongod.conf | grep '^dbpath' | awk -F'=' '{print $NF}' | tr -d '[[:space:]]')
		db_list=$(ls -l $data_dir | awk '{print $NF}' | grep '.ns$' | awk -F'.' '{print $1}')
		mongo_status=$(/usr/sbin/ss -an | grep '^LIS' | grep "$instance_port")

		[[ -n "$mongo_status" ]] && instance_status="running" || instance_status="stop"

		#中间件名|主机IP|实例ip|实例端口|最大连接数|数据库列表|实例状态
		instance_list+='mongodb''|'$Hostip'|'$instance_ip'|'$instance_port'|'$max_conn'|'$db_list'|'$instance_status','
	fi
}

#---------------------------------------------------------

#get_base_info
function get_system_info(){
	get_base_info_v_2
	get_mid_info
	if [[ -z $instance_list ]];then
		instance_list="-"
	fi
	echo $host_info'+'$instance_list
}
get_system_info
