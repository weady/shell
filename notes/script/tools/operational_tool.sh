#!/bin/bash
#
#
#	by wangdd 2015/10/30
#
#
last_split_ips=""
path="/usr/local/src"
rex1=[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}
rex2=[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}-[0-9]\{1,3\}
#function
function f_splitips(){
        local all_oldips=$1
        local newips=""
        local oldips
        for oldips in $all_oldips
        do
                local start_ip=${oldips%-*}
                local end=${oldips#*-}

                if [ "$end" == "$start_ip" ]
                then
                        if [ "$newips" == "" ]
                        then
                                newips=$start_ip
                        else
                                newips="$newips $start_ip"
                        fi
                else
                        start=${start_ip##*.}
                        local ip_header=${start_ip%.*}

                        local num
                        for((num=$start;num<=$end;num++))
                        do
                                if [ "$newips" == "" ]
                                then
                                        newips="$ip_header.$num"
                                else
                                        newips="$newips $ip_header.$num"
                                fi
                        done
                fi
        done


        #remove repeat ips
        if [ "$2" == "--norepeat" ]
        then
                local newips1=""
                local addip
                for addip in $newips
                do
                        if [ "$newips1" == "" ]
                        then
                                newips1="$addip"
                                continue
                        fi

                        local hasexist=""
                        local hasip
                        for hasip in $newips1
                        do
                                if [ "$hasip" == "$addip" ]
                                then
                                        hasexist="1"
                                        break
                                fi
                        done

                        if [ "$hasexist" == "" ]
                        then
                                newips1="$newips1 $addip"
                        fi
                done

                newips=$newips1 
        fi

        last_split_ips=$newips
}
#----------------------------------------------------------------------------------
#Install zabbix server
	
function ZB_server(){
    read -p " Your want into Zabbix Server to which slave(eg:slave14):" slave
	ip=`cat /etc/hosts | grep "$slave\>" | head -n 1|awk '{print $1}'`
	if [ -z "$ip" ];then
		echo "There is no this $slave"
		exit
	fi
	read -p " Databae IP:" dbip
    read -p " Databae user(root):" username
    read -p " Databae passwd:" password
    if [[ "$ip" =~ $rex1 ]];then
		echo "---- Install zabbix_server in $ip----"
		rsync $path/zabbix-2.4.6.tar.gz $ip:$path
		ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz >/dev/null;./scripts/zabbix_server_install.sh $ip $dbip $username $password"
		echo "Zabbix Server ip is $ip"
    else
        echo "Illegal IP"
    fi
}

#Install Zabbix_agent
function ZB_agent(){
	read -p "Input Zabbix Server ip:" sip
	#sip=`cat /homed/config_comm.xml | grep "mt_mainsrv_ip" |sed -re 's/.*>(.*)<.*$/\1/g'`
	read -p "Input Agent ips(eg:192.168.1.1-123 or 192.168.1.1):" ips
	[[ "$sip" =~ $rex1 ]] && serverip="$sip" || echo "Zabbix Server ip Error"
	if [[ "$ips" =~ $rex1 || "$ips =~ $rex2" ]];then
		f_splitips "$ips"
		ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
		for ip in ${ip_list}
		do
			echo " Install zabbix_agent to $ip"
			rsync $path/zabbix-2.4.6.tar.gz $ip:$path
			ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz >/dev/null;./scripts/zabbix_agent_install.sh $serverip"
			check_ok "$ip" "zabbix_agent"
		done
	else
		echo "Illegal IP"
	fi
}
#check function
function check_ok(){
	if [ $? -eq 0 ];then
		echo "----$1 install $2 success----"
	else
		echo "----$1 install $2 failed----"
	fi
}
#contral zabbix_agent
function contral_agent(){
	read -p "Input zabbix agent hostname(eg:slave1 or slave1-29):" name
	read -p "Choise one{status|start|restart|stop}:" command
	targ=`echo "$name" | grep '-' | grep -v grep`
	if [ -n "$targ" ];then
		num=`echo "$name" | tr -d '[a-zA-Z]'`
		first_num=`echo "$num" |awk -F '-' '{print $1}'`
		last_num=`echo "$num" |awk -F '-' '{print $2}'`
		for i in `seq $first_num $last_num`
		do
			echo "-------Hostname is slave${i}-----------------"
        		ssh  slave${i} "service zabbix_agent $command"
		done
	else
		echo "-------Hostname is $name-----------------"
		ssh $name "service zabbix_agent $command"
	fi
}
#input zabbix_server ip
function check_ip(){
	read -p "Input ips(eg:192.168.1.1 or 192.168.1.1-100) :" ip
	if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
		f_splitips "$ip"
        	ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
	else
		echo "Invalid IP"
		check_ip
	fi
}
#deploy softs
function deploy_softs(){
	soft_package=$1
	soft_name=$2
	argv=$3
	for ip in $ip_list
	do
		rsync -az $path/softs/$soft_package $ip:$path
		rsync -az $path/scripts/lamp_install.sh $ip:$path
		ssh $ip "cd $path;./lamp_install.sh $soft_name $argv"
	done
}
#Install some softs
function Install_soft(){
	read -p "Your want to install softs in the local host or the remote host(eg:local or remote):" targ
	if [ "$targ" == "remote" ];then
		check_ip
		read -p "Choise your want install soft:{php|mysql|apache} :" softname
		case $softname in
			php)
				deploy_softs "php-5.5.7-green.tar.gz" "php" "$targ"
				;;
			mysql)
				deploy_softs "mysql-5.5.33-green.tar.gz" "mysql" "$targ"
				;;
			apache)
				deploy_softs "apache-2.2.21-green.tar.gz" "apache" "$targ"
				;;
			*)
				echo "Usage {php|mysql|apache}"
				;;
		esac
	elif [ "$targ" == "local" ];then
		read -p "Choise your want install soft:{php|mysql|apache} :" softname
		cd $path
		./scripts/lamp_install.sh $softname
	else
		echo "Your should input local or remote!"
	fi
}
#-----------------------------------------------------------
function install_comm_server(){
	ser_name=$1
	for ip in $ip_list
        do
		if [ "$ser_name" == "ftp" ];then
                	rsync -az $path/scripts/ftp_install.sh $ip:$path
			read -p "Please input share directory:" share_path
                	ssh $ip "cd $path;./ftp_install.sh $share_path"
		elif [ "$ser_name" == "nfs" ];then
			rsync -az $path/scripts/nfs_install.sh $ip:$path
			read -p "Please input share directory:" share_path
			read -p "Please input allow network(eg:192.168.0.0/16):" allow_ip
			ssh $ip "cd $path;./nfs_install.sh $share_path $allow_ip"
		elif [ "$ser_name" == "dncp" ];then
			rsync -az $path/scripts/dhcp_install.sh $ip:$path
			read -p "Please input DHCP clients ip(eg:192.168.1.100-200):" clients_ip
			read -p "Please input getway IP" getwayip
			read -p "Please input DNS IP" dnsip
			ssh $ip "cd $path;./dhcp_install.sh $clients_ip $getwayip $dnsip"
		fi
        done
}
#install some server
function install_dhcp_ftp_nfs(){
	read -p "Your want to install softs in the local host or the remote host(eg:local or remote):" targ
	if [ "$targ" == "remote" ];then
		check_ip
		read -p "Choise your want install server:{ftp|dhcp|nfs}" server_name
		case $server_name in
			ftp)
				install_comm_server "ftp"
				;;
			dhcp)
				install_comm_server "dhcp"
				;;
			nfs)
				install_comm_server "nfs"
				;;
			*)
				echo "Usage {ftp|dhcp|nfs}"
				;;
		esac
	elif [ "$targ" == "local" ];then
		cd $path
		read -p "Choise your want install server:{ftp|dhcp|nfs}" ser_name
		if [ "$ser_name" == "ftp" ];then
                        read -p "Please input share directory:" share_path
			./scripts/ftp_install.sh $share_path
                elif [ "$ser_name" == "nfs" ];then
                        read -p "Please input share directory:" share_path
                        read -p "Please input allow network(eg:192.168.0.0/16):" allow_ip
			./scripts/nfs_install.sh $share_path $allow_ip
                elif [ "$ser_name" == "dncp" ];then
                        read -p "Please input DHCP clients ip(eg:192.168.1.100-200):" clients_ip
                        read -p "Please input getway IP" getwayip
                        read -p "Please input DNS IP" dnsip
			./scripts/dhcp_install.sh $clients_ip $getwayip $dnsip
                fi
	else
		echo "Your should input local or remote!"
	fi
	
}
#sync files to some where
function Sync(){
	check_ip
	read -p "Input source dir or files:" src
	read -p "Input destination dir or files:" dst
	if [ -z "$src" -o -z "$dst" ];then
		echo "Error"
	else
	for ip in ${ip_list} 
	do
		echo "-----Sync files to $ip-----"
		rsync -avz $src $ip:$dst
		[[ $? -eq 0 ]] && echo "SYNC Success" || echo "SYNC Failed"
        done
	fi
}
#Get or Put file to FTP
function ftp(){
	ftp_ip="ftp.xxxx.cn"
	username="xxxx"
	passwd="xxxxx"
	read -p "Input file(eg: put/get local_dir ftp_dir files):" method l_dir ftp_dir file
	echo "------------------------------------------------"
	echo "Start $method $file to  at `date +%Y-%m-%d-%T`"
	echo "------------------------------------------------"
/usr/bin/ftp -ivn $ftp_ip <<EOF
user $username $passwd
binary
lcd ${l_dir}
cd ${ftp_dir}
m${method} ${l_dir}  $file
bye
EOF
	echo "------------------------------------------------"
	echo "End ${method} $file at `date +%Y-%m-%d-%T`"
	echo "------------------------------------------------"
}
#-----------------------------------------------------------------------------------
#configure keepalived+LVS
#
function LVS(){
	if [ ! -f "/etc/keepalived/keepalived.conf" ];then
		read -p "Please input keepalived type(MASTER Or SLAVE):" lvs_type
		read -p "Please input LVS's priority:" lvs_priority
		read -p "Please input LVS's banlance algo(eg:rr wlc llc):" lvs_algo
		read -p "Please input your VIP:" vip_list
		read -p "Please input VIP binding interface:" bind_inter
		read -p "Please input port:" port_list
       	read -p "Please input real server ips(eg:192.168.1.1 or 192.168.1.1-100) :" ip
        if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
			f_splitips "$ip"
               		realip_list=$last_split_ips
		else
			echo "Invalid IP"
		fi
	else
		lvs_type="MASTER"
		lvs_priority="100"
		lvs_algo="rr"
		bind_inter="eth1"
		read -p "Please input your VIP:" vip_list
		read -p "Please input port:" port_list
       		read -p "Please input real server ips(eg:192.168.1.1 or 192.168.1.1-100) :" ip
        	if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
			f_splitips "$ip"
               		realip_list=$last_split_ips
		else
			echo "Invalid IP"
		fi
	fi
		
	sh $path/scripts/keepalived_install.sh "$vip_list" "$port_list" "$realip_list" "$lvs_type" "$bind_inter" "$lvs_priority" "$lvs_algo"
}

#-----------------------------------------------------------------------------------
#这个是更新zabbix脚本的命令,把更新目录位于/usr/local/src/zb_update目录下
function zb_update(){
	read -p "Please Input zabbix server host's name or host's ip(eg:slave14):" hostip
        srcpath="/usr/local/src/zabbix_update"
        dstpath="/usr/local/zabbix"
        user="zabbix"
        passwd="zabbixpass"
        mysql_cmd="mysql -B -u$user -p$passwd -h$hostip zabbix -e"
        sql="select host from hosts where available=1"
        clients=`$mysql_cmd "$sql"|grep -v 'host'`
        for ip in $clients
        do
                echo "----------update files to $ip------------"
                rsync -av $srcpath/scripts/* $ip:$dstpath/scripts
                rsync -av $srcpath/configure/* $ip:$dstpath/etc/zabbix_agentd.conf.d
                ssh $ip "service zabbix_agent restart"
        done
}
#-----------------------------------------------------------------------------------
#停用磁盘的写入监测，方便hadoop的更新
function stop_disk_monitor(){
	read -p "Please input stop or start:" tag
	dbip=`cat /homed/config_comm.xml  | grep 'mt_mainsrv_ip' | awk -F '[><]' '{print $3}'`
	user="zabbix"
	passwd="zabbixpass"
	db="zabbix"
	mysql_cmd="mysql -B -u$user -p$passwd -h$dbip $db -e"
	stop_sql="update items set status=1 where key_ like "disk.resource[%,disk_status]" and status=0"
	start_sql="update items set status=0 where key_ like "disk.resource[%,disk_status]" and status=1"
	if [ "$tag" == "stop" ];then
		echo "----$dbip-----"
		stop_result=`$mysql_cmd "$stop_sql"`
		[[ $? -eq 0 ]] && echo "SUCCESS" || echo "Failed"
	elif [ "$tag" == "start" ];then
		echo "----$dbip-----"
		start_result=`$mysql_cmd "$start_sql"`
		[[ $? -eq 0 ]] && echo "SUCCESS" || echo "Failed"
	else 
		echo "Errors!your should input stop or start"
		exit
	fi
}
#-----------------------------------------------------------------------------------
#安装部署单机版Homed
function install_single_homed(){
	read -p "Please input local IP:" ip
	root_path=`cd $(dirname $0);pwd`
	if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
		f_splitips "$ip"
        	ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
		$root_path/scripts/single_homed_install.sh $ip_list
	else
		echo "Invalid IP"
		install_single_homed
	fi
}
#-----------------------------------------------------------------------------------
function dump_mysql(){
	
	default_path="/usr/local/soft/mysql_structure"
	[[ ! -d "$default_path" ]] && mkdir -p $default_path >/dev/null
	user='root'
	passwd=`cat /homed/config_comm.xml | grep 'mt_db_pwd' | awk -F '[<>]' '{print $3}'`
	mysql_ip_info=`cat /homed/allips.sh | grep "_mysql_ips=" | awk -F '[=_ ]' '{print $2,$5}' | tr -d '"'`
	
	#homed_iusm,homed_dtvs,homed_icore 这三个库会单独部署在不同的数据库主机上
	specific_dbs="homed_iusm homed_dtvs homed_icore"

	#下列这些库都位于在同一台数据库主机上
	general_dbs="homed_cmd homed_hive homed_iacs homed_iclnd homed_iepgs homed_ilog homed_imsgs homed_invs homed_ipmux homed_ipwed homed_isas homed_itimers homed_iuds homed_iwds homed_mosaicbms homed_tsg"
	specific_dbs_ip=`echo "$mysql_ip_info" | grep -E 'iusm|dtvs|icore'`
	general_dbs_ip=`echo "$mysql_ip_info" | grep -E 'iuds'|awk '{print $2}'`
	
	echo ""
        echo "-- Starting dump all the database table structure to $default_path --"
        echo ""
        echo "The database list is:"
        echo "homed_iusm homed_dtvs homed_icore homed_cmd homed_hive homed_iacs homed_iclnd homed_iepgs homed_ilog"
        echo "homed_imsgs homed_invs homed_ipmux homed_ipwed homed_isas homed_itimers homed_iuds homed_iwds homed_mosaicbms homed_tsg"
        echo "" 
        echo "$specific_dbs_ip" | while read line
        do
                db_name=homed_`echo "$line" | awk '{print $1}'`
                db_ip=`echo "$line" | awk '{print $2}'`
                mysqldump -d -u$user -p$passwd -h$db_ip $db_name >$default_path/${db_name}_structure.sql 2>/dev/null
		[[ $? -ne 0 ]] && echo "Dump $db_name failed,db_ip is $db_ip"
        done
	
        for db in $general_dbs
        do
                mysqldump -d -u$user -p$passwd -h$general_dbs_ip $db >$default_path/${db}_structure.sql 2>/dev/null
		[[ $? -ne 0 ]] && echo "Dump $db failed,db_ip is $general_dbs_ip"
        done
        echo "---------- Complete ---------"
}
function dump_single_structure(){
        dbs_ip=$1
        dbs=$2
	user='root'
	passwd=`cat /homed/config_comm.xml | grep 'mt_db_pwd' | awk -F '[<>]' '{print $3}'`
	default_path="/usr/local/soft/mysql_structure"
	[[ ! -d "$default_path" ]] && mkdir -p $default_path >/dev/null
        echo "-- Starting dump the database of $dbs table structure to $default_path --"
        echo ""
        echo "-- Database name is $dbs --"
        mysqldump -d -u$user -p$passwd -h$dbs_ip $dbs >$default_path/${dbs}_structure.sql 2>/dev/null
	[[ $? -ne 0 ]] && echo "Dump $dbs failed,db_ip is $dbs_ip"
        echo "-- Complete --"
}
#dump 数据库表结构用于对比监测
function dump_mysql_structure(){
	read -p "Please input database name (default 'all'):" db_name
	if [[ "$db_name" =~ [a|A][l|L]{2} || -z "$db_name" ]];then
		dump_mysql
	else
		read -p "Please input database ip:" db_ip
		if [ -z "$db_name" -o -z "$db_ip" ];then
			echo "Please input database's name and database's ip"
			exit
		else
			dump_single_structure "$db_ip" "$db_name"
		fi
	fi
}
#-----------------------------------------------------------------------------------
#对比表结构函数
function compare_table_structure(){
	echo ""
	read -p "Please Input The Direcotory Of The Standard Structure:" dir_standard
	echo ""
	read -p "Please Input The Direcotory Of The Business Structure:" dir_business
	echo ""
	company_structure_path=$dir_standard
	business_structure_path=$dir_business
	
	if [ -z "$dir_standard" -o -z "$dir_business" ];then
		echo " [ Please Input Direcotory Name ] "
		echo ""
		exit
	elif [ ! -d "$dir_standard" -o ! -d "$dir_business" ]; then
		echo "[ $dir_standard or $dir_business is not a directory ]"
		echo ""
		exit
	else
		file_num=`ls -l $company_structure_path | awk '{print $NF}' | grep '^homed' | wc -l`
		[[ "$file_num" -lt 1 ]] && exit
		read -n1 -p "You Want To Compare ALL Database or Some Database (A/S)?:" compare_tag
		echo ""
		if [[ "$compare_tag" =~ a|A ]];then
			file_list=`ls -l $company_structure_path | awk '{print $NF}' | grep '^homed'`
			echo ""
		elif [[ "$compare_tag" =~ s|S ]]; then
			read -p "Please Input The Database Name of You Want To Compare (eg:homed_tsg homed_iuds):" comp_db_name
			#对输入的数据库，获取出相应的数据库结构文件
			for comp_name in $comp_db_name
			do
				if [[ "$comp_name" =~ homed_.* ]];then
        				comp_db_list=`ls -l $company_structure_path | awk '{print $NF}' | grep '^homed' | grep "$comp_name"`
        				tmp_db_list_a=`echo "$comp_db_list "`
        				tmp_db_list_b+=$tmp_db_list_a
        			else
					echo ""
        				echo " [ The Database Format must be 'homed_XXX' ] "
					echo ""
					exit
				fi
			done
			#获取出最后对比的数据库文件列表
			file_list=`echo "$tmp_db_list_b" | sed 's/ /\n/g'`		
		else
			echo "[ Please Input A or S ] "
			echo ""
			exit
		fi

	fi
	
	now_time=`date +%Y%m%d.%H.%M`
	
	#compare_report 存放的是只有存储引擎不同的日志
	compare_report="/tmp/compare_table_report_${now_time}.txt"
	#table_structure_report 是处理后的最终报告
	table_structure_report="/usr/local/src/table_structure_report_${now_time}.txt"
	#对差异表进行逐行对比,日志存放于line_report
	line_report="/tmp/line_report.txt"
	echo "" >$line_report
	echo ""
	echo "------- Starting Compare table's structure,Please waiting -------"
	echo ""
        echo "** Left Is The Standard Table Structure | Right Is Business's Table Structure **"
	echo ""
	cd /usr/local/src; rm -f table_structure_report_*.txt
	echo "$file_list" | while read line
	do
		db_name=${line%_*}
		b_db_name=`ls -l $business_structure_path | awk '{print $NF}' | grep "$db_name"`
		if [ -z "$b_db_name" ];then
			echo "-- $business_structure_path does not exsit $line --"
			exit
		fi
		if [ "$db_name" == "homed_tsg" ];then
			table_list=`cat $company_structure_path/$line | sed '/tsg_total/,$d' | grep '^CREATE TABLE' | awk '{print $3}' | tr -d '\`'`
		else
			table_list=`cat $company_structure_path/$line | grep '^CREATE TABLE' | awk '{print $3}' | tr -d '\`'`
		fi
		for table in $table_list
		do
			echo "" >/tmp/c_compare.log
			echo "" >/tmp/b_compare.log
			company_table=`cat $company_structure_path/$line | tr -d '\`' | sed -n "/^CREATE TABLE \<$table\> /,/) ENGINE/p" | sed 's/^[ \t]*//g' | awk -F'COMMENT' '{print $1}'| sed 's/\(.*\) AUTO_INCREMENT.*\(DEFAULT.*\)/\1 \2/g' | sed 's/[ \t]*$//g' | tr -d ',;\`' >/tmp/c_compare.log`
			business_table=`cat $business_structure_path/$line | tr -d '\`' | sed -n "/^CREATE TABLE \<$table\> /,/) ENGINE/p" |sed 's/^[ \t]*//g' | awk -F'COMMENT' '{print $1}'| sed 's/\(.*\) AUTO_INCREMENT.*\(DEFAULT.*\)/\1 \2/g' |sed 's/[ \t]*$//g' | tr -d ',;\`' >/tmp/b_compare.log`
			b_table=`cat $business_structure_path/$line | tr -d '\`' |sed -n "/^CREATE TABLE \<$table\> /,/) ENGINE/p" |sed 's/^[ \t]*//g' | awk -F'COMMENT' '{print $1}'| sed 's/\(.*\) AUTO_INCREMENT.*\(DEFAULT.*\)/\1 \2/g' |sed 's/[ \t]*$//g' | tr -d ',;\`'`
			if [ -z "$b_table" ];then
				echo "[ERROR] [ Business] The table [ $table ] does not exsit in [ $db_name ]" >> $compare_report
			else
				result=`diff -y /tmp/c_compare.log /tmp/b_compare.log | grep -E '\||>|<'`
                                if [ ! -z "$result" ];then
                                        echo "" >> $compare_report
					echo "$result" > /tmp/compare_table.tmp
					num=`cat /tmp/compare_table.tmp | wc -l`
					engine_tag=`cat /tmp/compare_table.tmp | grep 'ENGINE='`
					if [ "$num" -eq 1 -a ! -z "$engine_tag" ];then
						echo "[$db_name $table] $result" | sed 's/[|<>]/|/g' >> $compare_report
					else
						cat /tmp/c_compare.log | while read line
						do
							echo "" >/tmp/c_line
							echo "" >/tmp/b_line
							c_line=`echo "$line" >/tmp/c_line`
							tag=`echo "$line" | awk '{print $1}'`
        						[[ "$tag" =~ PRIMARY|KEY|\)|CONSTRAINT ]] && tag=`echo "$line" |awk '{print $1,$2}'`
							b_line=`cat /tmp/b_compare.log| grep "^$tag\>"`
							echo "$b_line" >/tmp/b_line
							if [ ! -z "$b_line" ];then
								result_line=`diff -y /tmp/c_line /tmp/b_line | grep -E '\||>|<'`
								col_1=`echo "$result_line" | awk -F '[|<>]' '{print $1}' | sed -e 's/[ \t]*$//g;s/^[ \t]*//g'`
								col_2=`echo "$result_line" | awk -F '[|<>]' '{print $2}' | sed -e 's/[ \t]*$//g;s/^[ \t]*//g'`
								[[ -n "$result_line" ]] && echo "[$db_name $table] $col_1 | $col_2 "  >> $line_report
							else
								echo "[ERROR] [Business] [$db_name $table] does not exist [ $line ]" >> $line_report
							fi
						done
					fi
                                fi
			fi
		done
	done
	error_list=`cat $compare_report | grep 'ERROR.*does not exsit'`
	error_list_line=`cat $line_report |grep 'ERROR' | grep -v 'ENGINE='`
	diff_list=`cat $line_report | grep -vE 'ERROR|ENGINE=|^$'`
	ENGINE_diff_list=`cat $compare_report | grep 'ENGINE='`
	ENGINE_diff_list_line=`cat $line_report | grep -v 'ERROR' | grep 'ENGINE='`
	echo "===================== The Differences Fields List ====================" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "$diff_list" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "================== Does Not Exsit Table or Fields  List ==============" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "$error_list_line" | tee -a $table_structure_report
	echo "$error_list" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "================== The Storage Engine Differences List ===============" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "$ENGINE_diff_list_line" | tee -a $table_structure_report
	echo "$ENGINE_diff_list" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "------ The Detailed Report Locate in $table_structure_report ---------"
	echo "" 
	echo "================================= END ================================" | tee -a $table_structure_report
	
	cd /tmp;rm -f $compare_report $line_report b_line c_line compare_table.tmp c_compare.log b_compare.log
	
}
#-----------------------------------------------------------------------------------
#Menu
function menu(){
echo "###################################################"
echo "#                   Instructions                  #"
echo "#   1: Install PHP Mysql Apache                   #"
echo "#   2: Install Zabbix Server                      #"
echo "#   3: Install Zabbix Agent                       #"
echo "#   4: Contral Zabbix Agent                       #"
echo "#   5: Update scripts for zabbix                  #"
echo "#   6: Synchronous Files                          #"
echo "#   7: Put or Get files from FTP                  #"
echo "#   8: Keepalive LVS configure                    #"
echo "#   9: Stop or Start write file to disk           #"
echo "#  10: Install DHCP FTP NFS                       #"
echo "#  11: Install Single Homed                       #"
echo "#  12: Dump database tables structure             #"
echo "#  13: Compare database tables structure          #"
echo "#  14: Exit                                       #"
echo "###################################################"
PS3="Please Choose One Number:"
select input in "Install Some soft" "Install Zabbix Server" "Install Zabbix Agent" "Contral Zabbix Agent" "Update zabbix scripts" "Synchronous Files" "FTP" "Keepalive LVS" "Crontral Disk Write Monitor" "Install some server" "Single_Homed" "Dump table structure" "Compare table structure" "Exit"
do
case $input in
	"Install Some soft")
		Install_soft
		;;
	"Install Zabbix Server")
		ZB_server
		;;
	"Install Zabbix Agent")
		ZB_agent
		;;
	"Contral Zabbix Agent")
		contral_agent
		;;
	"Update zabbix scripts")
		zb_update
		;;
	"Synchronous Files")
		Sync
		;;
	"FTP")
		ftp
		;;
	"Keepalive LVS")
		LVS
		;;
	"Crontral Disk Write Monitor")
		stop_disk_monitor
		;;
	"Install some server")
		install_dhcp_ftp_nfs
		;;
	"Single_Homed")
		install_single_homed
		;;
	"Dump table structure")
		dump_mysql_structure
		;;
	"Compare table structure")
		compare_table_structure
		;;
	"Exit")
		exit
		;;
esac
done
}
menu
