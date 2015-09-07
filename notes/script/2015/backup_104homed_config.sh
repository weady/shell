#!/bin/bash
path01="/r2/homed"
#find_file=`find $path01 -maxdepth 3 -tyep f | grep config.xml`
#find /r2/homed -maxdepth 3 -type f | grep  config.xml
#find_file=`find $path01 -maxdepth 3 -type f -name config.xml | awk -F'/homed/' '{print $2}' | awk -F'/' -v 'OFS=_' '{print $1,$3}'`
find_file=`find $path01 -maxdepth 3 -type f -name config.xml | awk -F'/homed/' '{print $2}' | sort`
#file01=`find /r2/homed -maxdepth 3 -type f -name config.xml | awk -F'/homed/' '{print $2}' | awk -F'/' '{print $1}' | sort`
dsc_path="/data2/homed_back"
if [ ! -d $dsc_path ];then 
	mkdir -p $dsc_path
	for file in $find_file
	do 
		cp $file $dsc_path/${file:0:3}_config.xml
	done
else
	
	for file in $find_file
	do 
		cp $file $dsc_path/${file:0:3}_config.xml
	done
fi
###backup_databaase
mysqldump -uroot -p123456 --all-database > $dsc_path/104_alldb.sql >/dev/null

###backup_apache configure file
cp /usr/local/apache/conf/httpd.conf $dsc_path
cp $path01/config_comm.xml $dsc_path
