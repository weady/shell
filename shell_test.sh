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
  read name
  echo "welcome $name login in!"
  if read -t 3 -p "please enter your name:" name1
  
  then 
  
      echo "hello $name1 ,welcome to my script"
  
  else
  
      echo "sorry,too slow"
  
  fi
  
  read -s -p "passwd is:" passwd
  echo "your passwd is $passwd"
  exit 0
#eg.4-------------------------------------------------------------
