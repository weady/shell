#!/bin/bash



echo "$0 running begin..."

########################################################
 #check once every 5 minutes
 if [[ 0 == 1 ]]
 then
 time=`date '+%M'`
 echo "time=$time"
 time=$((time%5))
 if [[ $time != 0 ]]
 then
 	echo "$0 not need real check, exit."
	 exit 0
 fi
 fi
########################################################


##########################################################################
#basic params
#the m_base_param.sh must be first load
this_shell_path0=`dirname $0`
. $this_shell_path0/../base/m_base_param.sh
#the m_base_begin.sh must be second load
. $base_path/m_base_begin.sh
##########################################################################

#my root my_root_path
my_root_path=$maintain_path/checkdiskmount

#main process
function main_fun()
{
	conf_path=$my_root_path/disk_config.txt

	f_log "conf_path=$conf_path"
	. $my_root_path/m_build_raid.sh
	f_log "end $my_root_path/m_build_raid.sh"
	
	
	
	#if the disk config is exits ??
	if [ -s $conf_path ]
	then			
		.	$my_root_path/m_reallycheck.sh 
	else
		.	$my_root_path/m_builddisk.sh
		.	$my_root_path/m_reallycheck.sh 
	fi

}


main_fun;

echo "$0 running end"
