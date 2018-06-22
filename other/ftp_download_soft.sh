#!/bin/bash
#
#
#
# wangdd 2015/7/15
#
#########################################################################
function ftp_base(){
	##put backup_file to ftp
	ftp_ip="xxxxxxxxxxx"
	username="xxxxx"
	passwd="xxxxx"
	echo "Start put file to ftp at `date +%Y-%m-%d-%T`"
	echo "------------------------------------------------"
	ftp -ivn $ftp_ip  <<-EOF 
	user $username $passwd 
	binary
	lcd $2
	cd soft
	m$1 $3
	bye
	EOF
	echo "put ftp end at `date +%Y-%m-%d-%T`"
}


##########################################################################
#download_soft
ftp="xxxxx"
soft_file="/usr/local/src/soft"
dec_path="/usr/local/test"
ftp_user="xxxxx"
ftp_passwd="xxxxx"
root_path=`dirname $0`
echo $root_path
if [ -e $soft_file ];then
	echo $soft_file is exsit.
else
	mkdir -p $soft_file
fi

function download_soft()
{
	for pack in `cat $root_path/soft_name.txt`
	do
		
		if [ -e $soft_file/$pack ];then
			rm -rf $soft_file/${pack%%.*}.*
			wget --ftp-user=$ftp_user --ftp-password=$ftp_passwd $ftp/$pack -P $soft_file
			tar zxvf $soft_file/$pack -C /usr/local/test
		else
			
			wget --ftp-user=$ftp_user --ftp-password=$ftp_passwd $ftp/$pack -P $soft_file
			tar zxvf $soft_file/$pack -C /usr/local/test
		fi
	done
}

#########################################################################

function main(){
	download_soft
}

main