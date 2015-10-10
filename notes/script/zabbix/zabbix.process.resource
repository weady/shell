#!/bin/bash
process=$1
name=$2
case $2 in
mem)
echo "`ps -e -o 'comm,pcpu,rsz' | awk '{a[$1]+=$3}END{for(key in a) print key,a[key]/1024}' | grep "$1\>" | awk '{print $2}'`"
;;
cpu)
echo "`ps -e -o 'comm,pcpu,rsz' | awk '{a[$1]+=$2}END{for(key in a) print key,a[key]}' | grep "$1\>" | awk '{print $2}'`"
;;
*)
echo "Error input:"
;;
esac
exit 0
