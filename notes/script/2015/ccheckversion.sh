#!/bin/bash
#
#
#This script used to check whether HOMED's *.exe run.sh homed_base/bin update sucess!!
#
#	by wangdd 2015/8/21
#
#
#

LOCK_NAME="/tmp/my.lock"
if ( set -o noclobber; echo "$$" > "$LOCK_NAME") 2> /dev/null; 
then
trap 'rm -f "$LOCK_NAME"; exit $?' INT TERM EXIT
ver_check_log=""
ver_check_log="/var/log/version_check.log"
[[ -e $ver_check_log ]] && rm -rf $ver_check_log

mode=$1    # start or stop

[ $# -ge 1 ] && shift

case $mode in
	'config')
		source ./check_config.sh
		echo "*****************"
        	echo -e "\033[40;31;5m ERROR $E_num_config \033[0m"
       		echo "*****************"
        	if [ "$E_num_config" -gt 0 ];then
                	echo "ERROR_LIST:"
               		echo "$E_LIST_config"
                	echo ""
		fi
		echo -e  "\033[4m The Report Located In $ver_check_log \033[0m"
		;;

	'run')
		source ./check_run.sh
                echo "*****************"
                echo -e "\033[40;31;5m ERROR $E_num_run \033[0m"
                echo "*****************"
                if [ "$E_num_run" -gt 0 ];then
                	echo "ERROR_LIST:"
               		echo "$E_LIST_run"
               		echo ""
		fi
		echo -e  "\033[4m The Report Located In $ver_check_log \033[0m"
		;;
	'exe')
		source ./check_exe.sh
                echo "*****************"
                echo -e "\033[40;31;5m ERROR $E_num_exe \033[0m"
                echo "*****************"
                if [ "$E_num_exe" -gt 0 ];then
                	echo "ERROR_LIST:"
                	echo "$E_LIST_exe"
                	echo ""
		fi
		echo -e  "\033[4m The Report Located In $ver_check_log \033[0m"
		;;
	'base')
		source ./check_base.sh
                echo "*****************"
                echo -e "\033[40;31;5m ERROR $E_num_base \033[0m"
                echo "*****************"
                if [ "$E_num_base" -gt 0 ];then
                	echo "ERROR_LIST:"
                	echo "$E_LIST_base"
                	echo ""
		fi
		echo -e  "\033[4m The Report Located In $ver_check_log \033[0m"
		;;
	'all')
		source ./check_run.sh
		source ./check_exe.sh
		source ./check_base.sh
		source ./check_config.sh
		E_num=`cat $ver_check_log | egrep "ERROR" | wc -l`
		E_list=`cat $ver_check_log | egrep "ERROR"`
		if [ "$E_num" -gt 0 ];then
			echo "-------------" |tee -a $ver_check_log
			echo -e "\033[40;31;5m ERROR $E_num \033[0m" | tee -a $ver_check_log
			echo "-------------" | tee -a $ver_check_log
			echo -e "\033[40;31m ERROR LIST: \033[0m" | tee -a $ver_check_log
			echo "$E_list"
			echo -e  "\033[4m The Report Located In $ver_check_log \033[0m"
		else
			echo "Congratulation!NO ERROR!!"
		fi
		;;
	*)
		basename=`basename "$0"`
		echo "Usage: $basename  {config|run|exe|base|all} "
      		exit 1
		;;
esac

### Removing lock
rm -f $LOCK_NAME
trap - INT TERM EXIT
else
echo "The Script is running" 
exit 1
fi
