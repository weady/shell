#!/bin/bash
#
#This script used to optimize zabbix's database
#
#
function optimize_mysql(){
#数据库分区,分区的sql语句在/usr/local/zabbix/scripts/zabbix.partition.sql
#day--->NOWDAY;nday--->NEXTDAY;ndayt--->NEXTDAYT
#mon--->NOWMON;nmon--->NEXTMON;nmont--->NEXTMONT
#
#

#当前月NOWMON----mon
#下个月NEXTMON---nmon
#下个月-:ZZZM----za
#下下个月-:BBZZ---zb
#当前日NOWDAY----day
#下一天NEXTDAY---nday
#下一天-:ZBBD---zc
#下下一天-:TZZ---zd

day=`date +%Y%m%d`
nday=`date +%Y%m%d -d '+1 days'`
zc=`date +%Y-%m-%d -d '+1 days'`
zd=`date +%Y-%m-%d -d '+2 days'`
mon=`date +%Y%m`
nmon=`date +%Y%m -d '+1 month'`
za=`date +%Y-%m -d '+1 month'`
zb=`date +%Y-%m -d '+2 month'`
tmon=`date +%Y%m -d '+2 month'`
sed -i "s/NOWDAY/$day/g;s/NEXTDAY/$nday/g;s/ZBBD/$zc/g;s/TZZ/$zd/g" /usr/local/zabbix/scripts/zabbix.partition.sql
sed -i "s/NOWMON/$mon/g;s/NEXTMON/$nmon/g;s/ZZZM/$za/g;s/BBZZ/$zb/g" /usr/local/zabbix/scripts/zabbix.partition.sql
mysql -uzabbix -pzabbixpass zabbix </usr/local/zabbix/scripts/zabbix.partition.sql
mysql -uzabbix -pzabbixpass zabbix </usr/local/zabbix/scripts/zabbix.auto.partition.sql
echo "1 0 * * * /usr/local/zabbix/scripts/auto.partition.sh >/dev/null" >> /var/spool/cron/root
}
optimize_mysql
rm -f $0
