#!/bin/bash
#
#This script used to extension ssl mode of apache
#
#	by wangdd 2015/11/4
path="/usr/local/apache"
soft="/usr/local/src"
ssl_mod=`find $path/modules -type f -name "mod_ssl.so"`
ver=`$path/bin/httpd -v | awk -F '[/ ]' 'NR==1 {print $4}'` 
pro_nu=`ps -ef | grep httpd | grep -v grep | wc -l`
client="$1"
#
function modify_config(){
	cd $soft
	mv $path/conf/extra/httpd-ssl.conf $path/conf/extra/httpd-ssl.conf.default
	\cp server.crt server.key $path/conf
	\cp httpd-ssl.conf $path/conf/extra
	sed -i "s/192.168.36.120/$client/g" $path/conf/extra/httpd-ssl.conf
	sed -i 's$#Include conf/extra/httpd-ssl.conf$Include conf/extra/httpd-ssl.conf$' $path/conf/httpd.conf 
	rm -rf httpd-2.2.22* httpd-ssl.conf server.crt server.key ex_ap_ssl.sh 
}
function restart_apache(){
	source /etc/profile
	$path/apache_stop.sh
	sleep 1
	$path/apache_run.sh
}
[[ "$pro_nu" -lt 1 || ! -d "$path" ]] && echo "apache not installed" && exit
[[ ! -d "$path/ssltest" ]] && mkdir -p $path/ssltest && echo "Welcome `hostname` throuth https" >$path/ssltest/index.html
[[ ! -z "${ssl_mod}" ]] && echo "mod_ssl.so exsit" && exit
if [ "$ver" == "2.2.22" ];then
	cd $soft
	tar zxvf httpd-2.2.22.tar.gz >/dev/null
	cd httpd-2.2.22/modules/ssl
	/usr/local/apache/bin/apxs -a -i -c -D HAVE_OPENSSL=1 -lcrypto -lssl -ldl *.c
	if [ $? -eq 0 ];then
		modify_config
		[[ $? -eq 0 ]] && echo "mod_ssl extension success" && restart_apache
	else
		echo "mod_ssl extension Failed"
		exit
	fi
else
	echo "apache version is $ver"
fi

