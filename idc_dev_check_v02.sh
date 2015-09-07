#!/bin/bash
#
#
#This script is used to check IDC development!
#
#	wangdd 2015/7/16
#
hadoop_path="/usr/local/hadoop/hadoop-1.2.1"
log_file="/var/log/idc_check/`date +%Y-%m-%d[%T]`.report"
log_dir="/var/log/idc_check"
if [ -n "$log_dir" ]
then
	mkdir -p /var/log/idc_check
fi

#check soft or command function
function soft_command()
{
soft_file="ifstat lrzsz dos2unix"
for command_file in $soft_file
do
	soft_ex=`rpm -qa | grep $command_file 2>/dev/null`
	comm_ex=`type $command_file 2>/dev/null`
	if [ ! -z "$comm_ex" ] || [ ! -z "soft_ex" ];then
		echo "$command_file soft installed!" >> $log_file
	else
		echo "$command_file not installed,Please installed!" >> $log_file 
	fi
done
}

# check service status function
function ser_status()
{
	S1=`chkconfig --list | grep $1`
	S2=`grep $1 /etc/rc.d`
	S3=`grep $1 /etc/rc.d/rc.local`
	if [  ! -z "$S1" ]
	then
        	echo "$1 Server Add Through Chkconfig!!" >> $log_file
        	echo "$S1" >> $log_file
	fi
	if [ ! -z "$S2" ]
	then
        	echo "$1 Server Add To /etc/rc.d!!" >> $log_file
        	echo "$S2" >> $log_file
	fi
	if [ ! -z "$S3" ]
	then
        	echo "$1 Server Add To /etc/rc.d/rc.local!!" >> $log_file
        	echo "$S3" >> $log_file
	fi
	if [ -z "$S1" ] && [ -z "$S2" ] && [ -z "$S3" ] 
	then
		echo " " >> $log_file
		echo "Please Add $1 Along With System Start! eg: vi /etc/rc.d/rc.local or chkconfig --add XX" >> $log_file
	fi
}
echo "Start IDC Development Check,Please Waiting!" | tee 
echo "                                                                                    " >> $log_file
echo "------------------------------------------------------------------------------------" >> $log_file
echo "                 Start Check IDC Development at `date +%Y-%m-%d[%T]` " >> $log_file
echo "------------------------------------------------------------------------------------" >> $log_file
echo "                                                                                    " >> $log_file
echo "**********************" >> $log_file
echo "* System Information *" >> $log_file
echo "**********************" >> $log_file
echo " " >> $log_file
echo "HOSTNAME:`hostname`" >> $log_file
echo "System Version:" `cat /etc/issue | head -n 1` >> $log_file
echo "Product Name:" `dmidecode | grep "Product" | head -n 1 |sed 's/^[[:space:]]*//g'` >> $log_file
echo "CPU:" `cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c | sed 's/^[[:space:]]*//g'` >> $log_file
echo "MEM:`free -m | grep Mem | awk '{print $2}'`M" >> $log_file
echo " " >> $log_file
echo "**********************" >> $log_file
echo "*  Disk Information  *" >> $log_file
echo "**********************" >> $log_file
echo " " >> $log_file
df -l >> $log_file
echo " " >> $log_file
echo "***********************" >> $log_file
echo "* Network Information *" >> $log_file
echo "***********************" >> $log_file
echo " " >> $log_file
echo "DNS:`cat /etc/resolv.conf`" >> $log_file
echo " " >> $log_file
ifconfig -a | egrep -A 1 "em|eth|vir" >> $log_file
echo " " >> $log_file
echo "Router Information:" >> $log_file
route -n >> $log_file
echo " " >> $log_file
echo "*************************" >> $log_file
echo "* Check Iptables Status *" >> $log_file
echo "*************************" >> $log_file
echo " " >> $log_file
service iptables status >> $log_file
echo " " >> $log_file
echo "*****************" >> $log_file
echo "* Schedule Task *" >> $log_file
echo "*****************" >> $log_file
echo " " >> $log_file
crontab -l >> $log_file
echo " " >> $log_file
echo "*********************" >> $log_file
echo "* Check Soft Exists!*" >> $log_file
echo "*********************" >> $log_file
echo " " >> $log_file
soft_command
#------------------------------------------------
#Server Status Check
list="crond ssh mysql apache ftp tomcat nfs irq"
for ser in $list
	do
		if [ $ser="apache" ];then
			proc_state_apa=`ps -ef | grep httpd`
			echo "*****************************" >> $log_file
			echo "* Check $ser Server Status *" >> $log_file
			echo "*****************************" >> $log_file
			ser_status $ser
			echo " " >> $log_file
		  	if [ ! -z "$proc_state_apa" ];then
				echo "$ser is running!" >> $log_file
			else
				echo "$ser is not running,please check!" >> $log_file
			fi
		else
			proc_state=`ps -ef | grep $ser`
			echo " " >> $log_file
			echo "*****************************" >> $log_file
			echo "* Check $ser Server Status *" >> $log_file
			echo "*****************************" >> $log_file
			ser_status $ser
			echo " " >> $log_file
		  	if [ ! -z "$proc_state" ];then
				echo "$ser is running!" >> $log_file
				echo " " >> $log_file
			else
				echo "$ser is not running,please check!" >> $log_file
				echo " " >> $log_file
			fi
		fi			
	done

echo " " >> $log_file
echo "*************************" >> $log_file
echo "* Check JDK Development *" >> $log_file
echo "*************************" >> $log_file
cat /etc/profile | egrep -3 "hadoop|jdk" >> $log_file
echo " " >> $log_file 
echo "JAVA version:" >> $log_file
echo "--------------" >> $log_file
java -version 2>>$log_file
echo " " >> $log_file
echo "****************************" >> $log_file
echo "* Check Hadoop Development *" >> $log_file
echo "****************************" >> $log_file
echo " " >> $log_file
echo "Hadoop Version:" >> $log_file
echo "--------------" >> $log_file
hadoop version >> $log_file
echo " " >> $log_file
echo "Hadoop config:" >> $log_file
echo "--------------" >> $log_file
grep -E -C 1 "hadoopdata|http.address" $hadoop_path/conf/hdfs-site.xml  | awk -F"<|>" '{print $3}' | sed '/^$/d' >> $log_file
echo " " >> $log_file
echo "Hadoop Status:" >> $log_file
echo "--------------" >> $log_file
jps | grep "^[0-9].*[a-z]$" >> $log_file
echo " " >> $log_file
echo "********************************************************"
echo -e "\033[44;37;5m The Report Stored In $log_file \033[0m"
echo "********************************************************"
echo " Complete !" 
