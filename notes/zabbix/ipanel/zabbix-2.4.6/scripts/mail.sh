#!/bin/bash
#
#This script used to send alarm mail
#
#
export LANG=en_US.UTF-8
#export LANG=zh_CN.UTF-8
echo "$3" | /bin/mailx -s "$2" $1
