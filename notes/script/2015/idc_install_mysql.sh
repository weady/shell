#!/bin/bash
#config_mysql
mysql_data="/r2/mysqldata"
des_soft="/usr/local/test"
soft_file="/usr/local/src/soft"

yum remove mysql*
rpm -e mysql-* --nodeps
if[ -d $mysql_data ]
then
	rm -rf /r2/mysqldata/*
else
	mkdir -p /r2/mysqldata
fi

cd $des_soft/mysql5.5.33
rpm -ivh *.rpm --force
if [ $? = "0" ]
then
	cd /usr/bin
	./mysql_install_db --user=mysql --datadir=/r2/mysqldata
	cp $soft_file/my.cnf /etc/my.cnf
	setenforce=0
	chkconfig --add mysqld
	service mysqld start
	mysql -uroot -e "SET PASSWORD = PASSWORD('123456')"
else
	echo "Install Mysql Failed"
fi
