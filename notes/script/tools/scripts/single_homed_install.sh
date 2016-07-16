#!/bin/bash
#
#	by wangdd 2016/06/27
#
#此脚本主要功能是部署单机版homed
#
#
client_ip=$1
#---------------------------------------------------
#需要安装的软件目录以及软件包信息
soft_path="/usr/local/soft"
jdk_path="/usr/java"
jdk_soft="/usr/local/soft/jdk1.7.0_55.tgz"
tomcat_path="/usr/local/tomcat"
tomcat_soft="/usr/local/soft/tomcat.tgz"
mysql_path="/usr/local/mysql"
mysql_data_path="/r2/mysqldata"
mysql_soft="/usr/local/soft/mysql-5.5.33-green.tar.gz"
apache_path="/usr/local/apache"
apache_soft="/usr/local/soft/apache-2.2.21-green.tar.gz"
http_data_path="/homed/homedbigdata/httpdata/clusterdata"
php_path="/usr/local/php"
php_soft="/usr/local/soft/php-5.5.7-green.tar.gz"
hadoop_soft="/usr/local/soft/hadoop-2.6.4-singlenode.tar.gz"
ifstat_path="/usr/local/ifstat"
ifstat_soft="/usr/local/soft/ifstat-1.1.tar.gz"
megacli_path="/opt/MegaRAID/MegaCli"
megacli_soft="/usr/local/soft/megacli.tar.gz"
libxml2_path="/usr/local/libxml2"
libxml2_soft="/usr/local/soft/libxml2-2.7.2.tar.gz"
app_soft="/usr/local/soft/application-20160524.tgz"
homed_soft="/usr/local/soft/single-release-20160524.tgz"
#---------------------------------------------------
#修改系统的基本参数函数
function modify_base(){
	echo "------------------------------------------------------------------------"
	echo "Starting Modify Base Configure !!"
	echo "------------------------------------------------------------------------"
	kernel_ver=`uname -r | awk -F '.' '{print $1}'`
	hostname="master"
	local_ip=`hostname -i | awk '{print $1}'`
	header=`echo "$local_ip" | awk -F '.' '{print $3"."$4}'`
	yum install -y openssh-server openssh-clients openssh gcc gcc-c++ gdb nfs-utils sysstat dos2unix bind libpng-devel libpng bc net-snmp &>/dev/null
	key="/root/.ssh/id_rsa"
	if [[ -f "$key" ]]; then
		ssh-copy-id root@${local_ip}
	else
		ssh-keygen -t rsa -N "" -f $key
		ssh-copy-id root@${local_ip}
	fi
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
	sed -i "s/@\\h \\W]/@\\h-($header) \\w]/g" /etc/bashrc
	echo "$local_ip $hostname" >>/etc/hosts
	echo "$local_ip secondmaster" >>/etc/hosts
	if [[ "$kernel_ver" -eq 3 ]]; then
		echo "$hostname" >/etc/hostname
		hostnamectl set-hostname $hostname
		systemctl stop firewalld.service
	else
		hostname $hostname
		sed -i "s/HOSTNAME=.*/HOSTNAME=$hostname/g" /etc/sysconfig/network
		service stop iptables
	fi
	if [ -d /r2 ]; then
		echo "Create Directories And Soft Links..."
		mkdir /r2/homed
		mkdir /r2/hadoop
		ln -s /r2/homed /usr/local/homed
		ln -s /r2/hadoop /usr/local/hadoop
		ln -s /usr/local/homed /homed
		ln -s /usr/local/hadoop /hadoop
		ln -s /usr/local/homed /root/homed
		ln -s /usr/local/hadoop /root/hadoop
		mkdir /r2/hadoopdata
		echo "Complete Base Configure"
	else
		echo "Create /r2 Amd Mount The Raid1 Disk at First"
		exit 
	fi
}
#---------------------------------------------------
#提示下载软件包函数
function prompt(){
	echo "------------------------------------------------------------------------"
	echo "You Should Download Softwares from FTP(ftp.ipanel.cn/soft/homed_need_install_soft/) to $soft_path!"
	echo "------------------------------------------------------------------------"
	echo "jdk1.7.0_55.tgz,tomcat.tgz,mysql-5.5.33-green.tar.gz,apache-2.2.21-green.tar.gz,php-5.5.7-green.tar.gz"
	echo "single-release-XXXX.tgz,ifstat-1.1.tar.gz,megacli.tar.gz,libxml2-2.7.2.tar.gz,application-XXX.tgz"
	echo "------------------------------------------------------------------------"
	read -n1 -p "Are You Sure Starting Install Single Homed [Y/N]? " answer
	if [[ "$answer" =~ y|Y ]];then
		install_tag="Yes"
	else
		echo ""
		exit
	fi
}
#---------------------------------------------------
#安装jdk软件函数
function install_jdk(){
	echo "------------------------------------------------------------------------"
	echo "Starting Install JDK To $jdk_path Software Version is jdk1.7.0_55.tgz"
	echo "------------------------------------------------------------------------"
	if [[ -d "$jdk_path" ]]; then
		echo "JDK Has Installed"
	else
		if [[ -f "$jdk_soft" ]]; then
			mkdir -p $jdk_path
			tar -xvf $jdk_soft -C $jdk_path >/dev/null 2>&1
			chmod -R 755 $jdk_path
			[[ $? -eq 0 ]] && echo "JDK Install Sucess!" || exit
		else
			echo "$jdk_soft does not exsit in $soft_path !"
			exit
		fi
	fi
}
#---------------------------------------------------
#安装tomcat函数
function install_tomcat(){
	echo "------------------------------------------------------------------------"
	echo "Starting Install Tomcat To $tomcat_path Software Version is tomcat.tgz"
	echo "------------------------------------------------------------------------"
	if [[ -d "$tomcat_path" ]]; then
		echo "tomcat Has Installed"
	else
		if [[ -f "$tomcat_soft" ]]; then
            		tar -xvf $tomcat_soft -C /usr/local/ >/dev/null 2>&1
            		chmod -R 755 /usr/local/tomcat
            		cd /usr/local/tomcat/bin/
            		./startup.sh >/dev/null 2>&1
            		[[ $? -eq 0 ]] && echo "Tomcat Install Sucess!" || exit
        	else
        		echo "$tomcat_soft does not exsit"
			exit
		fi
	fi
}
#---------------------------------------------------
#安装lamp函数
function install_lamp(){
	echo "------------------------------------------------------------------------"
	echo "Starting Install MySQL Apche PHP,Please waiting......"
	echo "------------------------------------------------------------------------"
	#------------------
	#install mysql
	mysql_port=`netstat -unltp | grep 3306`
	if [ ! -z "$mysql_port" -o -d "$mysql_path" ];then
		echo "mysql have installed"
	else
		if [[ -f "$mysql_soft" ]]; then
			echo "Starting Install Mysql-5.5.33,Please waiting....."
			yum remove -y MySQL-server* MySQL-devel mysql* >/dev/null 2>&1
			[[ -z `id mysql` ]] && useradd mysql
			cd $soft_path
	 	        tar zxvf mysql-5.5.33-green.tar.gz -C /usr/local/ >/dev/null
	        	[[ -f /etc/my.cnf  ]] && mv /etc/my.cnf /etc/my.cnf.bak
	        	\cp /usr/local/mysql/data/my.cnf /etc/
	        	if [ -d "$mysql_data_path" ];then
	        		echo "--/r2/mysqldata exist,it will backup on /r2/mysqldata_back--"
	            		if cp -r  /r2/mysqldata /r2/mysqldata_back &>/dev/null ;then
	            			rm -rf /r2/mysqldata
	            		fi
	        	fi
	        	mkdir /r2/mysqldata -pv &>/dev/null
	        	chown -R mysql:mysql /r2/mysqldata
	        	/usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/r2/mysqldata &>/dev/null
	        	\cp /usr/local/mysql/support-files/mysql.server  /etc/init.d/mysqld
			echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
			source /etc/profile
	        	service mysqld start >/dev/null && echo "start mysql sucess"
	        	mysql -uroot -e "SET PASSWORD = PASSWORD('123456');drop database test"
	        	[[ $? -eq 0 ]] && echo "MYSQL Install Sucess,Default Password is ‘123456’,Please Changed!!"
		else
			echo "$mysql_soft does not exist"
			exit
		fi
	fi

	#------------------
	#install apache
	[[ ! -d "$httpd_data_path" ]] && mkdir -p $http_data_path
	httpd_port=`netstat -unltp | grep ':80\>'`

	if [[ -n "$httpd_port" || -d "$apache_path" ]]; then
		echo "apache has installed"
	else
		if [[ -f "$apache_soft" ]]; then
			echo "Starting Install Apache-2.2.21,Please waiting....."
			cd $soft_path
	        	tar zxvf apache-2.2.21-green.tar.gz -C /usr/local/ >/dev/null
	        	[[ ! -d "/var/www/html" ]] && mkdir -p /var/www/html
	        	/usr/local/apache/bin/httpd -k start && echo 'start httpd success'
			auto_start=`cat /etc/rc.local | grep '/usr/local/apache/'`
			[[ -z "$auto_start" ]] && echo "/usr/local/apache/bin/httpd -k start" >>/etc/rc.local
		else
			echo "$apache_soft does not exist"
			exit
		fi
	fi
	#------------------
	#install php
	if [ -d "$php_path" ];then
		echo "PHP have installed"
	else
		if [[ -f "$php_soft" ]]; then
			echo "Starting Install PHP-5.5.7,Please waiting....."
			cd $soft_path
           		 tar zxvf php-5.5.7-green.tar.gz -C /usr/local/ >/dev/null
			[[ $? -eq 0 ]] && echo "PHP install sucess"
		else
			echo "$php_soft does not exist"
			exit
		fi
	fi
}
#---------------------------------------------------
#安装hadoop单机版
function install_hadoop(){
	install_jdk
	[[ $? -eq 0 ]] && echo "Starting Install Hadoop To "
	echo "PATH=$PATH:/usr/java/jdk1.7.0_55/bin" >>/etc/profile
	source /etc/profile
	tar zxvf $hadoop_soft -C /r2/hadoop/
	cd /r2/hadoop/hadoop-2.6.4
	echo "master" >etc/hadoop/slaves
	sed -i 's/>.*:12690/>0.0.0.0:12690/g' etc/hadoop/core-site.xml
	bin/hdfs namenode -format &>/dev/null
	usleep 1000
	sbin/start-dfs.sh &>/dev/null
	usleep 1000
	sbin/start-yarn.sh &>/dev/null
	hadoop_result=`jps | grep -v 'Jps' | wc -l`
	hdfs_port=`netstat -unltp | grep 50070`
	if [ "$hadoop_result" -eq 5 -a -n "$hdfs_port" ]; then
		echo "Hadoop Install sucess"
	else
		echo "Hadoop install false"
		exit
	fi
}
#---------------------------------------------------
#安装其他必须软件包函数libxml2 ifstat megacli
function install_other_soft(){
	echo "------------------------------------------------------------------------"
	echo "Starting Install libxml2、ifstat、megacli,Please waiting......"
	echo "------------------------------------------------------------------------"
	if [[ ! -d "$ifstat_path" ]]; then
		cd $soft_path
		tar zxvf ifstat-1.1.tar.gz &>/dev/null
		cd ifstat-1.1
		./configure &>/dev/null
		make &>/dev/null
		make install &>/dev/null 
		[[ $? -eq 0 ]] && echo "Ifstat Soft Install Success" || exit
	fi
	if [[ ! -d "$libxml2_path" ]];then
		cd $soft_path
		tar zxvf libxml2-2.7.2.tar.gz &/dev/null
		cd libxml2-2.7.2
		./configure --prefix=/usr/local/libxml2 &>/dev/null
		make && make install &>/dev/null
		[[ $? -eq 0 ]] && echo "libxml2 soft Install Success" || exit
	fi
	if [[ ! -d "$megacli_path" ]]; then
		cd $soft_path
		tar zxvf megacli.tar.gz &>/dev/null
		rpm -i Lib_Utils-1.00-09.noarch.rpm MegaCli-8.00.48-1.i386.rpm --nodeps &>/dev/null
		[[ $? -eq 0 ]] && echo "megacli soft install Success" || exit
		rm -f Lib_Utils-1.00-09.noarch.rpm MegaCli-8.00.48-1.i386.rpm
	fi
}
#---------------------------------------------------
#部署单机homed函数
function modify_ips(){
	oldip=$1
	newip=$2

	cd /homed
	./stopall.sh
	cd $HADOOP_HOME/bin
	./stop-all.sh
	oldgw={oldip%.*}".1"
	newgw={newip%.*}".1"
	oldnet={oldip%.*}
	newnet={newip%.*}
	# hadoop  homed weatherMgr application
	sed -i "s/$oldip/$newip/g" $HADOOP_HOME/etc/hadoop/*.xml $HADOOP_HOME/etc/hadoop/masters $HADOOP_HOME/etc/hadoop/slaves /etc/hosts /homed/*.sh /homed/*.xml /homed/*/config/config.xml  /homed/redis/config/*.conf /homed/appinstall/*/config/config.xml /homed/maintain/*/*.sh /homed/spark/exe/config.xml /var/www/html/weatherMgr/index.php /var/spool/cron/root /var/www/html/application/homedPortal/js/data.js /var/www/html/application/webFront/monitor/monitor/app/config/*.yml /var/www/html/weatherMgr/*.php /var/www/html/iwds_admin/model/*.php
	sed -i "s/$oldnet/$newnet/g" /homed/config_comm.xml /homed/*/config/config.xml
	rm -rf /var/www/html/application/webFront/monitor/monitor/app/cache/*
	#Mysql iuds  backend 
	sqltxt="use homed_iuds;update dns_domain_info set domain_info=replace(domain_info,\"$oldip\",\"$newip\");update server_info set server_oip=replace(server_oip,\"$oldip\",\"$newip\"),server_ip=replace(server_ip,\"$oldip\",\"$newip\");use homed_backend;update monitor_server set server_ip=replace(server_ip,\"$oldip\",\"$newip\");"
	echo $sqltxt > sql.txt
	mysql -u root -p123456  < sql.txt
	if [[ $? -eq 0 ]]; then
		echo "Update dns_domain_info table sucess"
		rm -f sql.txt
	else
		echo "Update dns_domain_info table false"
		exit
	fi
	#Mysql delete eit_history video zaker
	sqltxt="use homed_dtvs;delete from homed_eit_schedule_history;delete from event_series;delete from video_series;delete from video_info;delete from t_news_info;delete from promotion_program_user_record;delete from promotion_program_published;delete from promotion_program_editing;delete from user_video_raw_data;delete from video_record;use homed_ilog;delete from t_program_hits;delete from t_program_praise;delete from t_program_sort;delete from t_program_sort_record;delete from t_user_hits_info;delete from t_video_ocr_info;delete from user_history;use homed_tsg;delete from tsg_total_idx_hdcctv1;delete from tsg_total_idx_hdszdsj;delete from tsg_total_idx_sdbjws;delete from tsg_total_idx_sdcctv15;delete from tsg_total_idx_sdcctv2;delete from tsg_total_idx_sdcctvx2;delete from tsg_total_idx_sdjykt;delete from tsg_total_idx_sdzjws;drop database homed_maintain;create database homed_maintain DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci"
	echo $sqltxt > sql.txt
	mysql -u root -p123456  < sql.txt
	if [[ $? -eq 0 ]]; then
		echo "Delete old data sucess"
		rm -f sql.txt
	else
		echo "Delete old data false"
		exit
	fi
	#network
	sed -i "s/$oldip/$newip/g" /etc/sysconfig/network-script/ifcfg-*
	sed -i "s/$oldgw/$newgw/g" /etc/sysconfig/network-script/ifcfg-*
	#service network restart
}
function deploy_homed(){
	echo "------------------------------------------------------------------------"
	echo "Starting Deploy Single Homed Software Version is single-release-20160524.tgz,Please waiting......"
	echo "------------------------------------------------------------------------"
	if [[ ! -f "$homed_soft" ]]; then
		echo "Please download homed's soft from ftp (ftp.ipanel.cn/version/single-machine/)"
		exit
	else
		tar -zxvf $homed_soft -C / &>/dev/null
		mysql -u root -p123456 < /r2/all_dbs.sql
		if [[ $? -eq 0 ]]; then
			echo "Init Database Sucess,Starting Modify IPs For Configure Files"
			modify_ips "192.168.101.106" "$client_ip"
		fi
	fi
}
#---------------------------------------------------
#部署单机版Homed主函数
function main(){
	prompt
	if [ "$install_tag" == "Yes" ];then
		echo ""
		echo "------------------------------------------------------------------------"
		echo "starting install"
		modify_base
		install_jdk
		install_tomcat
		install_lamp
		install_other_soft
		deploy_homed
	fi
}

main
