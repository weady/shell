#!/bin/bash
#
#The script used to install zabbix server
#	by wangdd 2015/10/30
#

#check env function
#
dbip=$1
username=$2
password=$3
z_server=$4
function check(){
php_soft="/usr/local/php/bin"
httpd_proc=`ps -ef | grep httpd | grep -v grep`
httpd_soft="/usr/local/apache/bin"
default_data="/var/lib/mysql"
rpm_mysql=`rpm -qa | grep "mysql-server"`
mysql_pro=`ps -ef | grep mysql | grep -v grep`
mysql_file="/etc/my.cnf"
mysql_db=`cd ${default_data} && find ./ -mindepth 1 -type d | egrep -v "mysql|test"`
zb_server=`ps -ef | grep zabbix_server | grep -v grep`
zb_conf="/usr/local/zabbix/etc/zabbix_server.conf"
[[ -n "$zb_server" || -f "$zb_conf" ]] && echo "zabbix server installed" && clean 
	if [ -d "${php_soft}" ];then
		echo "php installed"
       	else
                echo -e "\033[40;31m php not installed \033[0m"
		clean
	fi
        if [ -d "${httpd_soft}" -o -n "$proc" ];then
                echo "apache installed"
        else
                echo -e "\033[40;31m apache not installed \033[0m"
		clean
        fi
	if [ -n "$rpm_mysql" -o -n "$mysql_pro" -o "$mysql_db" -o -f "$mysql_file" ];then
       	 	echo "mysql installed" 
	else
        	echo -e "\033[40;31m mysql not installed \033[0m" 
		clean
	fi
}
#Install server
function ZB_server(){
	mysql_pro=`ps -ef | grep mysql | grep -v grep`
	if [ -n "$mysql_pro" ];then
	mysql -u$username -p$password -e "use mysql;delete from user where user='';flush privileges;" 
	mysql -u$username -p$password -e "create database zabbix character set utf8;grant all on zabbix.* to zabbix@'%' identified by 'zabbixpass';flush privileges;"
	[[ $? -eq 0 ]] && echo "Zabbix database create sucess" || clean
	else
		echo "mysql not running"
		clean
	fi
	[[ -z `id zabbix` ]] && useradd -s /sbin/nologin zabbix
	cd /usr/local/src/zabbix-2.4.6
	mysql -uzabbix -pzabbixpass zabbix <./mysql/zabbix_def.sql >/dev/null
	[[ $? -ne 0 ]] && echo "init zabbix database failed" && clean
	mysql -uzabbix -pzabbixpass zabbix <./mysql/zabbix.auto.partition.sql >/dev/null
	#mysql -uzabbix -pzabbixpass zabbix <./mysql/schema.sql >/dev/null
	#mysql -uzabbix -pzabbixpass zabbix <./mysql/images.sql >/dev/null
	#mysql -uzabbix -pzabbixpass zabbix <./mysql/data.sql >/dev/null
	./configure \
	--prefix=/usr/local/zabbix \
	--with-mysql \
	--with-net-snmp \
	--with-libcurl \
	--enable-server \
	--enable-agent \
	--enable-proxy
	make && make install
		if [ $? -eq 0 ];then
			echo "zabbix install sucess"
			\cp -a /usr/local/src/zabbix-2.4.6/scripts /usr/local/zabbix
			\cp -a /usr/local/zabbix/scripts/zabbix_server /etc/init.d/zabbix_server
			\cp -a /usr/local/zabbix/scripts/zabbix_agent /etc/init.d/zabbix_agent
			\cp -a /usr/local/src/zabbix-2.4.6/conf/* /usr/local/zabbix/etc
			sed -i "s/192.168.36.130/$z_server/" /usr/local/zabbix/etc/zabbix_server.conf
			sed -i "s/192.168.36.130/$z_server/g" /usr/local/zabbix/etc/zabbix_agentd.conf
			\cp -a /usr/local/zabbix/etc/agentd/zabbix_agentd.conf.d/userparameter_script.conf /usr/local/zabbix/etc/zabbix_agentd.conf.d
			mv /usr/local/php/lib/php.ini	/usr/local/php/lib/php.ini.bak
			\cp -a /usr/local/src/zabbix-2.4.6/conf/php.ini	/usr/local/php/lib
			\cp -a /usr/local/src/zabbix-2.4.6/web/zabbix	/var/www
			sed -i "s/192.168.36.130/$z_server/" /var/www/zabbix/conf/zabbix.conf.php
			echo "1 0 * * * /usr/local/zabbix/scripts/auto.partition.sh >/dev/null" >> /var/spool/cron/root 
			service zabbix_server start
			service zabbix_agent start
		else
			echo "zabbix install failed"
			clean
		fi
}
#install mailx
function mailx_install(){
	mail=`rpm -qa | grep "^mailx-"`
	smtp=`grep "smtp-auth-user" /etc/mail.rc`	
	if [ -z "mail" -o -z "$smtp" ];then
		yum install -y mailx
cat >>/etc/mail.rc <<EOF
set from=wangdd@iPanel.cn smtp=smtp.iPanel.cn
set smtp-auth-user=wangdd smtp-auth-password=xxxx
set smtp-auth=login
EOF
	fi
}
#clean
function clean(){
	rm -rf /usr/local/src/zabbix-2.4.6
	rm -f /usr/local/src/agent_install.sh
	rm -f /usr/local/src/server_install.sh
	exit
}
#main
function main(){
check
if [ $? -eq 0 ];then
	ZB_server
	mailx_install
fi
}
main
