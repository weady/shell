#!/bin/bash


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

CHECK_LOG=/root/ndserver/statuslog/
SHELL_LOG_FILE=${CHECK_LOG}file_backup.log
MONITOR_LOG=/tmp/monitorbackup/
MONITOR_LOG_FILE=${MONITOR_LOG}file_monitor.log
SHELL_PID_FILE=${CHECK_LOG}file_backup_pid.pid
BACKUP_DATE=`date +%Y%m%d`

DATA_RETENTION_TIME=7
IPADDR=
pyupload_script="python /root/ndserver/data_backup_system/client/main.py"

## apptype info should be provided before running this script.
apptype=sysbak

function backup_main()
{
   check_running
   check_pythonversion
   backup_datafiles usr_local /usr/local /backup/web/usr
   backup_datafiles etc /etc /backup/web/etc
   #backup_datafiles data_wwwroot /data/wwwroot /backup/web/wwwroot
   backup_exit
}

function get_ip()
{
   ip_num=`ifconfig |grep 'Ethernet  HWaddr' -A3|grep 'inet add'|awk -F: '{print $2}'|awk '{print $1}'|wc -l`
   if [ $ip_num -gt 1 ];then
      #check whether has inner ip,default we chose inner ip
      ifconfig |grep 'Ethernet  HWaddr' -A3|grep 'inet add'|awk -F: '{print $2}'|awk '{print $1}'|grep ^10
      if [ $? -eq 0 ];then
         IPADDR=`ifconfig |grep 'Ethernet  HWaddr' -A3|grep 'inet add'|awk -F: '{print $2}'|awk '{print $1}'|grep ^10`
      else
         IPADDR=`ifconfig |grep 'Ethernet  HWaddr' -A3|grep 'inet add'|awk -F: '{print $2}'|awk '{print $1}'|head -1`
     fi
   fi
}

function check_running()
{
   if [ ! -d $CHECK_LOG ];then
      mkdir -p $CHECK_LOG
   fi
   if [ ! -d $MONITOR_LOG ];then
      mkdir -p $MONITOR_LOG
   fi
   if [ -f ${SHELL_PID_FILE} ]
   then
       log_record "script $0 is running on host `hostname`,please check! At $LAST_BACKUP_TIME"
       log_errorrecord "$0 script is running FoundWarning on host `hostname`,please check! At $LAST_BACKUP_TIME"
       exit 1
   else
       touch ${SHELL_PID_FILE}
   fi
}

function  backup_datafiles()
{
   pkg_name=${1}_${LAST_BACKUP_TIME}
   src_path=$2
   dst_path=${3}/${BACKUP_DATE}
   abs_pkg_name=${dst_path}/${pkg_name}.tgz
   if [ $# -ne 3 ];then
      log_record "you must provide three parameters like this: 'backup_datafiles tarfilename /usr/local /backup/webbackup' At $LAST_BACKUP_TIME"
      log_errorrecord "provide backup parameter $* FoundError,you should provide three parameters At $LAST_BACKUP_TIME"
      exit 0
   fi

   if [ ! -d $src_path ];then
      log_record "`hostname` $src_path not existed, it must be right. at $LAST_BACKUP_TIME"
      log_errorrecord "$src_path not existed FoundError,At $LAST_BACKUP_TIME"
      exit 0
   fi

   if [ ! -d $dst_path ];then
      mkdir -p $dst_path
   fi

   tar zcf $pkg_name $src_path
   /bin/mv -f $pkg_name $abs_pkg_name
   if [ -e $abs_pkg_name ];then
      log_record "`hostname` $abs_pkg_name backup Successfully At $LAST_BACKUP_TIME"
      upload_file $abs_pkg_name $apptype
      delete_old_file ${3}
   else
      log_record "$abs_pkg_name file not existed on `hostname` At $LAST_BACKUP_TIME"
      log_errorrecord "$abs_pkg_name file not existed on `hostname` FoundError At $LAST_BACKUP_TIME"
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

   check_backpath=$1
   dele_dirdate=`date -d"-$DATA_RETENTION_TIME days" +'%Y%m%d'`
   tag_alldir=/tmp/list_alldir.txt
   tag_deldir=/tmp/list_deledir.txt
   rm -f $tag_alldir >/dev/null 2>&1
   rm -f $tag_deldir >/dev/null 2>&1
   ls $check_backpath|grep '[0-9]\{4\}[0-9]\{2\}[0-9]\{2\}'|sort -n >$tag_alldir
   found_linenum=`awk '/'$dele_dirdate'/ {print NR}' $tag_alldir`
   if [ -n "$found_linenum" ];then
      # get all old directory name before $dele_dirdate under $check_backpath directory
      awk -v get_linenum=$found_linenum '{if(NR<=get_linenum) {print $0}}' $tag_alldir >$tag_deldir
   fi

   if [ $# -eq 1 ];then
      if [ -s "$tag_deldir" ];then
         while read k
         do
         dele_olddir=${check_backpath}/$k
         if [ -d $dele_olddir ];then
            echo "rm -rf $dele_olddir"
            rm -rf $dele_olddir
         else
            log_record "File $dele_olddir not existed on `hostname` at $LAST_BACKUP_TIME"
         fi
         done <$tag_deldir
      fi
   else
      log_record "you must provide a  parameters like this: 'delete_old_file /backup/nginx/etc' at $LAST_BACKUP_TIME"
      exit 0
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
function backup_exit()
{
   rm -f $SHELL_PID_FILE
   return 0
}

#Section 3: invoke main function
backup_main

#---------------------------------------
#