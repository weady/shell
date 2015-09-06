#!/bin/bash
#split section ips string to one by one ips string, the parameter is variable name, result e.g. "192.168.2.101-105"=>"192.168.2.101 192.168.2.102 192.168.2.103 192.168.2.104 192.168.2.105"
# source ./splitips.sh "myips"
newips=""
for oldips in $1
do
        start_ip=${oldips%-*}
        end=${oldips#*-}

        if [ "$end" == "$start_ip" ]
        then
                if [ "$newips" == "" ]
                then
                        newips=$start_ip
                else
                        newips="$newips $start_ip"
                fi
        else
                start=${start_ip##*.}
                ip_header=${start_ip%.*}

                for((num=$start;num<=$end;num++))
                do
                        if [ "$newips" == "" ]
                        then
                                newips="$ip_header.$num"
                        else
                                newips="$newips $ip_header.$num"
                        fi
                done
        fi
done