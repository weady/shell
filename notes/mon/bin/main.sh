#!/bin/bash
#是否发送邮件的开关
export send=1
#过滤ip地址
export addr=`ifconfig wlp5s0 | grep -A1 'wlp5s0' | awk -F '[: ]+' 'NR==2{print $3}'`
dir=`pwd`
#只需要最后一级目录名
last_dir=${dir##*/}

#下面的判断目的是，保证执行脚本的时候，我们在bin目录里
if [ $last_dir == "bin" ] || [ $last_dir == "bin/" ];then
	conf_file="../conf/mon.conf"
else
	echo "you should cd bin dir"
	exit
fi
exec 1>>../log/mon.log 2>>../log/err.log

echo "`date +"%F %T"` load average"
/bin/bash ../shares/load.sh

#先检查配置文件中是否需要监控502
if grep -q 'to_mon_502' $conf_file;then
	export log=`grep 'logfile=' $conf_file | awk -F '=' 'print $2' | sed 's/ //g'`
	bin/bash ../shares/502.sh
fi
