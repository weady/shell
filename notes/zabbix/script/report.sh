#!/bin/bash
#不配置字符集，脚本放到crontab里发出的中文E-MAIL乱码
#export LANG=en_US.UTF-8
 
#
cd /usr/local/zabbix/graph
 
#保存cookie文件名
COOKIE="zbx_cookie.txt"
> $COOKIE
 
#登录zabbxi的用户和密码，最后新建立一个只读用户，改用户去管理需要出报表的主机
NAME="admin"
PASSWD="zabbix"
 
#邮箱地址
EMAIL="wangdd@iPanel.cn"
 
#需要获取数据的主机IP，主要在定义图片名字时使用
IPADDR=(192.168.36.100)
 
#图片graphid的号
CPU_ITEMID=(2614)
 
#zbx地址，根据具体情况而定
URL="http://192.168.36.130/zabbix/index.php"
URL2="http://192.168.36.130/zabbix"
#登录保存cookie
curl -s -c $COOKIE -b $COOKIE  -d "request=&name=${NAME}&password=${PASSWD}&autologin=1&enter=Sign+in" $URL
 
#建立图片存放位置
[[ -d cpu_png ]] || mkdir cpu_png
 
#PERIOD配置获取数据的时间段，用秒数来表示。
#ld需求要7天内的。604800
#这里举个例子我写的3600。
PERIOD=604800
 
#开始时间，也就是当前时间，
STIME=$(date +%Y%m%d%H%M%S)
 
#图片宽度
WHIDTH=1200
 
#通过拼接url获取图片
[[ ! -s "$COOKIE" ]] && exit 0
for i in $(seq 0 $[${#CPU_ITEMID[@]}-1]);do
    curl -s -b $COOKIE \
    -F "graphid=${CPU_ITEMID[i]}" \
    -F "period=$PERIOD" \
    -F "curtime=$STIME" \
    -F "width=$WHIDTH" \
    "$URL2/chart2.php" > cpu_png/${i}.png
done
#图片
CPU_PNG="-a cpu_png/*.png"
 
#邮件主题
CPU_TITLE="$(date +%Y年%m月%d日) Cpu idle 曲线图"
 
# 
echo "附件为抽查服务器cpu idle曲线图" | /bin/mailx -s "$CPU_TITLE" $CPU_PNG $EMAIL
 
#
[[ -d cpu_png ]] && rm -rf cpu_png
exit 0
