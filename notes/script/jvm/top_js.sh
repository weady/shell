#!/bin/bash
# @Function
# Find out the highest cpu consumed threads of java, and print the stack of these threads.
#


if [ -f ~/.bash_profile ]; then
    source ~/.bash_profile
    source /etc/profile
fi

if [ -d /app/jdk1.8.0_65 ]; then
    export JAVA_HOME="/app/jdk1.8.0_65"
else
    export JAVA_HOME="/app/jdk1.8.0_25"
fi

function get_cpu_10()
{
    text='/tmp/top_cpu_10.txt'
    # echo "CPU资源消耗TOP-10信息"
    ps aux|grep -v PID|grep -v grep|grep java|grep -v cmdline-jmxclient-0.10.3.jar|sort -rn -k +3|head > $text
    echo "CPU资源消耗TOP-10 Java进程信息,已保存在 $text"
    #cat $text
    #获取top_cpu_5进程pid号
    echo "CPU资源消耗TOP-10 PID信息列表"
    top_pids=`cat $text|grep -v flume|awk '{print $2}'`
    echo $top_pids
    for pid in $top_pids; do
        #Instance_Name=`ps -ef |grep $pid|grep -v 'grep'|grep -v 'vim'|grep -v 'less'|grep -v 'more'|grep -v 'cat'|grep -v '\-Hp'|awk '{print $(NF-2)}'`
        #Instance_Name=`ps -ef |grep $pid|grep -v 'grep'|grep -v '\-Hp'|grep -Ewv 'vim|less|more|cat'|awk '{print $(NF-2)}'`
        Instance_Name=`ps -ef |grep $pid|grep -Ev 'grep|\-Hp|\-H \-p|top \-p'|grep -Ewv 'vim|less|more|cat'|awk '{print $(NF-2)}'`

        # jstack日志文件目录创建
        [ -d /app/tmp/jvm/$day_dir_name/$hour_dir_name ] || mkdir -p /app/tmp/jvm/$day_dir_name/$hour_dir_name

        echo -e "\033[42;30m $do_time 实例名称: $Instance_Name 实例PID号: $pid jstack详细信息 \033[0m"
        echo -e "\033[42;30m $do_time 实例名称: $Instance_Name 实例PID号: $pid threads详细信息 \033[0m"
        echo -e "\033[42;30m $do_time 实例名称: $Instance_Name 实例PID号: $pid jstat详细信息 \033[0m"
        echo -e "\033[42;30m $do_time 实例名称: $Instance_Name 实例PID号: $pid jmap详细信息 \033[0m"
        echo "$do_time 实例名称: $Instance_Name 实例PID号: $pid jstack详细信息" >> /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jstack.txt
        echo "$do_time 实例名称: $Instance_Name 实例PID号: $pid top10线程资源消耗情况" >> /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"threads.txt
        echo "$do_time 实例名称: $Instance_Name 实例PID号: $pid jstat详细信息" >> /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jstat.txt
        echo "$do_time 实例名称: $Instance_Name 实例PID号: $pid jmap详细信息" >> /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jmap.txt

        #获取当前进程jstack信息
        $JAVA_HOME/bin/jstack  $pid >>/app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jstack.txt
        echo "jstack信息成功保存 /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jstack.txt 中！！！"

        #获取当前进程top10线程资源消耗情况
        /usr/bin/top -Hp $pid -b -n 1|sed -n "7,17p" >>/app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"threads.txt
        echo "Thread信息成功保存 /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"threads.txt 中！！！"

        #获取当前进程jstat详细信息
        $JAVA_HOME/bin/jstat -gc $pid 250 4 >>/app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jstat.txt
        echo "jstat信息成功保存 /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jstat.txt 中！！！"

        #获取当前进程jmap详细信息
        #$JAVA_HOME/bin/jmap -histo $pid >>/app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jmap.txt
        #echo "jmap信息成功保存 /app/tmp/jvm/$day_dir_name/$hour_dir_name/$Instance_Name"_"$runtime"_"jmap.txt 中！！！"
    done
}

function get_mem_10()
{
    echo "MEM资源消耗TOP-10信息"
    echo "USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND" >/app/tmp/top_mem_10.txt
    /bin/ps aux  | /bin/grep -v PID | /bin/sort -k+4 -rn | /usr/bin/head >>/app/tmp/top_mem_10.txt
    echo "MEM资源消耗TOP-10信息,已保存在 /app/tmp/top_mem_10.txt"
    #cat '/tmp/top_mem_10.txt'
}

function check_process()
{

        Jmap_Count=`ps -ef |grep -E "$JAVA_HOME/bin/jstack | $JAVA_HOME/bin/jmap -histo | $JAVA_HOME/bin/jmap" | grep -v grep | wc -l`
        echo "采集jvm信息，超时时间进程的数量为--${Jmap_Count}"
        if [ ${Jmap_Count} -gt 5 ] ; then 
                ps aux | grep "$JAVA_HOME/bin/jstack" | grep -v grep | awk '{print $2}' | xargs kill -9
                ps aux | grep "$JAVA_HOME/bin/jstat" | grep -v grep | awk '{print $2}' | xargs kill -9
                ps aux | grep "$JAVA_HOME/bin/jmap" | grep -v grep | awk '{print $2}' | xargs kill -9
        fi
}

function MAIN()
{
    day_dir_name=`date "+%Y%m%d"`

    hour_dir_name=`date "+%Y%m%d%H"`

    do_time=`date "+%Y-%m-%d %H:%M:%S"`

    runtime=`date "+%Y_%m_%d_%H:%M:%S"`

    # 脚本启动时间
    start_time=`date +%s`

    # 获取top_cpu_10进程
    get_cpu_10

    # 防止进程卡死
    check_process

    yesterday=`date -d "2 day ago" +"%Y%m%d"`
    #清理前两天日志
    [ "ls -A $yesterday" ] && rm -rf /app/tmp/jvm/$yesterday
    # 获取get_mem_10进程
    #get_mem_10
}
MAIN
