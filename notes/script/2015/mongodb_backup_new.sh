#!/bin/bash
#Description: MongoDB Backup Script
#Write by 200808
#Ver 1.2

#Global setting
DATE=`date +%Y%m%d`
BACKUP_TYPE=mongo
#mongodb backup config file
. /usr/local/mongodb/bin/mongodb_backup.cnf
#Backup log directory
LOGDIR="/var/log"
LOGFILE=${LOGDIR}/mongo_backup.log
#lock file for backup
LOCKFILE="/var/lock/subsys/mongodbackup"
# Exit-Codes:
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
BACKUP_STATUS="/var/log/mongodb_backup_status.sh"
EXPIRED_BACKUP=${BACKUP_DIR}/${BACKUP_TYPE}_$(date +%Y%m%d --date="$LIFECYCLE days ago")
BAKSIZE=0

#Backup result nagios output
result_output()
{
	local NOWDATE
	NOWDATE=`date +%Y%m%d[%k:%M]`
	echo '#!/bin/sh' > ${BACKUP_STATUS}
	echo "echo \"MongoDB backup $1 at $NOWDATE.|Size(MB) of backup data=${BAKSIZE};0;1048576;;\"" >> ${BACKUP_STATUS}
	#echo "echo \"MongoDB backup $1 at $NOWDATE.\"" >> ${BACKUP_STATUS}
	echo "exit $2" >> ${BACKUP_STATUS}
}

#Backup log
logtofile()
{
	echo "$1" >> ${LOGFILE} 2>&1
}

#Backup status output
output_status_data()
{  
    case $1 in
            0)
                result_output "OK" $STATE_OK;
                rm -f ${LOCKFILE};
                exit $STATE_OK
                ;;
            1)
                result_output "Warning. remote backup data failure" $STATE_WARNING;
                rm -f ${LOCKFILE}
                exit $STATE_WARNING
                ;;
            *)
                result_output "error" $STATE_CRITICAL;
                rm -f ${LOCKFILE}
                exit $STATE_CRITICAL
                ;;
    esac
}

#Start backup MongoDB
backup_mongodb() {
	local RETVAL
	logtofile "Start backup MongoDB $1:$2 at `date +%Y%m%d[%T]`"
	$MONGODUMP -h $1:$2 $OPT --out ${BACKUP_DIR}/${DATE}/$1_$2/ >>/dev/null 2>&1
	RETVAL=$?
	if [[ $RETVAL -eq 0 ]]; then
		logtofile "MongoDB $1:$2 backup ok."
		return 0
	else
		logtofile "MongoDB $1:$2 backup exception."
		return 1
	fi
}

#localhost backup data compression
data_compress(){
	local RETVAL
	cd ${BACKUP_DIR}
	if [ -f ./${BACKUP_TYPE}_${DATE}.tgz ];then
		rm -f ./${BACKUP_TYPE}_${DATE}.tgz
	fi
	tar czf ./${BACKUP_TYPE}_${DATE}.tgz ./${DATE} 
	RETVAL=$?
	if [[ $RETVAL -eq 0 ]]; then
		logtofile "MongoDB backup compression is completed."
		rm -rf ./${DATE}
		BAKSIZE=`du -m ./${BACKUP_TYPE}_${DATE}.tgz|cut -f 1`
		return 0
	else 
		logtofile "MongoDB backup compression is failure."
		return 1
	fi
 }
#Delete local expired backup data
del_local_backup()
{
	if [ -f ${EXPIRED_BACKUP}.tgz ];then
		rm -f ${EXPIRED_BACKUP}.tgz
		logtofile "${EXPIRED_BACKUP}.tgz success."
		return 0;
	else
		logtofile "Not found ${EXPIRED_BACKUP}.tgz"
	return 0;
	fi
}

remote_upload()
{
	local RETVAL
	if [[ ! -f ${REMOTE_UPLOAD_SCRIPT} ]]; then
		logtofile "Not found ${REMOTE_UPLOAD_SCRIPT},so upload failure."
		return 1;
	elif [[ ! -f ${PYTHON} ]];then
		logtofile "Not found ${PYTHON},so must install python2.6 for backup."
		return 1;
	else
	
		{
		$PYTHON ${REMOTE_UPLOAD_SCRIPT} -f ${BACKUP_DIR}/${BACKUP_TYPE}_${DATE}.tgz -t ${BACKUP_TYPE}
		if [[ $RETVAL -eq 0 ]]; then
			logtofile "MongoDB remote backup data is OK."
			return 0
		else 
			logtofile "MongoDB remote backup data is failure."
			return 1
		fi
		}
	fi
}

prepare_job()
{
  #Prepare work
  if [ ! -d ${BACKUP_DIR} ]; then
      mkdir -p ${BACKUP_DIR}
  fi
  #Import username and passwd
  if [ -n "$USERNAME" ]; then
    OPT=$"$OPT --username=$USERNAME --password=$PWD"
  fi
  #create nagios monitor file
  if [ ! -f ${BACKUP_STATUS} ];then
    echo "echo \"Status is ok.\"" >> ${BACKUP_STATUS}
    echo "exit 0" >> ${BACKUP_STATUS}
    chmod 755 ${BACKUP_STATUS}
  fi

  if [ ! -f ${MONGODUMP} ]; then
    logtofile "Need mongodump to backup MongoDB."
    output_status_data 2
  fi

  #add nrpe cfg
	if [ `grep "check_mongodb_backup" ${NRPE_CFG} |wc -l` -lt 1 ];then
	{
		echo "command[check_mongodb_backup]=${BACKUP_STATUS}" >> ${NRPE_CFG}
		killall -9 nrpe
		sleep 1
		${NRPE_BIN} -c ${NRPE_CFG} -d
	}
	fi
}

#Running backup mongodb
if [ ! -f ${LOCKFILE} ];then
	touch ${LOCKFILE}
else
	logtofile "MongoDB backup script running."
	exit 1;
fi
prepare_job
mkdir -p ${BACKUP_DIR}/${DATE}

for i in "${DBPORT[@]}"
do
	{
	backup_mongodb $DBHOST $i
	if [[ $? -eq 1 ]]; then
	output_status_data 2
	fi
	}
done

data_compress
RETVAL=$?
if [[ $RETVAL -eq 1 ]]; then
	output_status_data 2
fi

remote_upload
RETVAL=$?
if [[ $RETVAL -eq 1 ]]; then
     output_status_data 1
fi

del_local_backup
output_status_data 0
