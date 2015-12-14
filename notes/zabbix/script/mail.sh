#!/bin/bash
#
#This script used to send alarm mail
#
#
echo "$3" | /bin/mailx -s "$2" $1
