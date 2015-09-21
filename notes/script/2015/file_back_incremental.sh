#!/bin/bash
#
#
#Incremental backup script
#
#	by wangdd 2015/9/21
#
#
bak_time=`date +%y+%m+%d+%T`
week=`date +%u`
Date=`date +%Y-%m-%d`
year=`date +'%Y'`
month=`date +'%m'`
day=`date +'%d'`
web_path=/data1/wangdong
web="backup diff shell www"
dst_back_path=/data1/back_test
[[ ! -d $dst_back_path ]] && mkdir -p $dst_back_path
for dir in $web
do
	if [ $day -eq 01 ];then
		cd $dst_back_path
		tar -Pczvf $dir.tar.gz.full $web_path/$dir
	else
		cd $dst_back_path
		diff=`date +'%Y-%m-01'`
		Incre=`date -d '-1 day' +'%F'`
		tar -N $diff -Pczvf $dir.tar.gz.$day $web_path/$dir
	fi
done
