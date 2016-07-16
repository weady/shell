#!/bin/bash
#
#	by wangdd 2016/07/16
#
#	这个脚本的主要作用是对比数据库结构的差异

function compare_table_structure(){
	now_time=`date +%Y%m%d.%H.%M`
	company_structure_path="/usr/local/soft/xxxxx"
	business_structure_path="/usr/local/soft/xxxxxx"
	
	#compare_report 存放的是只有存储引擎不同的日志
	compare_report="/tmp/compare_table_report_${now_time}.txt"
	#table_structure_report 是处理后的最终报告
	table_structure_report="/usr/local/src/table_structure_report_${now_time}.txt"
	#对差异表进行逐行对比,日志存放于line_report
	line_report="/tmp/line_report.txt"
	echo "" >$line_report
	file_list=`ls -l $company_structure_path | awk '{print $NF}' | grep '^homed'`
	echo ""
	echo "------- Starting Compare table's structure,Please waiting -------"
	echo ""
        echo "** Left is the standard table structure | Right is business's table structure **"
	echo ""
	cd /usr/local/src; rm -f table_structure_report_*.txt
	echo "$file_list" | while read line
	do
		db_name=${line%_*}
		b_db_name=`ls -l $business_structure_path | awk '{print $NF}' | grep "$db_name"`
		if [ -z "$b_db_name" ];then
			echo "-- $business_structure_path does not exsit $line --"
			exit
		fi
		if [ "$db_name" == "homed_tsg" ];then
			table_list=`cat $company_structure_path/$line | sed '/tsg_total/,$d' | grep '^CREATE TABLE' | awk '{print $3}' | tr -d '\`'`
		else
			table_list=`cat $company_structure_path/$line | grep '^CREATE TABLE' | awk '{print $3}' | tr -d '\`'`
		fi
		for table in $table_list
		do
			echo "" >/tmp/c_compare.log
			echo "" >/tmp/b_compare.log
			company_table=`cat $company_structure_path/$line | tr -d '\`' | sed -n "/^CREATE TABLE \<$table\> /,/) ENGINE/p" | sed 's/^[ \t]*//g' | awk -F'COMMENT' '{print $1}'| sed 's/\(.*\) AUTO_INCREMENT.*\(DEFAULT.*\)/\1 \2/g' | sed 's/[ \t]*$//g' | tr -d ',;\`' >/tmp/c_compare.log`
			business_table=`cat $business_structure_path/$line | tr -d '\`' | sed -n "/^CREATE TABLE \<$table\> /,/) ENGINE/p" |sed 's/^[ \t]*//g' | awk -F'COMMENT' '{print $1}'| sed 's/\(.*\) AUTO_INCREMENT.*\(DEFAULT.*\)/\1 \2/g' |sed 's/[ \t]*$//g' | tr -d ',;\`' >/tmp/b_compare.log`
			b_table=`cat $business_structure_path/$line | tr -d '\`' |sed -n "/^CREATE TABLE \<$table\> /,/) ENGINE/p" |sed 's/^[ \t]*//g' | awk -F'COMMENT' '{print $1}'| sed 's/\(.*\) AUTO_INCREMENT.*\(DEFAULT.*\)/\1 \2/g' |sed 's/[ \t]*$//g' | tr -d ',;\`'`
			if [ -z "$b_table" ];then
				echo "[ERROR] [ Business] The table [ $table ] does not exsit in [ $db_name ]" >> $compare_report
			else
				result=`diff -y /tmp/c_compare.log /tmp/b_compare.log | grep -E '\||>|<'`
                                if [ ! -z "$result" ];then
                                        echo "" >> $compare_report
					echo "$result" > /tmp/compare_table.tmp
					num=`cat /tmp/compare_table.tmp | wc -l`
					engine_tag=`cat /tmp/compare_table.tmp | grep 'ENGINE='`
					if [ "$num" -eq 1 -a ! -z "$engine_tag" ];then
						echo "[$db_name $table] $result" | sed 's/[|<>]/|/g' >> $compare_report
					else
						cat /tmp/c_compare.log | while read line
						do
							echo "" >/tmp/c_line
							echo "" >/tmp/b_line
							c_line=`echo "$line" >/tmp/c_line`
							tag=`echo "$line" | awk '{print $1}'`
        						[[ "$tag" =~ PRIMARY|KEY|\)|CONSTRAINT ]] && tag=`echo "$line" |awk '{print $1,$2}'`
							b_line=`cat /tmp/b_compare.log| grep "^$tag\>"`
							echo "$b_line" >/tmp/b_line
							if [ ! -z "$b_line" ];then
								result_line=`diff -y /tmp/c_line /tmp/b_line | grep -E '\||>|<'`
								col_1=`echo "$result_line" | awk -F '[|<>]' '{print $1}' | sed -e 's/[ \t]*$//g;s/^[ \t]*//g'`
								col_2=`echo "$result_line" | awk -F '[|<>]' '{print $2}' | sed -e 's/[ \t]*$//g;s/^[ \t]*//g'`
								[[ -n "$result_line" ]] && echo "[$db_name $table] $col_1 | $col_2 "  >> $line_report
							else
								echo "[ERROR] [Business] [$db_name $table] does not exist [ $line ]" >> $line_report
							fi
						done
					fi
                                fi
			fi
		done
	done
	error_list=`cat $compare_report | grep 'ERROR.*does not exsit'`
	error_list_line=`cat $line_report |grep 'ERROR' | grep -v 'ENGINE='`
	diff_list=`cat $line_report | grep -vE 'ERROR|ENGINE=|^$'`
	ENGINE_diff_list=`cat $compare_report | grep 'ENGINE='`
	ENGINE_diff_list_line=`cat $line_report | grep -v 'ERROR' | grep 'ENGINE='`
	echo "===================== The Differences Fields List ====================" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "$diff_list" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "================== Does Not Exsit Table or Fields  List ==============" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "$error_list_line" | tee -a $table_structure_report
	echo "$error_list" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "================== The Storage Engine Differences List ===============" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "$ENGINE_diff_list_line" | tee -a $table_structure_report
	echo "$ENGINE_diff_list" | tee -a $table_structure_report
	echo "" | tee -a $table_structure_report
	echo "------ The Detailed Report Locate in $table_structure_report ---------"
	echo "" 
	echo "================================= END ================================" | tee -a $table_structure_report
	
	cd /tmp;rm -f $compare_report $line_report b_line c_line compare_table.tmp c_compare.log b_compare.log
	
}

compare_table_structure
