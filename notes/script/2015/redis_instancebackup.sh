#!/bin/bash
#purpose: This script is used to backup redis instance, then invoke python client script to upload file backuped to
#         ftp server (net disk)
#auth:  NetDragon Websoft Inc. ,job number: 146588
#date: 2014/09/04
#General Public License
#Version: 1.1
#Usage:
#Note: if redis need password to connect, must give "REDIS_PASSWORD" some a value according to redis runing Firstly

if [ ! -d /backup ] && [ ! -L /backup ];then
    if [ ! -d /data/backup ];then
        mkdir -p /data/backup
    fi
    ln -s /data/backup /backup
fi
# write a function to get time dynamicly
function get_datetime(){
   dt=`date +%Y%m%d%H%M`
   echo $dt
}

###############################################
#Section 1: define common variables
LAST_BACKUP_TIME=$(get_datetime)

pyupload_script="python /root/ndserver/data_backup_system/client/main.py"
## apptype info should be provided for uploadfile program
apptype=redis

REDIS_BASIC_LOCATION=/usr/local/redis/
REDIS_BACKUP_LOG=/root/ndserver/statuslog/

REDIS_BIN_BASIC=${REDIS_BASIC_LOCATION}bin/
REDIS_ETC_BASIC=${REDIS_BASIC_LOCATION}etc/
REDIS_DATA_BASIC=/data/redis_data/
REDIS_IPPORT=${REDIS_BACKUP_LOG}redis_ip_port.txt
REDIS_IPPORT_TMPFILE=${REDIS_BACKUP_LOG}redis_ip_porttmp.log
TMPNEED_FILE=/tmp/connected_slaves.log
REDIS_PASSWORD=""
PUB_IP=
INNER_IP=

BACKUP_BASIC=/backup/${apptype}/

SHELL_BASIC=$(cd $(dirname $0); pwd)/
SHELL_LOG_FILE=${REDIS_BACKUP_LOG}redis_backup.log
SHELL_PID_FILE=${REDIS_BACKUP_LOG}redis_backup_pid.pid

BACKUP_DATE=`date +%Y%m%d`

DATA_RETENTION_TIME=7

MONITOR_LOG=/tmp/monitorbackup/
MONITOR_LOG_FILE=${CHECK_LOG}file_monitor.log
#Section 2: define function
###############################################

function backup_main()
{
        ready_env
        check_pythonversion
        get_ip
        check_running
        get_redis_instance
        backup_all_redis
        delete_old_file
        backup_exit
}

function ready_env()
{
        if [ ! -d $MONITOR_LOG ];then
           mkdir -p $MONITOR_LOG
        fi

        if [ ! -d $REDIS_DATA_BASIC ];then
           log_record "${REDIS_DATA_BASIC} redis source directory not existed ${LAST_BACKUP_TIME}"
           log_errorrecord "`hostname` ${REDIS_DATA_BASIC} source directory not existed FoundError ${LAST_BACKUP_TIME}"
           exit 0
        fi

        if [ ! -d $REDIS_BACKUP_LOG ];then
           mkdir -p $REDIS_BACKUP_LOG
        fi

        if [ ! -d $BACKUP_BASIC ];then
           mkdir -p $BACKUP_BASIC
        fi
}

function get_ip()
{
        ##for IP in `ifconfig |grep 'inet add'|grep -v "inet addr:127\.0\.0\.1"| awk -F: '{print $2}'|awk '{print $1}'|head -n 2`
        for IP in `ifconfig |grep 'Ethernet  HWaddr' -A3|grep -v '255.255.255.255'|grep 'inet add'|grep -v "inet addr:127\.0\.0\.1"|grep -v "inet addr:10\."|head -1|awk -F: '{print $2}'|awk '{print $1}'`
        do
                # get two bit length of ip net segment to detect ip is public or private
                TEMP=${IP:0:2}
                if [ $TEMP -eq 10 ]
                then
                        INNER_IP=$IP
                else
                        PUB_IP=$IP
                fi
        done
        return 0
}

function check_running()
{
        if [ -f ${SHELL_PID_FILE} ]
        then
                log_record "script $0 is runing,please check!"
                log_errorrecord "script $0 is runing,FoundWarning please check!"
                exit 1
        else
                touch ${SHELL_PID_FILE}
        fi
}

function get_redis_instance()
{
        netstat -lntp |grep redis-server|grep '^tcp' > ${REDIS_IPPORT_TMPFILE}
        if [ -s ${REDIS_IPPORT_TMPFILE} ];then
           awk '{ print $4 }' ${REDIS_IPPORT_TMPFILE}|awk -F ":" '{print $1 " "$2}'  > ${REDIS_IPPORT}
           rm -f ${REDIS_IPPORT_TMPFILE}
        else
           rm -f ${REDIS_IPPORT_TMPFILE}
           log_record "No redis is running please check $LAST_BACKUP_TIME"
           exit 1
        fi
}

function backup_all_redis()
{
        #1) begin backup all redis config file
        if [ ! -d ${REDIS_ETC_BASIC} ];then
            log_record "${REDIS_ETC_BASIC} config redis directory not existed ${LAST_BACKUP_TIME}"
            log_errorrecord "${REDIS_ETC_BASIC} config redis directory not existed FoundError ${LAST_BACKUP_TIME}"
            exit 1
        fi
        if [ ! -d ${BACKUP_BASIC}${BACKUP_DATE} ];then
           mkdir -p ${BACKUP_BASIC}${BACKUP_DATE}
        fi

        redis_allconf=redis_allconf_${LAST_BACKUP_TIME}.tgz
        tar zcf ${redis_allconf} ${REDIS_ETC_BASIC}
        absname_all_redisconf=${BACKUP_BASIC}${BACKUP_DATE}/all_redisconf/${redis_allconf}
        absdirname_all_redisconf=`dirname $absname_all_redisconf`
        if [ ! -d $absdirname_all_redisconf ];then
           mkdir -p $absdirname_all_redisconf
        fi
        mv ${redis_allconf} $absdirname_all_redisconf
        upload_file $absname_all_redisconf $apptype

        # end backup all redis config file

        #2) begin backup all redis rds or aof file
        while read -r IP PORT
        do
                if [ ! -d ${BACKUP_BASIC}${BACKUP_DATE}/${PORT} ];then
                   mkdir -p ${BACKUP_BASIC}${BACKUP_DATE}/${PORT}
                fi
                # make sure redis is needed password to connect redis.
                if [ -n "$REDIS_PASSWORD" ];then
                    redis_check_cmd="${REDIS_BIN_BASIC}redis-cli -h $IP -p $PORT -a ${REDIS_PASSWORD}"
                else
                    redis_check_cmd="${REDIS_BIN_BASIC}redis-cli -h $IP -p $PORT"
                fi

                TEMP=${IP:0:1}
                if [ $TEMP -eq 0 ];then  #convert 0.0.0.0 to inner ip
                   IP=$INNER_IP
                   echo $IP
                fi


                ##begin simulate connect with redis instance before backup,if connect fail then continue
                $redis_check_cmd info|grep 'redis_version'
                test_state=$?
                if [ $test_state -ne 0 ];then
                   log_record "Can not connect redis instance: ip $IP port $PORT $LAST_BACKUP_TIME"
                   log_errorrecord "Can not connect redis instance: ip $IP port $PORT FoundError $LAST_BACKUP_TIME"
                   continue
                fi
                ##end simulate connect with redis instance

                ##define default rds and aof file name.  The name of them may be changed according to the checking redis configuration dynamicly on running.
                rdbfile_src=${REDIS_DATA_BASIC}${PORT}/dump.rdb
                rdbfile_dst=${BACKUP_BASIC}${BACKUP_DATE}/${PORT}/dump_${LAST_BACKUP_TIME}.rdb
                aoffile_src=${REDIS_DATA_BASIC}${PORT}/appendonly.aof
                aoffile_dst=${BACKUP_BASIC}${BACKUP_DATE}/${PORT}/appendonly_${LAST_BACKUP_TIME}.aof

                rdbname=`$redis_check_cmd config get dbfilename|grep -v 'dbfilename'|tr -d '\r'`
                if [ -n "$rdbname" ];then
                   rdbfile_src=${REDIS_DATA_BASIC}${PORT}/$rdbname
                fi
                # check redis instance parameter appendonly enable or not
                $redis_check_cmd config get appendonly |grep 'yes'
                appendonly_setting=$?

                ##check redis parameter: save parameter setted or not
                save_value=`$redis_check_cmd config get save|grep -v save`

                ## if both appendonly and save parameter not  enabled,then no backup,go on checking next instance
                if [ $appendonly_setting -ne 0 ] && [ -z "$save_value" ];then
                   log_record "This redis instance: ip $IP port $PORT  no save command setting and no enable appendonly,so no need backup it $LAST_BACKUP_TIME"
                   continue
                fi

                # if redis instance is master role and has slaves at the same time,no need backup like this type of redis
                # delete '\r' using tr -d '\r'
                $redis_check_cmd info|grep 'role:master' -A 4|grep 'connected_slaves' >$TMPNEED_FILE
                found_connedslaves_state=$?
                if [ $found_connedslaves_state -eq 0 ];then
                   slave_number=`awk -F':' '{print $2}' $TMPNEED_FILE |tr -d '\r'`
                   if [ $slave_number -ge 1 ];then
                      log_record "This redis instance: ip $IP port $PORT is master role and has slaves no need backup at $LAST_BACKUP_TIME"
                      continue
                   else
                   #if redis is master and no slave,force save and copy redis rds file to another place for backup
                      $redis_check_cmd bgsave |grep 'saving started'
                      rds_state=$?
                      if [ $rds_state -eq 0 ];then
                         log_record "$redis_check_cmd bgsave successful at $LAST_BACKUP_TIME"
                         log_record `$redis_check_cmd lastsave`
                         /bin/cp -a $rdbfile_src $rdbfile_dst
                         tar zcf ${rdbfile_dst}.tgz $rdbfile_dst
                         upload_file ${rdbfile_dst}.tgz $apptype
                         rm -f $rdbfile_dst
                      fi
                    #if redis appendonly parameter enabled,force save and copy redis aof file to another place for backup
                      if [ $appendonly_setting -eq 0 ];then
                         sleep 30
                         $redis_check_cmd bgrewriteaof |grep 'rewriting started'
                         aof_rewrite_state=$?
                         if [ $aof_rewrite_state -eq 0 ];then
                            log_record "$redis_check_cmd bgrewriteaof successful at $LAST_BACKUP_TIME"
                            aoffilename=`$redis_check_cmd config get appendfilename|grep -v 'appendfilename'|tr -d '\r'`
                            if [ -n "$aoffilename" ];then
                               aoffile_src=${REDIS_DATA_BASIC}${PORT}/$aoffilename
                            fi
                            /bin/cp -a $aoffile_src $aoffile_dst
                            tar zcf ${aoffile_dst}.tgz  $aoffile_dst
                            upload_file ${aoffile_dst}.tgz $apptype
                            rm -f $aoffile_dst
                         else
                             log_record "$redis_check_cmd bgrewriteaof fail at $LAST_BACKUP_TIME"
                             log_errorrecord "$redis_check_cmd bgrewriteaof fail FoundError $LAST_BACKUP_TIME"
                         fi
                      fi
                   fi
                fi

                # if redis is slave role,then backup it.
                $redis_check_cmd info|grep 'role:slave'
                state_slave=$?
                if [ $state_slave -eq 0 ];then
                   #force save and copy redis rds file to another place for backup
                   $redis_check_cmd bgsave |grep 'saving started'
                   rds_stateslave=$?
                   if [ $rds_stateslave -eq 0 ];then
                      log_record "$redis_check_cmd bgsave successful at $LAST_BACKUP_TIME"
                      log_record `$redis_check_cmd lastsave`
                      /bin/cp -a $rdbfile_src $rdbfile_dst
                      tar zcf ${rdbfile_dst}.tgz $rdbfile_dst
                      upload_file ${rdbfile_dst}.tgz $apptype
                      rm -f $rdbfile_dst

                   fi

                   if [ $appendonly_setting -eq 0 ];then
                      sleep 30
                      $redis_check_cmd bgrewriteaof |grep 'rewriting started'
                      aof_rewrite_state=$?
                      if [ $aof_rewrite_state -eq 0 ];then
                         log_record "$redis_check_cmd bgrewriteaof successful at $LAST_BACKUP_TIME"
                         aoffilename=`$redis_check_cmd config get appendfilename|grep -v 'appendfilename'|tr -d '\r'`
                         if [ -n "$aoffilename" ];then
                            aoffile_src=${REDIS_DATA_BASIC}${PORT}/$aoffilename
                         fi
                         /bin/cp -a $aoffile_src $aoffile_dst
                         tar zcf ${aoffile_dst}.tgz  $aoffile_dst
                         upload_file ${aoffile_dst}.tgz  $apptype
                         rm -f $aoffile_dst
                       else
                         log_record "$redis_check_cmd bgrewriteaof fail at $LAST_BACKUP_TIME"
                         log_errorrecord "$redis_check_cmd bgrewriteaof fail FoundError $LAST_BACKUP_TIME"
                      fi
                   fi
                fi
        done < ${REDIS_IPPORT}
        # end backup all redis rds or aof file
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
# invoke python client program to up file backed to ftp server (net disk)
function upload_file()
{
   absfilename=$1
   apptype=$2
   $pyupload_script -f $absfilename -t $apptype
}

function log_record()
{
        echo $1 >> ${SHELL_LOG_FILE}
        return 0
}
function log_errorrecord()
{
   echo $1 >> ${MONITOR_LOG_FILE}
   return 0
}
function delete_old_file()
{
        find $BACKUP_BASIC -mtime +${DATA_RETENTION_TIME} -type f |xargs rm -f
}

function backup_exit()
{
        rm -f $SHELL_PID_FILE
        return 0
}

#Section 3: invoke main function
backup_main
