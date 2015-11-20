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

#
function clean(){
rm -rf /usr/local/src/zabbix-2.4.6
rm -f /usr/local/src/agent_install.sh
rm -f /usr/local/src/server_install.sh
exit
}

function check_ok(){
	if [ $? -eq 0 ];then
		echo "ok"
	else
		echo "Error,please check"
		clean
	fi
}
function check_agent(){
	znum=`ps -ef | grep -c zabbix_agent`
	zsbin="/usr/local/zabbix/sbin/zabbix_agentd"
	if [ $znum -gt 1 ] || [ -f $zsbin ];then
		echo "zabbix_agent is installed"
		clean
	fi
}
#-----------------------------------------------------------------
### add zabbix user
id zabbix || useradd zabbix -s /sbin/nologin
##install zabbix
clientip="$1"
serverip="$2"
path="/usr/local/zabbix"
dst_path="/usr/local/src"
check_agent
cd $dst_path/zabbix-2.4.6
./configure --prefix=$path --enable-agent --with-net-snmp 
make && make install
check_ok
##modify config_file
cd $path/etc && rm -rf zabbix*
mkdir -p $path/scripts
\cp -ar $dst_path/zabbix-2.4.6/agent/* $path/etc/
\cp -ar $dst_path/zabbix-2.4.6/scripts/* $path/scripts/
\cp -a $dst_path/zabbix-2.4.6/scripts/zabbix_agent /etc/init.d
check_ok
sed -i "s/zabbixagentip/$clientip/" $path/etc/zabbix_agentd.conf
sed -i "s/zabbixserip/$serverip/" $path/etc/zabbix_agentd.conf
check_ok
## start zabbix_agent
$path/sbin/zabbix_agentd -c $path/etc/zabbix_agentd.conf
[[ $? -eq 0 ]] && echo "zabbix agent installed success"
