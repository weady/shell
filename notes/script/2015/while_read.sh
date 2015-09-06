#!/bin/bash
#
#	 wangdd 2015/7/24
#
# 	 while read do .... done < file
#
#
#eg.1-----------------------------------------------------------
old_IFS=$IFS
IFS=:
while read user pass uid gid fullname homedir shell
do
	echo $shell
done < /etc/passwd
IFS=$old_IFS

#eg.2------------------------------------------------------------
path="/homed/ilogslave"
echo ${#path}

#eg.3-------------------------------------------------------------
