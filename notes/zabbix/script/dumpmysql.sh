#!/bin/bash
#
#ex_list="Tables_in_zabbix acknowledges alerts auditlog events history_log history history_str history_text history_uint trends trends_uint"
ex_list="housekeeper httpstepitem httptest httptestitem screens screens_items Tables_in_zabbix acknowledges alerts events history_log history history_str history_text history_uint trends trends_uint"
list=`mysql -uroot -p123456 zabbix -e "show tables;"`
for table in $list
do
        is_ex=0
        for ex_table in $ex_list
        do
                if [ "$table" == "$ex_table" ];then
                        is_ex=1
                        break
                fi
        done
        if [ $is_ex == 0 ] ; then
                mysqldump -uroot -p123456 zabbix $table >>zabbix_init.sql
        fi
done
