#!/bin/bash
#
if [ ! -d /backup ] && [ ! -L /backup ];then
    if [ ! -d /data/backup ];then
        mkdir -p /data/backup
    fi
    ln -s /data/backup /backup
fi
BAKTYPE=mysql
LOCALBAKDIR=/backup/${BAKTYPE}
DATE=`date +%Y%m%d`
LOGDIR=/var/log/mysql
BACKUP_STATUS_LOG=${LOGDIR}/mysqlbackup_status.log
RUN_LOG=${LOGDIR}/run_status_${DATE}.log

MONITOR_LOG=/tmp/monitorbackup/
MONITOR_LOG_FILE=${MONITOR_LOG}file_monitor.log

PUBLIC_IP=`ifconfig |grep "inet addr"|grep -v "inet addr:127\.0\.0\.1"|grep -v "inet addr:10\."|head -1|awk '{print $2}' |sed "s/addr://g"`
INNER_IP=`ifconfig |grep "inet addr:10\."|awk '{print $2}'|sed "s/addr://g"`
FTP_USER="web_webbak"
FTP_PASS="kiazp1.caa12Af"
DEFINE_DATADIR_SIZE="40960"
DEFINE_RETAIN_SIZE="200"
DBUSER="mysqlbackup"
DBPASS="r3bYH3vdr753hd78rjwe"
YESTERDAY=`date -d "-1 days" +'%Y%m%d'`
TMP_wait_timeout=28800
BIN_LOG_RETAIN_NUM=20

pyupload_script="python /root/ndserver/data_backup_system/client/main.py"
################################################
## beflow info should be provided for uploadfile program
apptype=mysql

# write a function to get time dynamicly
function get_datetime()
{
   dt=`date +%Y%m%d%H%M`
   echo $dt
}
#Section 1: define common variables
LAST_BACKUP_TIME=$(get_datetime)

# invoke python client program to up file backed to ftp server (net disk)
function upload_file()
{
   absfilename=$1
   apptype=$2
   $pyupload_script -f $absfilename -t $apptype
}
################################################
function PrintHelp() {
        echo Help:;
        echo "./mysql_backup.sh (ON3306) (ON3308)";
        echo "if the master Instance has slave mysqlserver,and you also want to backup the master Instance;please set \$1 = "ON3306",OR don't set \$1"
}
function checkDirExists()
{
if [ ! -d $1 ];then
   mkdir -p $1;
fi
}
function checkFileExists()
{
if [  -e $1 ];then
   LogToFile "$1  is Exist"
else 
   LogToFile "$1 is not Exist"
   return 1;
fi
}
function LogToFile()
{
   echo "$1 at `date +%Y-%m-%d[%T]` " >> ${RUN_LOG}
}
function LogToFile1()
{
   echo "$1 at `date +%Y-%m-%d[%T]` " >> ${BACKUP_STATUS_LOG}
}
function log_errorrecord()
{
   echo $1 >> ${MONITOR_LOG_FILE}
   return 0
}
function checkDownLoad()
{
if [ $? -eq 0 ];then
   LogToFile "download $1 is OK" 
else
   LogToFile "download $1 is ERROR;WARNING!!" 
return 8;
fi
}
function Install_innodb_tool()
{
if [ $(/bin/uname -m) = 'i686' ];then
   cd /usr/local/src;wget -S "http://nagios.99.com/ndtool/mysqlbackup/percona-xtrabackup-2.0.2_2012-12-10_x86.tar.gz"
   checkDownLoad percona-xtrabackup-2.0.2_2012-12-10_x86.tar.gz
   tar -zxf percona-xtrabackup-2.0.2_2012-12-10_x86.tar.gz
   cd percona-xtrabackup-2.0.2;/bin/cp -a bin/* /usr/bin/;
else [ $(/bin/uname -m) = 'X86_64' ]
   cd /usr/local/src;wget -S "http://nagios.99.com/ndtool/mysqlbackup/percona-xtrabackup-2.0.2_2012-12-10_x86_64.tar.gz"
   checkDownLoad percona-xtrabackup-2.0.2_2012-12-10_x86_64.tar.gz
   tar -zxf percona-xtrabackup-2.0.2_2012-12-10_x86_64.tar.gz
   cd percona-xtrabackup-2.0.2;/bin/cp -a bin/* /usr/bin/;
fi
}
# install dos2unix tool
function check_dos_tool()
{
if [ ! -f /usr/bin/dos2unix ];then
   yum -y install dos2unix;
fi
}
check_dos_tool

function GetBaseMess()
{
mysql_progress=$1
# GET DATA_DIR
for i in $mysql_progress;
do
  if [ -n "`echo $i|awk -F= '($1~ "datadir"){print $2}'`" ];then
     DATA_DIR=`echo $i|awk -F= '($1~ "datadir"){print $2}'`
     break;
   fi
done

#GET BASE_DIR
for i in $mysql_progress;
do
if [ -n "`echo $i|awk -F= '($1~ "basedir"){print $2}'`" ];then
   BASE_DIR=`echo $i|awk -F= '($1~ "basedir"){print $2}'`
   break;
fi
done

#GET CONFIG_FILE
for i in $mysql_progress;
do
if [ -n "`echo $i|awk -F= '($2~ "my.cnf"){print $2}'`" ];then
   CONFIG_FILE=`echo $i|awk -F= '($2~ "my.cnf"){print $2}'`
   break;
elif [ -n ${DATA_DIR} ] && [ -f ${DATA_DIR}/my.cnf ];then
   CONFIG_FILE=${DATA_DIR}/my.cnf
elif [ -n ${DATA_DIR} ] && [ -f /etc/my.cnf ];then
   CONFIG_FILE=/etc/my.cnf
elif [ -n ${DATA_DIR} ] && [ -f ${BASE_DIR}/my.cnf ];then
   CONFIG_FILE=${BASE_DIR}/my.cnf
elif [ -z ${DATA_DIR} ] && [ -f /etc/my.cnf ];then
   CONFIG_FILE=/etc/my.cnf
   DATA_DIR=`grep -A30 mysqld ${CONFIG_FILE}|grep "datadir"|awk -F "[ =]" '{print $NF}'`
elif [ -z ${DATA_DIR} ] && [ -f ${BASE_DIR}/my.cnf ];then
   CONFIG_FILE=${BASE_DIR}/my.cnf
   DATA_DIR=`grep -A30 mysqld ${CONFIG_FILE}|grep "datadir"|awk -F "[ =]" '{print $NF}'`
else [ -z ${DATA_DIR} ] && [ ! -f /etc/my.cnf ]  && [ ! -f ${BASE_DIR}/my.cnf ]
   LogToFile1 "There is can't get CONFIG_FILE and DATA_DIR.CRITICAL!!"
   LogToFile "There is can't get CONFIG_FILE and DATA_DIR.CRITICAL!!"
   log_errorrecord "There is can't get CONFIG_FILE and DATA_DIR.CRITICAL!!"
   exit
fi
done

#GET SOCKET_FILE
for i in $mysql_progress;
do
if [ -n "`echo $i|awk -F= '($1~ "socket"){print $2}'`" ];then
   SOCKET_FILE=`echo $i|awk -F= '($1~ "socket"){print $2}'`
   break;
else
   SOCKET_FILE=`grep -A20 mysqld ${CONFIG_FILE}|grep "socket"|awk -F "[ =]" '{print $NF}'`
fi
done

#GET Instance_port
for i in $mysql_progress;
do
if [ -n "`echo $i|awk -F= '($1~ "port"){print $2}'`" ];then
Instance_port=`echo $i|awk -F= '($1~ "port"){print $2}'`
break;
else
Instance_port=`grep -A30 mysqld ${CONFIG_FILE}|grep "port"|awk -F "[ =]" '{print $NF}'`
fi
done

#GET master_info_dir=
if [ `grep "^master-info" ${CONFIG_FILE}|wc -l ` -ge 1 ];then
master_info_dir=`grep "^master-info" ${CONFIG_FILE}|head -1|cut -d "=" -s -f2|sed 's/^ //g'|awk -F "/" 'BEGIN{ORS=""} {i=1;while(i<NF) {print $i"/";i++}; print "\n"}'`
else
master_info_dir=${DATA_DIR}
fi

if [ `grep "^log-bin" ${CONFIG_FILE}|wc -l ` -ge 1 ];then
log_bin_dir=`grep "^log-bin" ${CONFIG_FILE}|head -1|cut -d "=" -s -f2|sed 's/^ //g'|awk -F "/" 'BEGIN{ORS=""} {i=1;while(i<NF) {print $i"/";i++}; print "\n"}'`
BIN_LOG_PATTERN=`grep "^log-bin" ${CONFIG_FILE}|head -1|awk -F "/" 'BEGIN{ORS=""} {print $NF}'`
fi

MYSQL_CMD="${BASE_DIR}/bin/mysql  -S ${SOCKET_FILE} -u ${DBUSER} -p${DBPASS} -e"
OLD_wait_timeout=`${MYSQL_CMD} "show variables like 'wait_timeout';"|awk '(NR>1)'|cut -s -f2`
LOCK_FILE=${LOGDIR}/${Instance_port}.lock
LogToFile "$CONFIG_FILE $SOCKET_FILE $DATA_DIR $Instance_port $BASE_DIR $master_info_dir $log_bin_dir $BIN_LOG_PATTERN ${MYSQL_CMD} $OLD_wait_timeout $LOCK_FILE "
}
function check_alive()
{
checkFileExists $SOCKET_FILE
if [ $? -eq 0 ];then
   LogToFile "this Instance ${Instance_port} is alive,then will decide BACKUP or NOT. "
   return 0;
else
   return 1;
fi
}

function check_master_slave()
{
if [ -f ${master_info_dir}/master.info ];then
   LogToFile "This Instance ${Instance_port} maybe slave Instance."
   if [ -n "$string" ];then
      for i in $string;
      do
        if [ $i = OF${Instance_port} ];then
           LogToFile "This slave Instance ${Instance_port} is one of many slaves,no need to backup"
          return 7;
        fi
     done
   fi
   Master_Host=`${MYSQL_CMD} "show slave status\G;"|grep Master_Host:|awk '{print $2}'`
   if [ ! -d ${LOCALBAKDIR}/${DATE}/${Instance_port} ];then
      mkdir -p ${LOCALBAKDIR}/${DATE}/${Instance_port}
   fi
   echo "$PUBLIC_IP $INNER_IP is slave of mysql ${Master_Host}" >${LOCALBAKDIR}/${DATE}/${Instance_port}/hasmasterip-info
   if [ `grep ${Master_Host} ${master_info_dir}/master.info|wc -l` -ge 1 ] && [ `${MYSQL_CMD} "show slave status\G;"|grep Yes|wc -l` -eq 2 ];then
      LogToFile "This slave Instance ${Instance_port} is OK,and  need to BACKUP."
      edit_slave_config
      if [ $? -eq 1 ];then
         return 6;
      else
        return 1;
      fi
   else [ `grep ${Master_Host} ${master_info_dir}/master.info|wc -l` -eq 0 ] || [ `${MYSQL_CMD} "show slave status\G;"|grep Yes|wc -l` -lt 2 ]
      LogToFile "This slave Instance ${Instance_port} is abnormal,and Check the ${master_info_dir}/master.info;cann't BACKUP,CRITICAL!!"
      return 2;
   fi
fi
 if [ ! -f ${master_info_dir}/master.info ];then
  LogToFile "This Instance ${Instance_port} maybe master Instance."
  if [ -n "$string" ];then
  for i in $string;
  do
    if [ $i = ON${Instance_port} ];then
     LogToFile "This Instance ${Instance_port} is master Instance,but FORCE to backup"
     edit_slave_config
     if [ $? -eq 1 ];then
     return 6;
     else
     return 3;
     fi
    fi
  done
  fi
  if [ `${MYSQL_CMD} "show processlist"|grep "Binlog Dump"|wc -l` -ge 1 ];then
  LogToFile "This Instance ${Instance_port} has slave Instance; only need to BACKUP Permissions table"
  return 4;
  else
     LogToFile "This Instance ${Instance_port} has no slave Instance;need to BACKUP."
     edit_slave_config
   if [ $? -eq 1 ];then
   return 6;
   else
   return 5;
   fi
  fi
fi
}
function edit_slave_config()
{
if [ `${MYSQL_CMD} "show variables like 'log_slave_updates';"|grep log_slave_updates|awk '{print $2}'` != "ON" ] || [ `${MYSQL_CMD} "show variables like 'log_bin';"|grep log_bin|awk '{print $2}'` != "ON" ];then
   LogToFile "log-bin and log-slave-updates were change,it's need to manual restart mysql Instance. CRITICAL!!"
   if [ `grep "^log-slave-updates" ${CONFIG_FILE}|wc -l` -lt 1 ];then
      sed -i '/server-id/a \log-slave-updates' ${CONFIG_FILE};
      if [ `grep "^log-bin" ${CONFIG_FILE}|wc -l` -lt 1 ];then
         mkdir -p /data/log-bin;chown -R mysql.mysql /data/log-bin;
         sed -i "/server-id/a \log-bin=/data/log-bin/log-bin-${Instance_port}" ${CONFIG_FILE};
      fi
      if [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^4\.0"|wc -l` -lt 1 ] || [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^3"|wc -l` -lt 1 ] && [ `${MYSQL_CMD} "show variables like 'expire_logs_days';"|awk '(NR>1)'|awk '{print $2}'` -ne 10 ];then
         ${MYSQL_CMD} "set global expire_logs_days = 10;"
         sed -i '/^expire_logs_days/d' ${CONFIG_FILE};
         sed -i '/^log-bin/a \expire_logs_days = 10' ${CONFIG_FILE};
      fi
      if [ `${MYSQL_CMD} "show variables like 'max_binlog_size';"|awk '(NR>1)'|awk '{print $2}'` -gt 314572800 ];then
         ${MYSQL_CMD} "set @set_value = 314572800;set @@global.max_binlog_size =@set_value;"
         sed -i '/^max_binlog_size/d' ${CONFIG_FILE};
         sed -i '/^log-bin/a \max_binlog_size = 300M' ${CONFIG_FILE};
      fi
   fi
   return 1;
else 
   if [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^4\.0"|wc -l` -lt 1 ] && [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^3"|wc -l` -lt 1 ] && [ `${MYSQL_CMD} "show variables like 'expire_logs_days';"|awk '(NR>1)'|awk '{print $2}'` -ne 10 ];then
      ${MYSQL_CMD} "set global expire_logs_days = 10;"
      sed -i '/^expire_logs_days/d' ${CONFIG_FILE};
      sed -i '/^log-bin/a \expire_logs_days = 10' ${CONFIG_FILE};
   fi
   if [ `${MYSQL_CMD} "show variables like 'max_binlog_size';"|awk '(NR>1)'|awk '{print $2}'` -gt 314572800 ];then
     ${MYSQL_CMD} "set @set_value = 314572800;set @@global.max_binlog_size =@set_value;"
      sed -i '/^max_binlog_size/d' ${CONFIG_FILE};
      sed -i '/^log-bin/a \max_binlog_size = 300M' ${CONFIG_FILE};
   fi
   LogToFile "slave mysql's log-bin and log-slave-updates was opened."
fi
}

function backup_main()
{  
check_engine
LogToFile "${Instance_engine} ${BACKUP_MODE}"
${MYSQL_CMD} "set global wait_timeout =${TMP_wait_timeout};"
if [ ${Instance_engine} = "INNODB" ] && [ ${BACKUP_MODE} = "FULL" ];then
   drop_local_oldfiles 3;
   innodb_full
elif [ ${Instance_engine} = "INNODB" ] && [ ${BACKUP_MODE} = "INCREMENTAL" ];then
   drop_local_oldfiles 7;
   innodb_incremental
elif [ ${Instance_engine} = "MYISAM" ] && [ ${BACKUP_MODE} = "FULL" ];then
   drop_local_oldfiles 3;
   myisam_full
else [ ${Instance_engine} = "MYISAM" ] && [ ${BACKUP_MODE} = "INCREMENTAL" ]
   drop_local_oldfiles 7;
   myisam_incremental
fi

if [ $? -eq 0 ];then
   LogToFile "this Instance ${Instance_port} is normal,and Local BACKUP is OK"
   LogToFile1 "this Instance ${Instance_port} is normal,and Local BACKUP is OK"
   ${MYSQL_CMD} "set global wait_timeout =${OLD_wait_timeout};"
else
   LogToFile "this Instance ${Instance_port} is normal,but Local BACKUP is ERROR;CRITICAL!!"
   log_errorrecord "this mysql ${Instance_port} is normal,but Local BACKUP is ERROR;FoundError!"
   ${MYSQL_CMD} "set global wait_timeout =${OLD_wait_timeout};"
   return 1;
fi
}

function check_engine()
{
checkFileExists ${DATA_DIR}/ibdata1 && checkFileExists ${DATA_DIR}/ib_logfile0 && [ `grep "^skip-innodb" ${CONFIG_FILE}|wc -l` -eq 0 ]
if [ $? -eq 0 ];then
   LogToFile "this Instance ${Instance_port} is INNODB storage-engine"
   Instance_engine=INNODB
   if [ ! -f /usr/bin/innobackupex ];then
      Install_innodb_tool
   else
      LogToFile "innodb_tool is OK"
   fi
   choose_full_incremental
else
   LogToFile "Other  storage-engine defaults to MYISAM"
   Instance_engine=MYISAM
   choose_full_incremental
fi
}

function choose_full_incremental()
{
if [ `du -Lsm $DATA_DIR|cut -s -f1` -lt ${DEFINE_DATADIR_SIZE} ];then
   LogToFile "this Instance ${Instance_port} will use full backup"
   BACKUP_MODE=FULL
else
   LogToFile "this Instance ${Instance_port} will use incremental backup"
   BACKUP_MODE=INCREMENTAL
fi
}

function drop_local_oldfiles()
{
drop_local_dir=`date -d"-$1 days" +'%Y%m%d'`
retain_local_dir=`date -d"-$((${1}-1)) days" +'%Y%m%d'`
cd ${LOCALBAKDIR};
if [ -d ${drop_local_dir}/${Instance_port} ] && [ `du -sb ${retain_local_dir}/${Instance_port}|cut -s  -f1` -ge ${DEFINE_RETAIN_SIZE} ];then
   rm -rfv ${drop_local_dir}/${Instance_port} >>${RUN_LOG}
elif [ -d ${drop_local_dir}/${Instance_port} ] && [ `du -sb ${retain_local_dir}/${Instance_port}|cut -s  -f1` -lt ${DEFINE_RETAIN_SIZE} ];then
   LogToFile "The Local old BACKUP is ERROR;please check the ${retain_local_dir} day's backup.UNKNOWN!!"
   LogToFile1 "The Local old BACKUP is ERROR;please check the ${retain_local_dir} day's backup.UNKNOWN!!"
else 
   LogToFile "there is no BACKUP files in ${drop_local_dir} day"
fi
}

function Check_lock_file() {
if [ -f ${LOCK_FILE} ];then
   LogToFile "Last BACKUP is still runing,BACKUP is not START;WARNING!!"
   LogToFile1 "Last BACKUP is still runing,BACKUP is not START;WARNING!!"
   log_errorrecord "$0 Last BACKUP is still runing,BACKUP is not START,FoundWarning!"
   return 10;
fi
}

function innodb_full()
{
Check_lock_file
touch ${LOCK_FILE};
checkDirExists ${LOCALBAKDIR}/${DATE}/${Instance_port}
/bin/cp ${CONFIG_FILE} ${LOCALBAKDIR}/${DATE}/${Instance_port}
/usr/bin/innobackupex-1.5.1 --user=${DBUSER} --password=${DBPASS} --no-timestamp --sleep=5 --slave-info  --socket=${SOCKET_FILE}  --defaults-file=${CONFIG_FILE} ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL 
if [ $? -ne 0 ];then
   LogToFile1 "Instance ${Instance_port} Local BASE BACKUP is ERROR;CRITICAL!!"
   LogToFile "Instance ${Instance_port} Local BASE BACKUP is ERROR;CRITICAL!!"
   log_errorrecord "mysql ${Instance_port} Local BASE BACKUP is ERROR,FoundError!"
fi
tar -czf ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${Instance_engine}_FULL_${LAST_BACKUP_TIME}.tar.gz ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL 
if [ $? -ne 0 ];then
   LogToFile1 "Instance ${Instance_port} Local BASE GZIP is ERROR;maybe 'No space left on device'. CRITICAL!!"
   LogToFile "Instance ${Instance_port} Local BASE GZIP is ERROR;maybe 'No space left on device'.CRITICAL!!"
   log_errorrecord "Instance ${Instance_port} Local BASE GZIP is ERROR;maybe 'No space left on device',FoundError!"
   return 20;
fi
/bin/cp -a ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL/xtrabackup_binlog_info ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL_binlog_info;
rm -rfv ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL/ >>${RUN_LOG};
rm -fv ${LOCK_FILE} >>${RUN_LOG};
}

function myisam_full_mysqldump()
{
Check_lock_file
touch ${LOCK_FILE};
checkDirExists ${LOCALBAKDIR}/${DATE}/${Instance_port}
/bin/cp ${CONFIG_FILE} ${LOCALBAKDIR}/${DATE}/${Instance_port}

if [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^4\.0"|wc -l` -ge 1 ] || [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^3"|wc -l` -ge 1 ];then 
   #purge master logs in mysql 4.0 
   if [ `cat ${log_bin_dir}${BIN_LOG_PATTERN}.index|wc -l` -ge ${BIN_LOG_RETAIN_NUM} ];then
      UNTIL_BIN_LOG=`cat ${log_bin_dir}${BIN_LOG_PATTERN}.index|tail -20|head -1|awk -F "/" 'BEGIN{ORS=""} {print $NF}'`
      ${MYSQL_CMD} "purge master logs to '$UNTIL_BIN_LOG';"
   fi

   ${MYSQL_CMD} "FLUSH TABLES WITH READ LOCK;system ${BASE_DIR}/bin/mysqldump -S ${SOCKET_FILE} -u ${DBUSER} -p${DBPASS} --quick --lock-tables --flush-logs  -A > ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.sql;show master status;"|awk '(NR>1)'|awk '{print $1}' > ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL_binlog_info;
elif [ `${BASE_DIR}/bin/mysql  -S ${SOCKET_FILE} -u ${DBUSER} -p${DBPASS} -e "select version()" |awk '(NR>1)'|grep "4\.1"|wc -l` -ge 1 ];then
   ${MYSQL_CMD} "FLUSH TABLES WITH READ LOCK;system ${BASE_DIR}/bin/mysqldump -S ${SOCKET_FILE} -u ${DBUSER} -p${DBPASS} --quick --lock-tables --flush-logs  -A > ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.sql;show master status;"|awk '(NR>1)'|awk '{print $1}' > ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL_binlog_info;
else
   ${MYSQL_CMD} "FLUSH TABLES WITH READ LOCK;system ${BASE_DIR}/bin/mysqldump -S ${SOCKET_FILE} -u ${DBUSER} -p${DBPASS} --skip-opt --quick --lock-all-tables --master-data=2 --flush-logs -A > ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.sql;show master status;"|awk '(NR>1)'|awk '{print $1}' > ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL_binlog_info;
fi

if [ $? -ne 0 ];then
   LogToFile1 "Instance ${Instance_port} Local BASE BACKUP is ERROR;CRITICAL!!"
   LogToFile "Instance ${Instance_port} Local BASE BACKUP is ERROR;CRITICAL!!"
   log_errorrecord "mysql ${Instance_port} Local BASE BACKUP is ERROR,FoundError!"
fi

cd ${LOCALBAKDIR}/${DATE}/${Instance_port};
tar -czf ${BAKTYPE}_${Instance_engine}_FULL.sql_${LAST_BACKUP_TIME}.tar.gz ${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.sql;
if [ $? -ne 0 ];then
   LogToFile1 "Instance ${Instance_port} Local BASE GZIP is ERROR;maybe 'No space left on device'. CRITICAL!!"
   LogToFile "Instance ${Instance_port} Local BASE GZIP is ERROR;maybe 'No space left on device'.CRITICAL!!"
   log_errorrecord "mysql ${Instance_port} Local BASE GZIP is ERROR;maybe 'No space left on device',FoundError!"
   return 20;
fi
rm -fv  ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.sql >>${RUN_LOG}
rm -fv ${LOCK_FILE} >>${RUN_LOG};
edit_binlog_pos
}

function myisam_full()
{
Check_lock_file
touch ${LOCK_FILE};
checkDirExists ${LOCALBAKDIR}/${DATE}/${Instance_port}
/bin/cp ${CONFIG_FILE} ${LOCALBAKDIR}/${DATE}/${Instance_port}

if [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^4\.0"|wc -l` -ge 1 ] || [ `${MYSQL_CMD} "select version()" |awk '(NR>1)'|grep "^3"|wc -l` -ge 1 ];then 
   #purge master logs in mysql 4.0 
   if [ `cat ${log_bin_dir}${BIN_LOG_PATTERN}.index|wc -l` -ge ${BIN_LOG_RETAIN_NUM} ];then
      UNTIL_BIN_LOG=`cat ${log_bin_dir}${BIN_LOG_PATTERN}.index|tail -20|head -1|awk -F "/" 'BEGIN{ORS=""} {print $NF}'`
      ${MYSQL_CMD} "purge master logs to '$UNTIL_BIN_LOG';"
   fi
   ${MYSQL_CMD} "FLUSH TABLES WITH READ LOCK;flush logs;system tar -cf ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.tar $DATA_DIR;show master status;"|awk '(NR>1)'|awk '{print $1}' > ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL_binlog_info;
else
   ${MYSQL_CMD} "FLUSH TABLES WITH READ LOCK;flush logs;system tar -cf ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.tar $DATA_DIR;show master status;"|awk '(NR>1)'|awk '{print $1}' > ${LOCALBAKDIR}/${DATE}/${Instance_port}/FULL_binlog_info;
fi

if [ $? -ne 0 ];then
   LogToFile1 "Instance ${Instance_port} Local BASE BACKUP is ERROR;CRITICAL!!"
   LogToFile "Instance ${Instance_port} Local BASE BACKUP is ERROR;CRITICAL!!"
   log_errorrecord "mysql ${Instance_port} Local BASE BACKUP is ERROR,FoundError!"
fi

cd ${LOCALBAKDIR}/${DATE}/${Instance_port};
gzip ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.tar
mv ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_${Instance_engine}_FULL.tar.gz ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${Instance_port}_${Instance_engine}_FULL_${LAST_BACKUP_TIME}.tar.gz
rm -fv ${LOCK_FILE} >>${RUN_LOG};
edit_binlog_pos
}

function innodb_incremental() {
if [ ! -e ${LOCALBAKDIR}/FULL_DAY_${Instance_port} ];then
   innodb_full
   echo $(($RANDOM%7+1)) > ${LOCALBAKDIR}/FULL_DAY_${Instance_port}
   chmod 700 ${LOCALBAKDIR}/FULL_DAY_${Instance_port};
   /usr/bin/chattr +a ${LOCALBAKDIR}/FULL_DAY_${Instance_port};
elif [ `cat ${LOCALBAKDIR}/FULL_DAY_${Instance_port} ` -eq ` date +%u` ];then
   innodb_full
else
   Check_lock_file
   touch ${LOCK_FILE};
   checkDirExists ${LOCALBAKDIR}/${DATE}/${Instance_port}/INCREMENTAL/
   /bin/cp ${CONFIG_FILE} ${LOCALBAKDIR}/${DATE}/${Instance_port}
   ${MYSQL_CMD} "FLUSH TABLES WITH READ LOCK;flush logs;show master status;"|awk '(NR>1)'|awk '{print $1}' >${LOCALBAKDIR}/${DATE}/${Instance_port}/INCREMENTAL_binlog_info;
   rm -fv ${LOCK_FILE} >>${RUN_LOG};
   edit_binlog_pos
   backup_incremental_binlog
fi
}
function myisam_incremental()
{
if [ ! -e ${LOCALBAKDIR}/FULL_DAY_${Instance_port} ];then
   myisam_full
   echo $(($RANDOM%7+1)) > ${LOCALBAKDIR}/FULL_DAY_${Instance_port}
   chmod 700 ${LOCALBAKDIR}/FULL_DAY_${Instance_port};
   /usr/bin/chattr +a ${LOCALBAKDIR}/FULL_DAY_${Instance_port};

elif [ `cat ${LOCALBAKDIR}/FULL_DAY_${Instance_port} ` -eq ` date +%u` ];then
   myisam_full
else
   Check_lock_file
   touch ${LOCK_FILE};
   checkDirExists ${LOCALBAKDIR}/${DATE}/${Instance_port}/INCREMENTAL/
   /bin/cp ${CONFIG_FILE} ${LOCALBAKDIR}/${DATE}/${Instance_port}
   ${MYSQL_CMD} "FLUSH TABLES WITH READ LOCK;flush logs;show master status;"|awk '(NR>1)'|awk '{print $1}' >${LOCALBAKDIR}/${DATE}/${Instance_port}/INCREMENTAL_binlog_info;
   rm -fv ${LOCK_FILE} >>${RUN_LOG};
   edit_binlog_pos 
   backup_incremental_binlog
fi
}
function edit_binlog_pos() 
{
EDIT_FILE=`find ${LOCALBAKDIR}/${DATE}/${Instance_port}/ -type f -name "*_binlog_info" `
BIN_LOG_TMP1=`cat ${EDIT_FILE}`
BIN_LOG_TMP=`grep -B1 "$BIN_LOG_TMP1" ${log_bin_dir}${BIN_LOG_PATTERN}.index |grep -v "${BIN_LOG_TMP1}"`
BIN_LOG_FILE=${BIN_LOG_TMP##*/}
BIN_LOG_POS=`${BASE_DIR}/bin/mysqlbinlog ${log_bin_dir}${BIN_LOG_FILE}|tail -50|grep log_pos|tail -2|head -1|awk -F'log_pos' '{print $2}'|awk '{print $1}'`
echo "${BIN_LOG_FILE}   ${BIN_LOG_POS}" > ${EDIT_FILE}
}

function backup_incremental_binlog() 
{
START_BINLOG_FILE=`find ${LOCALBAKDIR}/ -type f -name "*binlog_info"|grep ${Instance_port}|sort |grep -B1 ${DATE}|grep -v ${DATE}|xargs cat |awk '{print $1}'`
END_BINLOG_FILE=`find ${LOCALBAKDIR}/${DATE}/${Instance_port}/ -name "*binlog_info" |xargs cat |awk '{print $1}'`

cd ${log_bin_dir};
for i in `sed -n "/${START_BINLOG_FILE}/,/${END_BINLOG_FILE}/p" ${BIN_LOG_PATTERN}.index|sed '1d'`;
do
  /bin/cp -av $i ${LOCALBAKDIR}/${DATE}/${Instance_port}/INCREMENTAL/ >>${RUN_LOG};
done

tar -czf ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${Instance_engine}_INCREMENTAL_${LAST_BACKUP_TIME}.tar.gz ${LOCALBAKDIR}/${DATE}/${Instance_port}/INCREMENTAL/
cd ${LOCALBAKDIR}/${DATE}/${Instance_port}/;
Check_local_gz ${BAKTYPE}_${Instance_engine}_INCREMENTAL_${LAST_BACKUP_TIME}.tar.gz

if [ $? -eq 0 ];then
   LogToFile "Local $1 file is OK;"
   rm -frv  INCREMENTAL >>${RUN_LOG}
   rm -fv ${LOCK_FILE} >>${RUN_LOG};
else
   LogToFile "Local $1 file is ERROR;CRITICAL!!"
   LogToFile1 "Local $1 file is ERROR;CRITICAL!!"
   rm -fv ${LOCK_FILE} >>${RUN_LOG};
   return 5;
fi
}

function Check_local_gz() {
gzip -t $1
if [ $? -eq 0 ];then
   LogToFile "Local $1 file is OK;"
   return 0;
else
   LogToFile "Local $1 file is ERROR;CRITICAL!!"
   LogToFile1 "Local $1 file is ERROR;CRITICAL!!"
   log_errorrecord "Local $1 file is ERROR,FoundError!"
   return 1;
fi
}

function backup_Permissions_tables() {
Check_lock_file
touch ${LOCK_FILE};
checkDirExists ${LOCALBAKDIR}/${DATE}/${Instance_port}
/bin/cp ${CONFIG_FILE} ${LOCALBAKDIR}/${DATE}/${Instance_port}
${MYSQL_CMD} "system ${BASE_DIR}/bin/mysqldump -S ${SOCKET_FILE} -u ${DBUSER} -p${DBPASS} --quick --lock-tables mysql user db host tables_priv columns_priv >${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_Permissions_tables.sql;"

if [ $? -ne 0 ];then
   LogToFile1 "Instance ${Instance_port} Local BASE BACKUP is ERROR;CRITICAL!!"
   log_errorrecord "mysql ${Instance_port} Local BASE BACKUP is ERROR,FoundError!"
fi

cd ${LOCALBAKDIR}/${DATE}/${Instance_port};
tar -czf ${BAKTYPE}_Permissions_tables.sql_${LAST_BACKUP_TIME}.tar.gz ${BAKTYPE}_${IP}_${Instance_port}_Permissions_tables.sql
Check_local_gz ${BAKTYPE}_Permissions_tables.sql_${LAST_BACKUP_TIME}.tar.gz

if [ $? -eq 0 ];then
   LogToFile "Local $1 file is OK;"
   rm -fv  ${LOCALBAKDIR}/${DATE}/${Instance_port}/${BAKTYPE}_${IP}_${Instance_port}_Permissions_tables.sql >>${RUN_LOG}
   rm -fv ${LOCK_FILE} >>${RUN_LOG};
else
   LogToFile "Local $1 file is ERROR;CRITICAL!!"
   LogToFile1 "Local $1 file is ERROR;CRITICAL!!"
   log_errorrecord "Local $1 file is ERROR,FoundError!"
   rm -fv ${LOCK_FILE} >>${RUN_LOG};
   return 5;
fi
}
function upload_to_ftp()
{
cd ${LOCALBAKDIR}/${DATE}/
find ./ -type f |while read line
do 
##/usr/bin/curl -T $line ftp://${ftpserver}/linux/${IP}/${BAKTYPE}/${DATE}/$line --retry 10 --retry-delay 10 -C - -S -s --ftp-create-dirs --user ${FTP_USER}:${FTP_PASS}
absfile_local=`echo ${LOCALBAKDIR}/${DATE}/$line|sed -e's/\.\///'`
upload_file $absfile_local $apptype
done
}

function backup_Instance() {
GetBaseMess "$1";
check_alive
if [ $? -eq 0 ];then
 check_master_slave
  case $? in 
  1)
  backup_main
  if [ $? -eq 1 ];then
     LogToFile1 "this Instance ${Instance_port} is normal,but Local BACKUP is ERROR;CRITICAL!!"
     log_errorrecord "mysql ${Instance_port} is normal,but Local BACKUP is ERROR FoundError!"
     return 15;
  fi
  ;;
  2)
    LogToFile "This slave Instance ${Instance_port} is abnormal,and Check the ${master_info_dir}/master.info;cann't BACKUP,CRITICAL!!"
    LogToFile1 "This slave Instance ${Instance_port} is abnormal,and Check the ${master_info_dir}/master.info;cann't BACKUP,CRITICAL!!"
    log_errorrecord "mysql slave ${Instance_port} is abnormal,and Check the ${master_info_dir}/master.info;cann't BACKUP,FoundError!"
    return 4;
  ;;
  3)
    LogToFile "This Instance ${Instance_port} is master Instance,but FORCE to backup"
    LogToFile1 "This Instance ${Instance_port} is master Instance,but FORCE to backup"
    backup_main
  ;;
  4)
    LogToFile1 "This Instance ${Instance_port} has slave Instance; only need to BACKUP Permissions table"
    drop_local_oldfiles 3;
    backup_Permissions_tables
    ;;
  5)
   LogToFile "This Instance ${Instance_port} has no slave Instance;need to BACKUP."
   LogToFile1 "This Instance ${Instance_port} has no slave Instance;need to BACKUP."
  backup_main
  ;;
  6)
  LogToFile1 "log-bin and log-slave-updates were change,it's need to manual restart mysql Instance. CRITICAL!!"
  log_errorrecord "log-bin and log-slave-updates were change,it's need to manual restart mysql Instance,FoundError!"
  return 3;
  ;;
  7)
  LogToFile1 "This slave Instance ${Instance_port} is one of many slaves,no need to backup"
  return 16;
  ;;
  esac
   
else
   LogToFile "this Instance ${Instance_port} is abnormal,cann't login into mysql server;CRITICAL!!"
   LogToFile1 "this Instance ${Instance_port} is abnormal,cann't login into mysql server;CRITICAL!!"
   log_errorrecord "this Instance ${Instance_port} is abnormal,cann't login into mysql server,FoundError!"
return 1;
fi
}
function check_pythonversion()
{
   pver_info=`rpm -qa|grep ^python-2.4`
   pver_info26=`rpm -qa|grep ^python26-devel`
   if [ -n "$pver_info" ] && [ -n "$pver_info26" ] ;then
       pyupload_script="python2.6 /root/ndserver/data_backup_system/client/main.py"
   elif [ -n "$pver_info" ] && [ -z "$pver_info26" ] ;then
      log_record "please install python26-devel at $LAST_BACKUP_TIME"
    exit 
   fi
}
#################################################################################
check_pythonversion

echo "======================= PREPARE ^_^ at `date +%Y-%m-%d[%T]` ===================" >>${RUN_LOG} 
if [ $# -eq 0 ];then
   LogToFile "that is no Instance need FORCE backup"
else
   arr=($@)
   for i in ${arr[*]};
   do 
   if [ `expr length ${i}` -eq 6 ] && [ `echo ${i:0:2}` = "ON" ] || [ `echo ${i:0:2}` = "OF" ];then
      LogToFile " that is `echo ${i:2:4}` Instance need special treatment"
   else
      LogToFile " $i Parameter is ERROR;CRITICAL!!"
      LogToFile1 " $i Parameter is ERROR;CRITICAL!!"
      PrintHelp;
      exit 2;
   fi
   done
   string=$@
fi
if [ ! -d /backup ] && [ ! -L /backup ];then
    if [ ! -d /data/backup ];then
        mkdir -p /data/backup
    fi
    ln -s /data/backup /backup
fi
checkDirExists ${LOGDIR}
checkDirExists ${MONITOR_LOG}
checkDirExists "${LOCALBAKDIR}/${DATE}"

if [ -z "${PUBLIC_IP}" ];then
   IP=${INNER_IP};
else
   IP=${PUBLIC_IP};
fi
if [ ! -f /usr/bin/curl ];then
   yum -y install curl libaio;
fi

#################################################################################
echo "">${BACKUP_STATUS_LOG};
LogToFile "============Start BACKUP at `date +%Y-%m-%d[%T]` ====================="
ps -ef|grep "mysqld "|grep -v "grep"|while read line
do
backup_Instance "$line";
done

upload_to_ftp
if [ $? -eq 0 ];then
   LogToFile1 "This Instance ${Instance_port} UPLOAD to ${ftpserver} is OK"
else
   LogToFile1 "This Instance ${Instance_port} UPLOAD to ${ftpserver} is ERROR;CRITICAL!!"
   return 2;
fi

find $LOGDIR/ -type f -name "run*" -mtime +15 |xargs rm -fv >>${RUN_LOG}
cd ${LOCALBAKDIR};find ./ -type d -empty |xargs rm -rfv >>${RUN_LOG} 
cat ${BACKUP_STATUS_LOG} >> ${RUN_LOG}
LogToFile "============END BACKUP at `date +%Y-%m-%d[%T]` ========================"
