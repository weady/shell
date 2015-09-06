#########################################################################

#by wangdd 2015/6/25 

#########################################################################
#!/bin/bash
path="/homed"
#find_start_process=`grep '^#[a-z]*[a-z]$' $path/start.sh  | awk -F'#' '{print $2}'`
find_start_process=`grep "^_.*" $path/start.sh | awk -F" " '{print $5}' | awk -F"['.]" '{print $2}' | sed '/^$/d' | sort -u`
for process in $find_start_process
do
        command01=`ps -ef | grep "$process|*.exe" | awk -F' ' '{print $8}' | awk -F'/' '{print $2}'`
	command02=`netstat -unltp | grep -E "LI.*$process" | head -n 1`
        if [ ! -z "$command01" ] && [ ! -z "command02" ];then
                echo $command02 is running
        else
                echo $process is not running,Please Check!
        fi
done
