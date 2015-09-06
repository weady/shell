#!/bin/bash

ips="192.168.35.102 192.168.35.104 192.168.35.99 192.168.101.131 192.168.36.99"
path=`pwd`

for IP in $ips; do

#	path="/r2/mysqldata"

	if [ -f $path/showslavestatus.txt ]; then
		rm -f $path/showslavestatus.txt
	fi
	
	echo "show slave status\G;" > $path/showslavestatus.txt
	
	cmd=`mysql -h $IP -u root -p123456 < $path/showslavestatus.txt`
	cmdresult=`echo $cmd`
	#echo "$cmdresult"
	
	lastioerr=""
	lastsqlerr=""
	iostatus=""
	sqlstatus=""
	
	usedlog=${cmdresult##*Slave_IO_Running: }
	#echo "usedlog: $usedlog"
	iostatus=${usedlog%% *}
	usedlog=${usedlog##*Slave_SQL_Running: }
	#echo "usedlog: $usedlog"
	sqlstatus=${usedlog%% *}
	usedlog=${usedlog##*Last_IO_Error: }
	#echo "usedlog: $usedlog"
	lastioerr=${usedlog%%Last_SQL_Errno*}
	usedlog=${usedlog##*Last_SQL_Error: }
	lastsqlerr=${usedlog%%Replicate_Ignore_Server_Ids:*}
	
	echo "$IP:"
	#echo "iostatus:<B><font color=red> $iostatus</font>"
	#echo "sqlstatus: <B><font color=red> $sqlstatus</font>"
	#[[ "No" == $iostatus ]] && echo "iostatus:<B><font color=red> $iostatus</font>"
	#[[ "Yes" == $iostatus ]] && echo "iostatus:  <B><font color=green> $iostatus</font>"
	#[[ "No" == $sqlstatus ]] && echo "sqlstatus: <B><font color=red> $sqlstatus</font>"
	#[[ "Yes" == $sqlstatus ]] && echo "sqlstatus: <B><font color=green>  $sqlstatus</font>"
	
	if [ "No" = $iostatus ]; then
		echo "iostatus:<B><font color=red> $iostatus</font></B>"
		wget -q --tries=2 --timeout=5 "http://192.168.35.122:12690/sms/sms_send?recvmode=0&receiver=13570898131&msg=$IP-IOERROR:$lastioerr&st=1&smsauth=aaa:abc12345" -O reslave
		rm -f reslave
		echo "$lastioerr"
	else
		echo "iostatus:<B><font color=green> $iostatus</font></B>"
	fi
	
	if [ "No" = $sqlstatus ]; then
		echo "sqlstatus:<B><font color=red> $sqlstatus </font></B>"
		wget -q --tries=2 --timeout=5 "http://192.168.35.122:12690/sms/sms_send?recvmode=0&receiver=13570898131&msg=$IP-SQLERROR:$lastsqlerr&st=1&smsauth=aaa:abc12345" -O reslave
	        rm -f reslave
		echo "$lastsqlerr"
	else
		echo "sqlstatus:<B><font color=green> $sqlstatus</font></B>"
	fi
	
	echo ""
done;
