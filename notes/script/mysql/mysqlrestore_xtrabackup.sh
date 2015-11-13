#!/bin/bash
set -e

mysql_dir='/data/mysql'                 #mysql的数据目录
mysql_bak_dir='/data/back_history'      #mysql的备份目录
log='/tmp/history.txt'                  #自动备份时产生的日志记录

cd $mysql_bak_dir
service mysqld stop
for i in `ls $mysql_bak_dir`;do
    tar zxf $i
done

arr=(`cat $log`)
arrs=${#arr[@]}
for ((i=0; i<$arrs; i++));do
    if [ $i -eq 0 ] ;then
        innobackupex --apply-log --redo-only $mysql_bak_dir/${arr[i]}
    else
        innobackupex --apply-log --redo-only $mysql_bak_dir/${arr[0]} --incremental-dir=$mysql_bak_dir/${arr[i]}
    fi
done

rm -rf $mysql_dir/*

innobackupex --copy-back $mysql_bak_dir/${arr[0]}
chown -R mysql:mysql $mysql_dir/*
service mysqld start