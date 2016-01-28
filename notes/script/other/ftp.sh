#!/bin/bash
#
# ./ftp.sh get|put local_dir file
#

##put backup_file to ftp
ftp_ip="xxxxxxxxxxx"
username="xxxxx"
passwd="xxxxx"
echo "Start put file to ftp at `date +%Y-%m-%d-%T`"
echo "------------------------------------------------"
ftp -ivn $ftp_ip  <<EOF 
user $username $passwd 
binary
lcd $2
cd soft
m$1 $3
bye
EOF
echo "put ftp end at `date +%Y-%m-%d-%T`"
