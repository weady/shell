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
        read -p "Zabbix Server Listen IP:" ip
        if [[ "$ip" =~ $rex1 ]];then
		echo " Install zabbix_server to $ip"
		rsync $path/zabbix-2.4.6.tar.gz $ip:$path
		ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz;bash server_install.sh"
		check_ok "$ip" "zabbix_server"
        else
                echo "Illegal IP"
        fi
}

#Install Zabbix_agent
function ZB_agent(){
	read -p "Input Zabbix Server ip:" sip
	read -p "Input Agent ips(eg:192.168.1.1-123):" ips
	[[ "$sip" =~ $rex1 ]] && serverip="$sip" || echo "Zabbix Server ip Error";exit
	if [[ "$ips" =~ $rex1 || "$ips =~ $rex2" ]];then
		f_splitips "$ips"
		ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
		for ip in ${ip_list}
		do
			echo " Install zabbix_agent to $ip"
			rsync $path/zabbix-2.4.6.tar.gz $ip:$path
			ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz;bash agent_install.sh $ip $serverip"
			check_ok "$ip" "zabbix_agent"
		done
	else
		echo "Error"
	fi
}
#check function
function check_ok(){
	if [ $? -eq 0 ];then
		echo "$1 install $2 success"
	else
		echo "$1 install $2 failed"
	fi
}
#contral zabbix_agent
function contral(){
	read -p "Input Agent Ips(eg:192.168.1.1 or 192.168.1.1-100):" ips
	if [[ "$ips" =~ $rex1 || "$ips" =~ $rex2 ]];then
		f_splitips "$ips"
		ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
		read -p "Choise one{status|start|restart|stop}:" command
		case $command in
		status)
			comm
			;;
		start)
			comm
			;;	
		restart)
			comm
			;;	
		stop)
			comm
			;;
		*)
			echo "Error"
			;;
		esac
	else
		echo "Error"
	fi
}
#command 
function comm(){
	for ip in ${ip_list}
	do
		echo "------------$ip--------------------"
		ssh $ip "service zabbix_agent $command"
	done
}
#input zabbix_server ip
function check_ip(){
        read -p "Server IP(eg:192.168.1.1 or 192.168.1.1-100) :" ip
        if [[ "$ip" =~ $rex1 || "$ip" =~ $rex2 ]];then
		f_splitips "$ip"
                ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
	else
		echo "Ip error"
	fi
}
#check soft installed or not
function check_soft(){
	check_ip
}
function comm01(){
	for list in ${ip_list}
	do
		echo "-------------------$list-------------------"
		ssh $list "cd /usr/local/src && bash ${1}_install.sh"
		check_ok "$ip" "$softname"
	done
}
#Install some soft to IP
function Install_soft(){
	check_ip
	read -p "Choise your want install soft:{php|mysql|apache} :" softname
	case $softname in
		php)
			comm01 "$softname"
		;;
		mysql)
			comm01 "$softname"
		;;
		apache)
			comm01 "$softname"
		;;
		*)
			echo "Usage {php|mysql|apache}"
			;;
	esac
}
#sync files to some where
function Sync(){
	read -p "Input source dst_ip dst(eg: /homed/test 1.1.1.1 /homed):" src dstip dst
        if [[ "$dstip" =~ $rex1 || "$dstip" =~ $rex2 ]];then
		rsync $src $dstip:$dst
		[[ $? -eq 0 ]] && echo "SYNC Success" || echo "SYNC Failed"
	else
                echo "Ip error"
        fi
}
#Memu
echo "###################################################"
echo "#                   Instructions                  #"
echo "#   1: Check PHP MYSQL Apache Installed or Not    #"
echo "#   2: Install PHP Mysql Apache                   #"
echo "#   3: Install Zabbix Server                      #"
echo "#   4: Install Zabbix Agent                       #"
echo "#   5: Contral Zabbix Agent                       #"
echo "#   6: Synchronous Files                          #"
echo "#   7: Exit                                       #"
echo "###################################################"
PS3="请选择一个数字:"
select input in "Check Soft" "Install Some soft" "Install Zabbix Server" "Install Zabbix Agent" "Contral Zabbix Agent" "Synchronous Files" "Exit"
do
case $input in
	"Check Soft")
		check_soft
		;;
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
		contral
		;;
	"Synchronous Files")
		Sync
		;;
	Exit)
		exit
		;;
esac
done
