#!/bin/bash
#
#这个脚本的主要功能是实现对redis服务的启动和关闭控制
#	by wangdd 2015/10/28
#
path="/usr/local/redis"
pidfile=`cat $path/etc/redis.conf | grep "^pidfile"| sed 's/pidfile //g'`
port=`grep "^port" $path/etc/redis.conf | sed 's/port //'`
function start(){
	if [ -e $pidfile ];then
		echo "Redis is running"
	else
		${path}/bin/redis-server $path/etc/redis.conf
		[[ $? -eq 0 ]] && echo "Redis Start Success" || echo "Redis Start Failed"
	fi
}
function stop(){
	if [ ! -e $pidfile ];then
		echo "Redis Stoped"
	else
		echo "shutdown" | $path/bin/redis-cli -p $port
		echo "Redis Stoped"
	fi	
}
function status(){
	[[ -e $pidfile ]] && echo "Redis is running" || echo "Redis is not running"
}
#
case $1 in
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status
		;;
	restart)
		stop
		start
		;;
	*)
		echo "$1 Usage {start|stop|status|restart}"
		exit 1
		;;
esac
