#!/bin/bash
#
#The script used to monitor HDFS health status
#
#	by wangdd 2015/10/16



file=`curl -s http://192.168.36.100:50070/dfshealth.jsp | egrep "Configured Capacity" | sed 's/<td id="col[0-9]"> //g;s/<tr class="row[a-zA-Z]*"//g;s/> /\n/g' | tail -n +2`
name=`curl -s http://192.168.36.100:50070/dfsnodelist.jsp?whatNodes=DEAD | grep "50075" | awk -F'[:/]' '{print $5}'`
function transfer(){
	value=`echo "$file" | grep "^$1:" | awk -F':' '{print $2}'`
	if [[ "$value" =~ TB$ ]];then
		res=`echo $value | awk '{print $1}'`
		#res=`echo "$tmp*1024*1024" | bc`
		echo $res
	elif [[ "$value" =~ GB$ ]];then
		tmp=`echo $value | awk '{print $1}'`
		res=`echo "$tmp/1024" | bc`
		echo $res
	elif [[ "$value" =~ %$ ]];then
		res=`echo $value | awk '{print $1}'`
		echo $res
	fi
}
function dfs_num(){
		res=`echo "$file" | egrep -A 1 "$1" | tail -n 1 |tr -d ":"`
                echo $res
}
#
case $1 in
	total)
		transfer "Configured Capacity"
		;;
	dfs.used)
		transfer "DFS Used"
		;;
	non.dfs.used)
		transfer "Non DFS Used"
		;;
	dfs.remaining)
		transfer "DFS Remaining"
		;;
	dfs.pused)
		transfer "DFS Used%"
		;;
	dfs.premaining)
		transfer "DFS Remaining%"
		;;
	live.nodes)
		dfs_num "Live Nodes"
		;;
	dead.nodes)
		dfs_num "Dead Nodes"
		;;
	dead.nodes.name)
		if [ -z "$name" ];then
			echo "ok"
		else
			res=`echo $name |sed 's/\n/ /g'`
			echo $res
		fi
		;;
	decom.nodes)
		dfs_num "Decommissioning Nodes"
		;;
	replicated)
		res=`echo "$file" | grep "Replicated" | awk -F'[:<]' '{print $2}'`
		echo $res
		;;
	*)
		echo "ERROR INPUT:"
esac
