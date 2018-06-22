#!/bin.bash
#backup 00:00:00
week=`date +%u`
Date=`date +%Y-%m-%d`
year=`date +%Y`
month=`date +%m`
day=`date +%d`
bakpath=/var/bak/webbak
webpath=/var/htmlwww
wzbakup=/var/bak/webbak/wzbf
backup=$bakpath/$year/$month/$(date +%d -d "1 day ago")
web=(web1 web2 web3)
for i in `ls $webpath`
        do
        if [[ $week -ne 1 ]];then
                if [ ! -d $backup ]; then
                        mkdir -p $backup/$i
                        mkdir -p $bakpath/$i
                fi
 
                        tar -g $bakpath/$i.txt -zPcf $backup/$i.tar.gz $webpath/$i
        else
                if [ ! -d $wzbakup ]; then
                        mkdir -p $wzbakup
                fi
                cd $wzbakup
                tar -g $bakpath/$i.txt -zcPf $PWD/$i$Date.tar.gz $webpath/$i
                rm -rf $i$(date +%Y-%m-%d -d "7 days ago").tar.gz
                rm -rf $backup/*
        fi
done
