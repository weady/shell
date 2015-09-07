#!/bin/bash

#	split section ips string to one by one ips string, and save to env $last_split_ips, e.g. "192.168.2.101-105"=>"192.168.2.101 192.168.2.102 192.168.2.103 192.168.2.104 192.168.2.105"
#
#	like: 
#	myoldips="192.168.2.10 192.168.2.101-105 192.168.2.200"
#	source ./splitips.sh "192.168.2.10 192.168.2.101-105 192.168.2.200" --norepeat
#	mynewips=$last_split_ips
#
#	by chengxuewen, 20130515
#

#######################################
last_split_ips=""

function f_splitips()
{
	local all_oldips=$1
	local newips=""
	local oldips
	for oldips in $all_oldips
	do
		local start_ip=${oldips%-*}
		local end=${oldips#*-}
		
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
			local ip_header=${start_ip%.*}
			
			local num
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
	
	
	#remove repeat ips
	if [ "$2" == "--norepeat" ]
	then
		local newips1=""
		local addip
		for addip in $newips
		do
			if [ "$newips1" == "" ]
			then
				newips1="$addip"
				continue
			fi
			
			local hasexist=""
			local hasip
			for hasip in $newips1
			do
				if [ "$hasip" == "$addip" ]
				then				
					hasexist="1"
					break
				fi
			done
			
			if [ "$hasexist" == "" ]
			then
				newips1="$newips1 $addip"
			fi
		done	
		
		newips=$newips1 
	fi
	
	last_split_ips=$newips
}

f_splitips "$1" "$2"
export last_split_ips

#echo "oldips=$1"
#echo "last_split_ips=$last_split_ips"
