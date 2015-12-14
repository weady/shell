#!/bin/bash
#
#
#
path="/usr/local/zabbix/scripts"
db_zabbix="/var/lib/mysql/zabbix"
log_file="$path/zabbix_db_size.log"
[[ ! -f $log_file ]] && touch $log_file
size=`du -sh $db_zabbix |awk '{print $1}'`
d=`date +%F-%T`
cat >>$log_file <<EOF
$d	$size
EOF
