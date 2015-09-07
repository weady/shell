#!/bin/bash
export homed_allstaticsrv="db_router db_writer dtvs iacs ias iclnd icore iis ilogclient ilogmaster ilogslave imsgs ipuis ipwed isas itimers itts iuds iusa iusm redis  tsg ulogs"
export homed_alldynasrv="iaps ifts ilogautotask invs ipys iwds"

path01="/homed"
#find_file01=`find $path01 -maxdepth 3 -type f -name config.xml | awk -F'/homed/' '{print $2}' | sort`
dsc_path="/data1/homed_config_backup/`date +%Y-%m-%d`"
if [ ! -d $dsc_path ];then 
	mkdir -p $dsc_path
fi

for srv in $homed_allstaticsrv
do
	cp $path01/$srv/config/config.xml $dsc_path/$srv.config.xml
done

for srv_dy in $homed_alldynasrv
do
	cp $path01/appinstall/$srv_dy/config/config.xml $dsc_path/$srv_dy.config.xml
done
###backup_apache configure file
cp /usr/local/apache/conf/httpd.conf $dsc_path
cp $path01/config_comm.xml $dsc_path
