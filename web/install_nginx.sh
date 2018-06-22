#!/bin/bash
#
#
#	by wangdd 2016/12/26
#
# The scripts used to install nginx
#
#

#源码编译安装nginx
soft_path="/usr/local/src"

function install_nginx(){
	#安装基本的编译环境  一般需要 pcre----rewrite 正则需要,zlib --压缩所用,如果yum 安装失败就单独下载pcre 和zlib 
	yum install -y gcc gcc-c++  autoconf libtool automake make zlib zlib-devel  openssl  openssl-devel  pcre-devel pcre >/dev/null
	#wget -q  http://nginx.org/download/nginx-1.10.2.tar.gz -P $soft_path 
	tar zxvf ${soft_path}/nginx-1.10.2.tar.gz -C $soft_path >/dev/null
	cd ${soft_path}/nginx-1.10.2 
	./configure \
	--prefix=/usr/local/nginx \
	--with-http_flv_module \
	--with-http_stub_status_module \
	--with-http_gzip_static_module \
	#--with-pcre \ 
	#--with-pcre=/usr/local/pcre \ //指定pcre的源码目录而不是安装目录
	make && make install
}

#nginx的启动脚本

function start_nginx(){

#!/bin/bash 
# nginx Startup script for the Nginx HTTP Server 
# chkconfig: - 85 15 
# description: Nginx is a high-performance web and proxy server. 
# processname: nginx 
nginxd=/usr/local/nginx/sbin/nginx
nginx_config=/usr/local/nginx/conf/nginx.conf
nginx_pid=/usr/local/nginx/logs/nginx.pid
RETVAL=0 
prog="nginx"
# Source function library. 
. /etc/rc.d/init.d/functions 
# Source networking configuration. 
. /etc/sysconfig/network
# Check that networking is up. 
[ ${NETWORKING} = "no" ] && exit 0
[ -x $nginxd ] || exit 0
# Start nginx daemons functions. 
start() {
if [ -e $nginx_pid ];then
echo "nginx already running...." 
exit 1
fi
echo -n $"Starting $prog: " 
daemon $nginxd -c ${nginx_config}
RETVAL=$?
echo 
[ $RETVAL = 0 ] && touch $nginx_pid
return $RETVAL

}
# Stop nginx daemons functions. 
stop() {
echo -n $"Stopping $prog: "
killproc $nginxd
RETVAL=$?
echo 
[ $RETVAL = 0 ] && rm -f $nginx_pid
}
# reload nginx service functions. 
reload() {
echo -n $"Reloading $prog: " 
#kill -HUP `cat ${nginx_pid}` 
killproc $nginxd -HUP
RETVAL=$?
echo 
}
# See how we were called. 
case "$1" in
start)
start
;;
stop)
stop
;;
reload)
reload
;;
restart)
stop
start
;;
status)
status $prog
RETVAL=$?
;;
*)
echo $"Usage: $prog {start|stop|restart|reload|status|help}" 
exit 1
esac
exit $RETVAL

}
