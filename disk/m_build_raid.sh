#!/bin/bash


function f_import_disk()
{
	echo f_import_disk
}

function f_build_raid()
{

	echo "f_build_raid begin..."

	#find new disk
	#content=`/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aAll`

	
		ip=`ifconfig |grep "inet addr:"|grep -v "127.0.0.1"|cut -d: -f2|awk '{print $1}'|awk '{print $1}'|head -1`

		



	if ifconfig | grep "192.168.33."
	then 
	
			enclosure=""
			group=""
			span=""
			arm=""
			enclosure_pos=""
			device_id=""
			foreign_state=""
		

	
	
		/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aAll | while read line
		do
		
		
		
			tmp="^Enclosure\s\+Device\s\+ID:\s\+\w\+$"
			if echo $line | grep -q "$tmp"
			then
				enclosure=`echo $line | sed "s/^Enclosure\s\+Device\s\+ID:\s\+//g"`
				f_log "$LINENO - enclosure Device ID="$enclosure
			fi

			tmp="^Slot\s\+Number:\s\+\w\+$"
			if echo $line | grep -q "$tmp"
			then
				slot=`echo $line | sed "s/^Slot\s\+Number:\s\+//g"`
				f_log "$LINENO - slot="$slot
			fi

			
			#tmp="^Drive's\s\+position:\s\+DiskGroup:\s\+\w\+,\s\+Span:\s\+\w\+,\s\+Arm:\s\+\w\+$"
			tmp=".*DiskGroup:\s\+\w\+,\s\+Span:\s\+\w\+,\s\+Arm:\s\+\w\+$"
			#echo line=============================$line
			#echo tmp============================$tmp
			if echo $line | grep -q "$tmp"
			then
				#xx=`echo $line | sed "s/^Drive's\s\+position:\s\+DiskGroup:\s\+//g" | sed "s/,\s\+Span:\s\+/,/g" | sed "s/,\s\+Arm:\s\+/,/g" `
				xx=`echo $line | sed "s/.*DiskGroup:\s\+//g" | sed "s/,\s\+Span:\s\+/,/g" | sed "s/,\s\+Arm:\s\+/,/g" `
				group=`echo $xx | sed "s/,.*//g"`
				span=`echo $xx | sed "s/\(\w\+,\)\?//" | sed "s/,\w\+//g"`
				
				# echo "xxxxxxxxxxxxx"
				# echo $xx | sed "s/\(\w\+,\)\?//"
				# echo $xx | sed "s/\(\w\+,\)\?//" | sed "s/,\w\+//g"
				# echo "ooooooooooooo"

				arm=`echo $xx | sed "s/\w\+,\w\+,//g"`	
				f_log "$LINENO - xx="$xx
				f_log "$LINENO - group="$group
				f_log "$LINENO - span="$span
				f_log "$LINENO - arm="$arm
			fi  

			tmp="^Enclosure\s\+position:\s\+\w\+$"
			if echo $line | grep -q "$tmp"
			then
				enclosure_pos=`echo $line | sed "s/^Enclosure\s\+position:\s\+//g"`
				f_log "$LINENO - enclosure position="$enclosure_pos
			fi  
			
			tmp="^Device\s\+Id:\s\+\w\+$"
			if echo $line | grep -q "$tmp"
			then
				device_id=`echo $line | sed "s/^Device\s\+Id:\s\+//g"`
				f_log "$LINENO - device_id="$device_id
			fi

			tmp="^Foreign\s\+State:.*"
			if echo $line | grep -q "$tmp"
			then
				foreign_state=`echo $line | sed "s/^Foreign\s\+State:\s\+//g"`
				f_log "$LINENO - foreign_state="$foreign_state
			fi
			
			tmp="^Drive\s\+has\s\+flagged\s\+a.*"
			if echo $line | grep -q "$tmp"
			then
				if [ "$foreign_state" = "Foreign" ]
				then
					/opt/MegaRAID/MegaCli/MegaCli64 -CfgForeign -Import a$enclosure_pos	
					f_log "$LINENO - import Foreign disk !!"
					msg="import Foreign disk !!"
					msg="$msg server_ip:$ip"
					$path/../alert/sms.sh "$msg"
				elif [ -z $group ] #根据group判断是否需要新建虚拟磁�?
				then
					if [ $slot -eq 0 ] ||  [ $slot -eq 1 ] 
					then
						/opt/MegaRAID/MegaCli/MegaCli64 -CfgLdAdd -R1[$enclosure:0,$enclosure:1] WT NORA Direct a$enclosure_pos
						f_log "$LINENO - create new group -R1[$enclosure:0,$enclosure:1]!!!!"
						msg="create new group -R1[$enclosure:0,$enclosure:1]!!"
						msg="$msg server_ip:$ip"
						$path/../alert/sms.sh "$msg"
					else
						/opt/MegaRAID/MegaCli/MegaCli64 -CfgLdAdd -R0[$enclosure:$slot] WT NORA Direct a$enclosure_pos
						f_log "$LINENO - create new group !!"
						msg="create new group slot==$slot,R0!!"	
						msg="$msg server_ip:$ip"
						$path/../alert/sms.sh "$msg"
					fi			
				fi
			
			
			
				enclosure=""
				group=""
				span=""
				arm=""
				enclosure_pos=""
				device_id=""
				foreign_state=""
			fi


		done

	fi
}



f_build_raid;