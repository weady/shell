#!/bin/bash
################################
#
#purpose:  Output java process Jvm and Jstack information
#time: Five minutes once, save That day information
#
################################

if [ -f ~/.bash_profile ]; then
        source ~/.bash_profile
fi

app_pid=`$JAVA_HOME/bin/jps | grep -E 'Bootstrap|Main|*.jar' | grep -v grep | awk '{print $1}'`

output_process_info()
{
        app_id=$1
        for pid in ${app_pid}
        do
                if [ X$pid != "X" ] ; then
                        app_name=`$JAVA_HOME/bin/jps -m | grep -E 'Bootstrap|Main|*.jar' | grep -v grep | grep "${pid}" | awk '{if($2=="Main") print $4;else if ($2=="Bootstrap") print $3;else print $2}'`
                        $JAVA_HOME/bin/jstack  $pid >>/app/apptmp/"${app_name}"_"jstack"_"$pid".`date +"%Y-%m-%d:%H-%M-%S"`.log
                        $JAVA_HOME/bin/jmap -histo $pid >>/app/apptmp/"${app_name}"_"histo"_"$pid".`date +"%Y-%m-%d:%H-%M-%S"`.log
                else
                        continue;
                fi
        done;
}
Delete_expired_logs()
{
        #find /app/apptmp -name "*.hprop" -mtime +1 | xargs rm -rf {} >/dev/null 2>&1
        find /app/apptmp -name "*.log" -mtime 1 | xargs rm -rf {} >/dev/null 2>&1
}
check_process()
{

        Jmap_Count=`ps -fe |grep -E "$JAVA_HOME/bin/jstack | $JAVA_HOME/bin/jmap -histo" | grep -v grep | wc -l`
        if [ ${Jmap_Count} -gt 5 ] ; then 
                ps aux | grep "$JAVA_HOME/bin/jstack" | grep -v grep | awk '{print $2}' | xargs kill -9
                ps aux | grep "$JAVA_HOME/bin/jmap" | grep -v grep | awk '{print $2}' | xargs kill -9

        fi

        JSTACK_COUNT=`ps -ef | grep jstack.sh | grep -v grep | wc -l`
        if [ ${JSTACK_COUNT} -lt 5 ] ; then
                app_pid=`$JAVA_HOME/bin/jps | grep -E 'Bootstrap|Main|*.jar' | grep -v grep | awk '{print $1}'`
                output_process_info $app_pid
        else
                ps aux | grep jstack.sh | grep -v grep | awk '{print $2}' | xargs kill -9
        fi
}

check_process
Delete_expired_logs
