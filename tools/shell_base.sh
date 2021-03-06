#!/bin/bash
#
#主要记录shell的一些基本开发技巧
#
#	 wangdd 2015/7/24
#
#eg.1-----------------------------------------------------------
  old_IFS=$IFS
  IFS=:
  while read user pass uid gid fullname shell
  do
  	echo $shell
  done < /etc/passwd
  IFS=$old_IFS
  
#eg.2------------------------------------------------------------
  path="/slave"
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
#awk test script
BEGIN { OFS = "\t"}
{
	total = 0
	for (i=2;i<=NF;i++)
	total += $i
	avg = total/(NF-1)
	student_avg[NR]=avg
	if(avg >= 90) grade = "A"
	else if (avg >= 80) grade = "B"
	else if (avg >= 70) grade = "C"
	else if (avg >= 60) grade = "D"
	else grade = "F"
	++class_grade[grade]
	print $1,avg,grade
	
}
END{
	for (x=1;x<=NR;x++)
		class_avg_total+=student_avg[x]
		class_average = class_avg_total /NR
	for (x=1;x<=NR;x++)
		if (student_avg[x] >= class_average)
			++above_average
		else
			++below_average
	print ""
	print "Class Average:",class_average
	print "At or Above Average:",above_average
	print "Beow Average:",below_average
	for ( letter_grade in class_grade)
		print letter_grade ":",class_grade[letter_grade] | "sort"
}
#eg.5-------------------------------------------------------------
#利用awk处理两个文件时，原理是找出两个文件的共同列，以这个共同列作为数据的下标，然后把要处理列的值赋予这个数组，然后在另一个文件中进行调用，进而实现对两个文件中列操作
#File processing command
#比较 a.txt的1-4字符 和 b.txt的2-5 字符，如果相同，将b.txt 的第二列 与 a.txt 合并 
awk  'NR==FNR{a[substr($1,2,5)]=$2}NR>FNR&&a[substr($1,1,4)]{print $0, a[substr($1,1,4)] }' b.txt a.txt
#用某一文件的一个域替换另一个文件中的的特定域
awk 'BEGIN{OFS=FS=":"} NR==FNR{a[$1]=$2}NR>FNR{$2=a[$1];print $0 >"result.txt"}' shadow passwd
#如果文件a中包含文件b，则将文件b的记录打印出来 
awk -F'[/,]' 'NR==FNR{a[$0]}NR>FNR{($2 in a);print $0}' b.txt a.txx
#两文件中，若干字段相同，然后输出相同部分
awk 'NR==FNR{a[$1]=$1"x"$2"x"$3}NR>FNR{b=substr($4,3);c=$3"x"b"x"$6;if(c==a[$3]) print $0}' a.txt b.txt
#两个文件中对应列相加
awk '{for(i=1;i<=NF;i++)a[i]=$i;getline < "b.txt";for (j=1;j<=NF;j++) printf $j+a[j]" ";printf "\n"}' a.txt
#eg.6-------------------------------------------------------------
	seq -s '#' 100 | sed -e 's/[0-9]*//g'
	arch=i486
	[[ $arch = i*86 ]] && echo "arch is x86!" 
#eg.7-------------------------------------------------------------
	a0="abc"
	j=0
	b=a$j
	echo ${!b}
	eval b="$"a"$j"
	echo $b
#eg.8-------------------------------------------------------------
	expre="111.12GB"
	[[ $expre =~ GB$ ]] && echo "ok"
#eg.9-------------------------------------------------------------
	for num in `seq 1 2 100`
	do
	        echo -n "$num|"
	done
	echo 
#eg.10-------------------------------------------------------------
	a1=11
	a2=12
	a3=$[$a1+$a2]
	a4=`expr $a1 + $a2`
	echo $a4
	echo $a3
#eg.11-------------------------------------------------------------
	testfile="/data1/wangdong/shell/a.txt"
	[[ -s "$testfile" ]] && echo "size gt zero" || echo "empty"
#eg.12-------------------------------------------------------------
	#利用${file//}截取字段
	line='/dev/sdb1: LABEL="/d2" UUID="ad354338-2059-4c73-a11a-39a5949aeedc" TYPE="ext4"'
	type_=${line/*TYPE=\"/}
	type_=${type_/\"*/}
	echo $type_
#eg.13-------------------------------------------------------------
#linux记录所有用户操作命令方法,编辑/etc/profile文件
	#history
	export HISTTIMEFORMAT="[%Y%m%d-%H%M-:%S]"
	USER_IP=`who -u am i 2>/dev/null| awk '{print$NF}'|sed -e 's/[()]//g'`
	HISTDIR=/var/log/.hist
	if [ -z $USER_IP ]
	then
	 USER_IP=`hostname`
	fi
	if [ ! -d $HISTDIR ]
	then
	   mkdir -p $HISTDIR
	   chmod 777 $HISTDIR
	fi
	if [ ! -d $HISTDIR/${LOGNAME} ]
	then
	    mkdir -p $HISTDIR/${LOGNAME}
	    chmod 300 $HISTDIR/${LOGNAME}
	fi
	export HISTSIZE=8192
	DT=`date +%Y%m%d_%H%M%S`
	export HISTFILE="$HISTDIR/${LOGNAME}/${USER_IP}.hist.$DT"
	chmod 600 $HISTDIR/${LOGNAME}/*.hist* 2>/dev/null
	if [[ "$PROMPT_COMMAND" == "" ]]; then
	    export PROMPT_COMMAND="history -w"
	else
	    export PROMPT_COMMAND="$PROMPT_COMMAND;history -w"
	fi
