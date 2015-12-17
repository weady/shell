#!/bin/bash
#
#
user="zabbix"
pass="zabbixpass"
db="zabbix"
host="127.0.0.1"
dt=`date +%s -d "30 days ago" `
mysql -B -u$user -h$host -p$pass zabbix -e "CALL create_zabbix_partitions();"

