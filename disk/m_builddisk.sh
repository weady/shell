#!/bin/bash




#do read disk info and build config file
function f_read_current_disk_info()
{

	f_log "$LINENO - function,f_read_current_disk_info"
	build_tmp=$path/build_tmp
	f_log "$LINENO - $build_tmp"
	touch $build_tmp
	
	rm -rf $conf_path
	touch $conf_path
	
	blkid > $build_tmp
	while read line
	do	
		panfu_=${line/:*/}
		f_log "$LINENO - $panfu_"
				
		uuid_=${line/*UUID=\"/}
		uuid_=${uuid_/\"*/}
		f_log "$LINENO - $uuid_"		

		dir_=`df -l| grep $panfu_`
		dir_=`echo $dir_|awk '{print $6}'`
				
		#if [[ $dir_ = /data* ]] || [[ $dir_ = /r2 ]]
		if [[ $dir_ = /data* ]]
		then
			label_=${dir_/data/d}			
		#elif [ $dir_ ]
		#then
		#	label_=$dir_
		else
			continue
		fi
		f_log "$LINENO - $dir_"
		
		type_=${line/*TYPE=\"/}	
		type_=${type_/\"*/}
		f_log "$LINENO - $type_"
			
		local j=0
		local flag=0
		for temp in ${disk_conf[@]}
		do
			if [[ $temp = *$uuid_,* ]] || [[ $temp = *,$label_,* ]] || [[ $temp = *,$dir_,* ]]
			then
				f_log "$LINENO - disk config repeat think is wrong!!!!!!!"
				flag=1
			fi
		done

		f_log "$LINENO - add label to the disk"
		e2label UUID=$uuid_ $label_
				
		f_log "$LINENO - write disk config to $conf_path"
		if [ $flag -eq 0 ]
		then
		
			echo change the config /etc/fstab
			temp=${label_/\//\\/}
			sed -i "/^LABEL=$temp/ d" $fstab
			temp=${panfu_//\//\\/}
			sed -i "/^$temp/ d" $fstab 
			
			temp="LABEL=$label_     $dir_                  $type_ defaults        1 0"
			echo $temp >> $fstab
		
			echo $uuid_,$panfu_,$dir_,$label_,$type_ >> $conf_path
			disk_conf[$i]="$uuid_,$label_,$dir_,$type_"
			let i++
		fi

		uuid_=""
		panfu_=""
		label_=""
		dir_=""
		type_=""
	done < $build_tmp
	rm -rf $build_tmp
}
	
	
f_read_current_disk_info;
	
	

conf=`cat $conf_path`	
f_log "$LINENO - $conf"