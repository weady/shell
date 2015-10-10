#!/bin/bash
#
#
#this script used to install zabbix_agent
#
#
#	by wangdd 2015/10/8
#
#
##check_ok function

function check_ok(){
	if [ $? -eq 0 ];then
		echo "ok"
	else
		echo "Error,please check"
		exit 1
	fi
}
function check_agent(){
	znum=`ps -ef | grep -c zabbix_agent`
	zsbin="/usr/local/zabbix/sbin/zabbix_agentd"
	if [ $znum -gt 1 ] || [ -f $zsbin ];then
		echo "zabbix_agent is installed"
		exit 1
	fi
}

path="/usr/local/zabbix"
ip_agent=`ifconfig | grep '192.168.36' |awk -F '[ :]+' '{print $4}'`
### add zabbix user
id zabbix || useradd zabbix -s /sbin/nologin
##install zabbix
dst_path="/usr/local/src"
ftp_user="homedmaintain"
ftp_passwd="HomedMaintain44"
file="zabbix-2.4.6.tar.gz"
url="http://192.168.10.112:30/homedmaintain"
if [ -f $dst_path/$file ];then
	echo " $file exist"
else
	wget --ftp-user=$ftp_user --ftp-password=$ftp_passwd $url/soft/$file -P $dst_path >/dev/null
fi
check_ok
check_agent
cd $dst_path
tar zxvf $file
cd zabbix-2.4.6
./configure --prefix=$path --enable-agent --with-net-snmp 
make && make install
check_ok
##modify config_file
cd $path/etc && rm -rf zabbix*
mkdir -p $path/scripts
cp -ar $dst_path/zabbix-2.4.6/agend/* $path/etc/
check_ok
sed -i "s/slave30/$ip_agent/" $path/etc/zabbix_agentd.conf
check_ok
## start zabbix_agent
$path/sbin/zabbix_agentd -c $path/etc/zabbix_agentd.conf
check_ok
