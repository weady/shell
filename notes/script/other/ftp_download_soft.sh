#!/bin/bash
#
#
#
# wangdd 2015/7/15
#
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
download_soft
#########################################################################
