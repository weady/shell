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
        read -p " Zabbix Server Listen IP:" ip
	read -p " Databae IP:" dbip
        read -p " Databae user:" username
        read -p " Databae passwd:" password
        if [[ "$ip" =~ $rex1 ]];then
		echo "---- Install zabbix_server in $ip----"
		rsync $path/zabbix-2.4.6.tar.gz $ip:$path
		ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz >/dev/null;./server_install.sh $dbip $username $password $ip"
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
			ssh $ip "cd $path;tar zxvf zabbix-2.4.6.tar.gz >/dev/null;./agent_install.sh $ip $serverip"
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
	read -p "Input Agent Ips(eg:192.168.1.1 or 192.168.1.1-100):" ips
	if [[ "$ips" =~ ^$rex1$ || "$ips" =~ ^$rex2$ ]];then
		f_splitips "$ips"
		ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
		read -p "Choise one{status|start|restart|stop}:" command
		case $command in
		status)
			agent_comm
			;;
		start)
			agent_comm
			;;	
		restart)
			agent_comm
			;;	
		stop)
			agent_comm
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
function agent_comm(){
	for ip in ${ip_list}
	do
		echo "------------$ip--------------------"
		ssh $ip "service zabbix_agent $command"
	done
}
#input zabbix_server ip
function check_ip(){
        read -p "Input Server IP(eg:192.168.1.1 or 192.168.1.1-100) :" ip
        if [[ "$ip" =~ ^$rex1$ || "$ip" =~ ^$rex2$ ]];then
		f_splitips "$ip"
                ip_list=`echo $last_split_ips | sed 's/ /\n/g'`
	else
		echo "Invalid IP"
		check_ip
	fi
}
#check soft installed or not
function check_soft(){
	check_ip
	for list in ${ip_list}
	do
		echo "-------------------$list-------------------"
		rsync -avz $path/scripts/check.sh $list:$path >/dev/null
		ssh $list "cd $path && ./check.sh"
	done
}
function deploy(){
	for list in ${ip_list}
	do
		echo "-------------------$list-------------------"
		rsync -az $path/apache.tar.gz $list:$path >/dev/null
		rsync -az $path/scripts/${1}_install.sh $list:$path >/dev/null
		ssh $list "source /etc/profile;cd $path;./${1}_install.sh"
		check_ok "$ip" "$softname"
	done
}
#Install some soft to IP
function Install_soft(){
	check_ip
	read -p "Choise your want install soft:{php|mysql|apache} :" softname
	case $softname in
		php)
			rsync -az $path/php.tgz $list:$path >/dev/null
			deploy "$softname"
		;;
		mysql)
			rsync -az $path/mysql5.5.33.tgz $list:$path >/dev/null
			rsync -az $path/my.cnf $list:$path >/dev/null
			deploy "$softname"
		;;
		apache)
			rsync -az $path/apache.tar.gz $list:$path >/dev/null
			rsync -az $path/httpd-2.2.22-source.tar.gz $list:$path >/dev/null
			deploy "$softname"
		;;
		*)
			echo "Usage {php|mysql|apache}"
			;;
	esac
}
#sync files to some where
function Sync(){
	check_ip
	read -p "Input source dir or files:" src
	read -p "Input destination dir or files:" dst
	for ip in ${ip_list} 
	do
		echo "-----Sync files to $ip-----"
		rsync -avz $src $ip:$dst
		[[ $? -eq 0 ]] && echo "SYNC Success" || echo "SYNC Failed"
        done
}
#contral apache 
function contral_apache(){
	check_ip
	echo "-------Choise Option----------"
	echo " 1:extension ssl mode"
	echo " 2:start or stop apache"
	read -p "Your choise:" num
	case $num in
	1)
		exten_ssl_mode
		;;
	2)
		con_apache
		;;
	*)
		echo "Error Choise"
	esac
}
#apache extension ssl mode
function exten_ssl_mode(){
	for ip in ${ip_list}
	do
		echo "-----Extention SSL Mode for $ip,Please Waiting.....-----"
		rsync -az $path/apache-2.2.22-ssl.tar.gz $ip:$path
		ssh $ip "source /etc/profile;cd $path;tar zxvf apache-2.2.22-ssl.tar.gz >/dev/null;./ex_ssl.sh \"$ip\"" | tee -a $path/exssl.log
	done 
	S_nu=`grep Sucess $path/exssl.log | wc -l`
	E_nu=`grep Failed  $path/exssl.log | wc -l`
	E_list=`grep Failed  $path/exssl.log`
	Ap_nu=`grep "not installed" $path/exssl.log | wc -l`
	Ap_list=`grep "not installed" $path/exssl.log`
	num=`expr $E_nu + $Ap_nu`
	if [ "$E_nu" -gt 0 -o "$Ap_nu" -gt 0 ];then
        	echo -e "\033[40;31m Success:${S_nu} \033[0m" 
        	echo -e "\033[40;31m Errors:${num} \033[0m" 
        	echo -e "\033[40;31m Errors Lists:\033[0m" 
		echo "$E_list"
		echo "$Ap_list"
	else
        	echo -e "\033[40;31m Success:${S_nu} \033[0m" 
	fi
	rm -f $path/exssl.log
}
#start or stop apache
function con_apache(){
	echo "Start or Stop apache:"
	read -p "Choise command (start|stop|restart):" command
	for ip in ${ip_list}
	do
		echo "--$command apache in $ip--"
		ssh $ip "source /etc/profile;cd /usr/local/apache/bin;./httpd -k $command"
	done
}
#Get or Put file to FTP
function ftp(){
	ftp_ip="ftp.ipanel.cn"
	username="homedmaintain"
	passwd="HomedMaintain44"
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
#Menu
function menu(){
echo "###################################################"
echo "#                   Instructions                  #"
echo "#   1: Install PHP Mysql Apache                   #"
echo "#   2: Install Zabbix Server                      #"
echo "#   3: Install Zabbix Agent                       #"
echo "#   4: Contral Zabbix Agent                       #"
echo "#   5: Contral Apache                             #"
echo "#   6: Synchronous Files                          #"
echo "#   7: Put or Get files from FTP                  #"
echo "#   8: Exit                                       #"
echo "###################################################"
PS3="Please Choise One Number:"
select input in "Install Some soft" "Install Zabbix Server" "Install Zabbix Agent" "Contral Zabbix Agent" "Contral Apache" "Synchronous Files" "FTP" "Exit"
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
	"Contral Apache")
		contral_apache
		;;
	"Synchronous Files")
		Sync
		;;
	"FTP")
		ftp
		;;
	Exit)
		exit
		;;
esac
done
}
menu
