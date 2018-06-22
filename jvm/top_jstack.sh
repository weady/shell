#!/bin/bash
#/usr/bin/top -b -n 1 |head -n 17 >> /tmp/cputop10.log
echo "CPU资源消耗TOP-10信息"
#/usr/bin/top -b -n 1 |head -n 17
/usr/bin/top -c -b -n 1 |sed -n "7,17p" >/tmp/1.txt
cat "/tmp/1.txt"
echo "--------------------------------------------------------------------------------------"
#echo "MEM资源消耗TOP-10信息"
#echo "USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND"
#/bin/ps aux  | /bin/grep -v PID | /bin/sort -k+4 -rn | /usr/bin/head
while true; do
    echo
    read -p "请输入需要jstack的进程PID: " tag
    echo
    /app/jdk1.8.0_25/bin/jstack -l $tag >/tmp/$tag"_"jstack.txt
    echo "jstack信息成功保存   /tmp/$tag"_"jstack.txt   中!!"
    echo 
    echo "Thread线程TOP10情况"
    /usr/bin/top -Hp $tag -b -n 1|sed -n "7,17p" >/tmp/$tag"_"thread.txt
    echo "Thread信息成功保存  /tmp/$tag"_"thread.txt   中!!"
    echo 
    echo "jstat详细信息:"
    /app/jdk1.8.0_25/bin/jstat -gc $tag 250 4 >/tmp/$tag"_"jstat.txt
    echo "jstat信息成功保存  /tmp/$tag"_"jstat.txt   中!!"
    exit 0
done
