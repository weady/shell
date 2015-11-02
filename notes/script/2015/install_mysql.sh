#!/bin/bash
#
#The script used to install mysql-5.5.46 database
#
# by wangdd 2015/11/2
#
#
#install base packages,eg:cmake|bison|gcc-c++|ncurses
#cmake 编译安装5.5版本以上的数据库使用
#bison 语法分析器生成器
#gcc-c++ 编译器
#ncurses 提供字符终端处理库，包括面板和菜单
#ncurses-devel ncurses的环境
mysql_path="/usr/local/mysql"
db_path="/usr/local/mysql/data"
soft_path="/usr/local/src"
function check(){
	list="cmake bison gcc-c++ ncurses"
	for soft in $list
	do
		result=`rpm -qa | grep "${soft}-[0-9]"`
		if [ -z "$result" ];then 
			yum install -y $soft
			[[ $? -eq 0 ]]&& echo "$soft installed sucess" || exit
		fi
	done
}
#install mysql
function install_mysql(){
	check
	if [ $? -eq 0 ];then
		echo "Starting  install mysql"
		wget http://cdn.mysql.com//Downloads/MySQL-5.5/mysql-5.5.46.tar.gz -P ${soft_path}
		[[ -z `id mysql` ]] && useradd -s /sbin/nologin mysql
		tar zxvf ${soft_path}/mysql-5.5.46.tar.gz -C /usr/local/src
		cd ${soft_path}/mysql-5.5.46
		cmake . -DCMAKE_INSTALL_PREFIX=${mysql_path}
		-DMYSQL_DATADIR=${db_path}
		-DDEFAULT_CHARSET=utf8
		-DDEFAULT_COLLATION=utf8_general_ci
		-DEXTRA_CHARSETS=all
		-DENABLED_LOCAL_INFILE=1
		make && make install
		[[ $? -eq 0 ]] && config_mysql && service mysqld start || echo "configure mysql failed"
	
	fi

}
#configure mysql
function config_mysql(){
	cd ${mysql_path}
        chown -R mysql.mysql ${mysql_path}
        chown -R mysql data
        bash scripts/mysql_install_db --user=mysql --basedir=${mysql_path} --datadir=${db_path}
        cp support-files/my-medium.cnf /etc/my.cnf
        cp support-files/mysql.server /etc/init.d/mysqld
        chmod +x /etc/init.d/mysqld
        chkconfig --add mysqld
}
#main
install_mysql
echo "export PATH=$PATH:${mysql_path}/bin" >>/etc/profile
