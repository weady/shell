#! /bin/bash


# 检测硬盘 主要工作流程

# 1.读取配置文件#######################
# 2.根据配置文件进行检查硬盘
	# 1.检测uuid是否是有效的 如果无效则表明配置文件已经过期啦 删除配置 
		# 1.查看uuid是否存在
		# 2.不存在则检测硬盘mount是否正常
			# 1.用df命令检查 2.写文件检查
				# 1.检查通过 不做任何操作
				# 2.检查不通过 则重新mount
					# 1.mount成功则发短信 更新配置文件
					# 2.mount失败检查是否有新硬盘
						# 1.获取盘符
						# 2.获取mount状态
						# 3.获取配置信息
							# 1.如果已经mount但又没有配置信息 则运行创建配置脚本, 读取最新配置
						# 4.获取硬盘分区信息,如果没有分区就分区 格式化
						# 5.获取硬盘格式信息,如果没有格式化 格式化
						# 6.获取uuid信息
						# 7.查看uuid是否已经配置
					# 3.根据uuid与配置文件 判断有新硬盘
						# 1.更新硬盘标签
						# 2.mount
						# 3.配置新硬盘
						# 4.发送短信
					# 4.根据uuid与配置文件 判断没有新硬盘
						# 1.把配置信息写到硬盘错误配置文件里面#######################
						# 2.发送短信
		# 3.正常则更新配置 
	# 2.检查标签是否被改变 如有改变 则修正 更新配置文件 发送报警信息#######################
	# 3.查看硬盘是否发生漂移 如果已经漂移 则更新配置文件 发送报警信息#######################
	# 4.查看是否满了 满了就发短信告警
	# 5.检测硬盘mount是否正常
		# 1.用df命令检查 2.写文件检查
			# 1.检查通过 不做任何操作
			# 2.检查不通过 则重新mount
				# 1.mount成功则发短信 更新配置文件
				# 2.mount失败检查是否有新硬盘
					# 1.获取盘符
					# 2.获取mount状态
					# 3.获取配置信息
						# 1.如果已经mount但又没有配置信息 则运行创建配置脚本, 读取最新配置
					# 4.获取硬盘分区信息,如果没有分区就分区 格式化
					# 5.获取硬盘格式信息,如果没有格式化 格式化
					# 6.获取uuid信息
					# 7.查看uuid是否已经配置
				# 3.根据uuid与配置文件 判断有新硬盘
					# 1.更新硬盘标签
					# 2.mount
					# 3.配置新硬盘
					# 4.发送短信
				# 4.根据uuid与配置文件 判断没有新硬盘
					# 1.把配置信息写到硬盘错误配置文件里面#######################
					# 2.发送短信
	# 6.检查是否有新硬盘
		# 1.获取盘符
		# 2.获取mount状态
		# 3.获取配置信息
			# 1.如果已经mount但又没有配置信息 则运行创建配置脚本, 读取最新配置
		# 4.获取硬盘分区信息,如果没有分区就分区 格式化
		# 5.获取硬盘格式信息,如果没有格式化 格式化
		# 6.获取uuid信息
		# 7.根据uuid查看硬盘是否是新硬盘 或者已经配置 或者是错误硬盘
	# 7.配置新硬盘
		# 1.检查mount 是否已经mount /dataX
		# 2.检查配置 是否已经配置 /dataX
		# 3.更新硬盘标签
		# 4.mount
		# 5.配置新硬盘
		# 6.发送短信
	# 8.配置缺失的硬盘#######################
		# 0.获取信息 更新................
		# 1.更新硬盘标签
		# 2.mount
		# 3.配置新硬盘 删除硬盘错误配置文件里面的配置#######################
		# 4.发送短信





source /etc/profile	


#this_shell_name=`basename $0`
#this_shell_path=`dirname $0`
#echo this_shell_path=$this_shell_path

#硬盘默认格式
df_type=ext4
#日志级别
log_level="DEBUG"
#执行模式 是否是后台执行
#is_silent="false"

#硬盘检测配置文件 正常配置
declare -A disk_conf
#硬盘检测配置文件 缺失配置
declare -A err_disk_conf
#系统mount配置文件
fstab="/etc/fstab"
#配置文件路径
conf_path=$this_shell_path/disk_config.txt
err_conf_path=$this_shell_path/err_disk_config.txt




#读取配置文件 保存配置数据盘文件夹列表
function read_config_fun()
{		
	f_log "$LINENO - function,read_config_fun"
	
	
	local i=0
	
	while read line
	do	
		if [ "$line" ] 
		then
			disk_conf[$i]=$line	
		else
			f_log "$LINENO - null____line_____"			
		
		fi

		let i++
		
	done < $conf_path
	
}


#读取配置文件 保存配置数据盘文件夹列表
function read_err_config_fun()
{		
	f_log "$LINENO - function,read_err_config_fun"
		
	local i=0
	
	while read line
	do	
		if [ "$line" ] 
		then
			err_disk_conf[$i]=$line	
		else
			f_log "$LINENO - null____line_____"			
		
		fi

		let i++
		
	done < $err_conf_path	
}


#检测硬盘是否出问题了 出了问题就修正 修不了就配置新硬盘
function read_current_disk_info_fun()
{
	f_log "$LINENO - function,read_current_disk_info_fun"
	
	local blkid_info=`blkid`
	
	
	for disk in ${disk_conf[@]}
	do	
		f_log "$LINENO - $disk"
		
		disk=${disk//,/ }
		uuid=`echo $disk|awk '{print $1}'`
		old_uuid=$uuid
		old_uuid_status=false
		
		panfu=`echo $disk|awk '{print $2}'`
		dirname=`echo $disk|awk '{print $3}'`
		label=`echo $disk|awk '{print $4}'`
		type=`echo $disk|awk '{print $5}'`		
		status=`df -l | grep $panfu |awk '{print $5}'`
		i_status=`df -li | grep $panfu | awk '{print $5}'`

		f_log "$LINENO - uuid=$uuid,panfu=$panfu,label=$label,type=$type"
		

		#检测uuid是否是有效的 如果无效则表明配置文件已经过期啦 删除配置 
		 uuid_flag=`echo $blkid_info | grep $uuid`
		 if [ -z "$uuid_flag" ] 
		 then
			clean_config;
			check_disk_mount;
			disk_status_=$?
			if [ $disk_status_ -eq 0 ]
			then
				#获取uuid
				uuid=`echo $blkid_info | grep $panfu`
				uuid=${uuid/*UUID=\"/}
				uuid=${uuid/\"*/}
				f_log "$LINENO - change the config, new uuid = $uuid"		
				
				build_config;
			else
				f_log "$LINENO - disk error !! uuid=$uuid,panfu=$panfu,dirname=$dirname,label=$label,type=$type"
				f_log "$LINENO - check next disk !!"
				continue;				
			fi
			
			#return ;
		 fi
		
		
		#检查标签是否被改变 如有改变 则修正
		#if [[ $dirname = /data* ]] || [[ $dirname = /r2 ]]
		if [[ $dirname = /data* ]]
		then
			label_=${dirname/data/d}			
		else
			label_=$dirname
		fi
		
		curr_label=`e2label UUID=$uuid`
		if [[ $curr_label != $label_ ]]
		then
			f_log "$LINENO - update label, curr_label=$curr_label >>to>> label=$label, "
			
			label=$label_
			e2label UUID=$uuid $label

			if [ $? -eq 0 ]
			then
				f_log "$LINENO - update label success!!! uuid=$uuid,panfu=$panfu,dirname=$dirname,label=$label,type=$type"
				f_log "$LINENO - update config file $conf_path"
				
				clean_err_config;
				build_config;
				alert_fun "update label success!!! uuid=$uuid,panfu=$panfu,dirname=$dirname,label=$label,type=$type"
			else
				f_log "$LINENO - update label fail!!! uuid=$uuid,panfu=$panfu,dirname=$dirname,label=$label,type=$type"
				alert_fun "error!! update label fail!!! uuid=$uuid,panfu=$panfu,dirname=$dirname,label=$label,type=$type"
			fi
			
		fi
		
		
		#查看盘符是否发生变化 修正	

		tmp1=`echo $blkid_info | grep $uuid`
		tmp2=`echo $blkid_info | grep $panfu | grep $uuid`
	
		f_log "$LINENO - tmp1=$tmp1"
		f_log "$LINENO - tmp2=$tmp2"


		if [ -n "$tmp1" ] && [ -z "$tmp2" ]
		then		
			f_log "$LINENO - tmp1=$tmp1"
			f_log "$LINENO - tmp2=$tmp2"
					
			new_panfu=`blkid -U $uuid`
			panfu=$new_panfu
			
			f_log "$LINENO - disk name has change update the config file $conf_path"
			alert_fun "warning!!!!disk name has change!!!uuid=$uuid,panfu=$panfu,dirname=$dirname,label=$label,type=$type"
			
			clean_config;
			build_config;
		fi
		
		#查看是否满了 满了就发短信告警
		if [[ $status = %100 ]]
		then
			f_log "$LINENO - Warning!!$panfu:$dirname disk Occupancy is $status!!!"
			alert_fun "Warning!!!$panfu:$dirname disk Occupancy is $status!!"
			
			continue;
		elif [[ $i_status = %100 ]]
		then
			f_log "$LINENO - Warning!!!$panfu:$dirname disk index node Occupancy is $i_status!!"			
			alert_fun "Warning!!!$panfu:$dirname disk index node Occupancy is $i_status!!" 
			
			continue;
		fi

		#查看是否有失效的目录 有则重新挂载硬盘 如果还不行就配新硬盘
		#if [[ $dirname = /r2 || $dirname = /data* ]]
		if [[ $dirname = /data* ]]
		then
			check_disk_mount;		
		fi	
		
	done 
	
	old_uuid=""
	
	
	check_new_disk_fun;
	local tmp=$?	
	if [ $tmp -eq 0 ]
	then
		f_log "$LINENO - it has new disk!!"
		
		config_new_disk_fun;
	elif [ $tmp -eq 2 ]
	then
		f_log "$LINENO - find a lost disk!!"
		
		config_lost_disk_fun;
	fi
}

function config_lost_disk_fun()
{

	dirname=`cat $err_conf_path | grep $uuid | sed 's/,/ /g'| head -1 | awk '{print $3}'`
	label=`cat $err_conf_path | grep $uuid | sed 's/,/ /g' |head -1 |  awk '{print $4}'`
	type=`cat $err_conf_path | grep $uuid | sed 's/,/ /g' |head -1 | awk '{print $5}'`
	panfu=`blkid -U $uuid`
	
	e2label UUID=$uuid $label
	
	f_log "$LINENO - mount new disk!!! panfu=$panfu, label=$label,dirname=$dirname"
	
	mount UUID=$uuid $dirname

	
	#检查硬盘mount状态 读写

	if check_mount_write #success
	then
		f_log "$LINENO - add config to $conf_path"
		
		type=$df_type
		
		old_uuid_status=true
		clean_err_config;
		build_config;
		
		f_log "$LINENO - read config again"
		read_config_fun;
		
		alert_fun "Congratulation to you !! config lost disk success!!! panfu=$panfu, label=$label,dirname=$dirname"	
	fi	
}



#删除配置信息
function clean_config()
{
	f_log "function,clean_config"
	
	f_log "$LINENO - update config file $conf_path, delete disk"
	
	sed -i "/^$uuid/ d" $conf_path
	
	f_log "$LINENO - update config file $fstab, delete disk"
	
	f_log "$LINENO - change the config /etc/fstab"
	temp=${label/\//\\/}
	sed -i "/^LABEL=$temp/ d" $fstab
}

#删除配置信息
function clean_err_config()
{
	f_log "function,clean_err_config"	
	f_log "$LINENO - update config file $err_conf_path, delete disk"	
	cat $err_conf_path
	if [ $old_uuid_status = "true" ] && [ $old_uuid ]
	then
		sed -i "/^$old_uuid/ d" $err_conf_path
		echo "sed -i /^$old_uuid/ d $err_conf_path"
		
	fi

	old_uuid_status=false
	cat $err_conf_path
	
	tmp_dir=${dirname/\//\\/}
	sed -i "/$tmp_dir/ d" $err_conf_path
	cat $err_conf_path
	
	
	sed -i "/^$uuid/ d" $err_conf_path	
	echo "sed -i /^$uuid/ d $err_conf_path"
	cat $err_conf_path
}



#更新配置文件
function build_config()
{
	f_log "function,build_config"
	
	
	clean_config;
	
	
	f_log "$LINENO - uuid=$uuid,panfu=$panfu,label=$label,type=$type"
	
	f_log "$LINENO - update config file $conf_path, add new disk"
	
	echo $uuid,$panfu,$dirname,$label,$df_type >> $conf_path
	
	f_log "$LINENO - update config file $fstab, add new disk"
	
	temp=${label/\//\\/}
	sed -i "/^LABEL=$temp/ d" $fstab
	temp="LABEL=$label     $dirname                  $df_type defaults        1 0"
	echo $temp >> $fstab
}


#更新配置文件
function build_err_config()
{
	f_log "function,build_err_config"
	
	clean_err_config;
	
	f_log "$LINENO - uuid=$uuid,panfu=$panfu,label=$label,type=$type"
	
	f_log "$LINENO - update config file $conf_path, add new disk"
	
	echo $uuid,$panfu,$dirname,$label,$df_type >> $err_conf_path
}



#检查硬盘mount 读写 出错返回0
function check_mount_write()
{
	#sleep 5;
	mount_status=`df -l | grep $dirname`
	echo "disk test" > $dirname/disk_test.txt
	test_=$?
	if [ -z "$mount_status" ] || [ $test_ -ne 0 ]
	then
		return 1;
	else
		return 0;
	fi
}


#检测硬盘mount 
function check_disk_mount()
{
	#查看是否有失效的目录 有则重新挂载硬盘 如果还不行就配新硬盘

	check_mount_write;
	local tmp_stat=$?
	if [ $tmp_stat -eq 1 ]
	then 
		f_log "$LINENO - remove config panfu==$panfu, dir==$dirname, uuid==$uuid"
		clean_config;		
		
		f_log "$LINENO - mount_status=$mount_status,test to write disk=$test_"
		
		f_log "$LINENO - mount disk again"
		
		umount -l $dirname
		ret=`mount $panfu $dirname 2>&1`

		f_log "$LINENO - ret==================$ret"
		
		tmp="^mount:\s\+wrong\s\+fs\s\+type*"
		if echo $ret | grep $tmp
		then 
			f_log "$LINENO - disk type error format disk!!panfu==$panfu, dir==$dirname, uuid==$uuid!!!!!!!!"
			$type=$df_type
			#mkfs -t ext4 -i 10240 -I 128  /dev/sdh1
			mkfs -t $type -i 10240 $panfu
			mount $panfu $dirname
		fi
		
		check_mount_write;
		local tmp_stat=$?
		if [ $tmp_stat -eq 1 ]
		then 
			f_log "$LINENO - mount disk fail"
			
			f_log "$LINENO - umount the bad disk!! cmd=umount -l $dirname !"
			
			umount -l $dirname
				
			check_new_disk_fun;
			
			local flag=$?

			if [ $flag -eq 0 ]
			then
				f_log "$LINENO - have new disk, create label !!"
							
				e2label UUID=$uuid $label
				f_log "$LINENO - mount"
				mount LABEL=$label $dirname
				if [ $? -eq 0 ]
				then						
					build_config;
					old_uuid_status=true
					clean_err_config;
							
					f_log "$LINENO - Congratulation to you !! Add new disk success!!! panfu=$panfu, label=$label,dirname=$dirname"
					alert_fun "Congratulation to you !! Add new disk success!!! panfu=$panfu, label=$label,dirname=$dirname"
					return 0;
				else
					build_err_config;
				
					f_log "Error!!!$panfu:$dirname disk error!!it has new disk but it cat not mount !"
					alert_fun "Error!!!$panfu:$dirname disk error!!it has new disk but it cat not mount !"
					return 1;
				fi				
			else
				build_err_config;
			
				f_log "$LINENO - Error!!!$panfu disk has some problem and it has not new disk to replace"
				alert_fun "Error!!!$panfu:$dirname disk error!!"
				
				return 1;
			fi
		else
			build_config;
			f_log "$LINENO - Congratulation to you !! remount disk success!!! panfu=$panfu, label=$label,dirname=$dirname"
			alert_fun "Congratulation to you !! remount disk success!!! panfu=$panfu, label=$label,dirname=$dirname"
			return 0;
		fi
	else
		#硬盘没问题
		f_log "$LINENO - disk status good!!! panfu=$panfu, label=$label,dirname=$dirname, uuid=$uuid"
		return 0;
	fi
	

}


#检查新硬盘
function check_new_disk_fun()
{
	f_log "$LINENO - function,check_new_disk_fun"
	
	local flag=1
	
	f_log "$LINENO - find new disk"
	
	fdisk -l | grep 'Disk /dev/sd' > $this_shell_path/new_disk.tmp
	while read disk
	do	
		f_log "$LINENO - $disk"
		
		local panfu=`echo $disk|awk '{print $2}'`
		panfu=${panfu/:/}
		fenqu1="$panfu"1

		#查看有没有mount上去 
		local tmp=`df -l | grep $panfu`
		if [ "$tmp" ]
		then
			f_log "$LINENO - $panfu is not new disk"
			
			#有没有该硬盘的配置信息 ？
			f_log "$LINENO - panfu=$panfu"
			f_log "$LINENO - fenqu1=$fenqu1"
			f_log "$LINENO - tmp==$tmp"
			
			is_config=`cat $conf_path | grep $fenqu1`
			is_data_dir=`echo $tmp | grep \/data`
			f_log "$LINENO - is_config=$is_config"
			f_log "$LINENO - is_data_dir=$is_data_dir"
			if [ -z "$is_config" ] && [ "$is_data_dir" ]
			then 
				f_log "$LINENO - this disk has no config, build the config file again!!!!!!!fenqu1=$fenqu1"
				
				if [ $is_silent = "false" ]
				then				
					source $this_shell_path/m_builddisk.sh
				else
					source $this_shell_path/m_builddisk.sh  --nomsg
				fi	

				f_log "$LINENO - read the disk config again!!!!!!!!!!"
				read_config_fun;		
				
				uuid=`tune2fs -l $fenqu1 |grep 'UUID'|awk '{print $3}'`
				
				f_log "$LINENO - delete error config!!!!fenqu1=$fenqu1"
				clean_err_config;

				
			fi

			continue;
		else
			f_log "$LINENO - $panfu is new disk??"
			
		fi
		
		#检查该硬盘的其他信息
		f_log "$LINENO - check $panfu, check mount, check partition, check format ..."
				
		
		#查看其是否已经分区		
		fenqu=`fdisk -l $panfu | grep $fenqu1`

		#已经分区
		if [ "$fenqu" ] 
		then
			f_log "$LINENO - $panfu has been partitioned"
			
			#查看是否已经格式化
			gsh=`blkid | grep $fenqu1`
			#已经格式化
			if [ "$gsh" ]
			then	
				#获取uuid
				uuid_=${gsh/*UUID=\"/}
				uuid_=${uuid_/\"*/}

			#没有格式化
			else
				f_log "$LINENO - format disk $panfu"
				
				#格式化
				mkfs -t $df_type -i 10240 $fenqu1
				
				uuid_=`tune2fs -l $fenqu1 |grep 'UUID'|awk '{print $3}'`
				f_log "$LINENO - find disk $panfu uuid, uuid=$uuid_"
				
			fi	

		else
		#没有分区
			f_log "$LINENO - disk $panfu has no partition yet"
			
			#需要分区 格式化 添加标签 mount 修改fstab
			fenqu_fun;
			#格式化
			mkfs -t $df_type -i 10240 $fenqu1
		
			uuid_=`tune2fs -l $fenqu1 |grep 'UUID'|awk '{print $3}'`
			f_log "$LINENO - find disk $panfu uuid, uuid=$uuid_"
			
		fi

		
		f_log "$LINENO - use the disk uuid to find disk info"
		
		get_disk_info_by_uuid_fun;	
		local tmp=$?
		#没有配置 或者是缺失的硬盘
		if [ $tmp -eq 0 ] || [ $tmp -eq 2 ]
		then
			uuid=$uuid_
			flag=$tmp
			break;
		fi
		
	done < $this_shell_path/new_disk.tmp
	
	rm -rf $this_shell_path/new_disk.tmp
	f_log "$LINENO - flag==$flag"
	
	return $flag;
}


#根据uuid以及配置 判断是否是新硬盘    返回0表示是新硬盘 返回1表示已经配置的硬盘 返回2表示缺失或者错误硬盘 
function get_disk_info_by_uuid_fun()
{
	f_log "$LINENO - function,get_disk_info_by_uuid_fun"
	
	if cat $conf_path | grep $uuid_
	then
		f_log "$LINENO - exist disk config, the disk is the old one"
		return 1;
		
	elif cat $err_conf_path | grep $uuid_
	then
		f_log "$LINENO - error or lost disk config, the disk is the old one"
		return 2;		
	else
		f_log "$LINENO - the disk config is not exist, it is a new disk"
		return 0;	
	fi
	
	# for disk in ${disk_conf[@]}
	# do
		# if [[ $disk = $uuid_* ]]
		# then
			# flag=1
			# f_log "$LINENO - exist disk config, the disk is the old one"
			
			# return 1;				
		# fi	
	# done
	# f_log "$LINENO - the disk config is not exist, it is a new disk"
	
	# return 0;	
}


#配置新硬盘
function config_new_disk_fun()
{	
	f_log "$LINENO - function,config_new_disk_fun"
	

	
	
	local j=1
	while true			
	do
		f_log "$LINENO - check the disk is used or not"
		
		f_log "$LINENO - ${disk_conf[@]}"
		
		if df -l | grep "/data$j$"
		then 
			f_log "$LINENO - /data$j exist"		
			
			echo "disk test" > "/data"$j/disk_test.txt
			test_=$?
			if [ $test_ -ne 0 ]
			then 
				umount -l "/data"$j
				f_log "$LINENO - the disk is fail, umount the disk, umount -l /data$j"
				
				break;
			fi
			
			let j++
			continue;
		fi
		
		f_log "$LINENO - check the disk has config or not"
		
		if echo ${disk_conf[@]} | grep "/data$j$"
		then
			f_log "$LINENO - /data$j exist"
			
			let j++
			continue;
		fi			
		
		break;
	done
		
	f_log "$LINENO - create dir /data$j"
	
	
	mkdir "/data$j"
	label="/d$j"
	dirname="/data$j"
	panfu=`blkid -U $uuid`
	
	f_log "$LINENO - update disk label uuid=$uuid, panfu=$panfu, label=$label,dirname=$dirname"
	echo "e2label UUID=$uuid $label"
	f_log "$LINENO - e2label UUID=$uuid $label"
	
	e2label $panfu $label
	
	e2label UUID=$uuid $label
	
	f_log "$LINENO - mount new disk"
	
	mount UUID=$uuid $dirname
	
	if check_mount_write
	then
		f_log "$LINENO - add config to $conf_path"
		
		type=$df_type
		
		old_uuid_status=true
		clean_err_config;
		
		clean_config;
		build_config;
		
		alert_fun "Congratulation to you !! config disk success!!! panfu=$panfu, label=$label,dirname=$dirname"	
	fi
	
	

}


#分区
function fenqu_fun()
{
	f_log "$LINENO - function,fenqu_fun"
	
	f_log "$LINENO - disk $panfu partition begin"
	
	fdisk $panfu <<EOF
d
n
p
1


w
EOF
	f_log "$LINENO - disk $panfu partition end"
	
}


#发送报警信息
function alert_fun()
{
	f_log "$LINENO - function,alert_fun"
	local flag=0
	msg=$1
	
	ip=`ifconfig |grep "inet addr:"|grep -v "127.0.0.1"|cut -d: -f2|awk '{print $1}'|awk '{print $1}'|head -1`

	msg="$msg server_ip:$ip"
	
	my_date=`date '+%Y-%m-%d %H:%M:%S'`
	
	if [ ! -f $this_shell_path/msg.txt ]
	then
		echo "test message" > $this_shell_path/msg.txt	
	fi
	
	
	while read line_
	do		
		if [[ $line_ = *$msg ]]
		then
			f_log "$LINENO - Repeat the message $msg"	
			flag=1
			break;		
		fi			
	done < $this_shell_path/msg.txt
	
	if [ $flag -eq 0 ]
	then
		if [ $is_silent = "false" ]
		then
			$this_shell_path/../alert/sms.sh "$msg"
			$this_shell_path/../alert/sendmail.sh "$msg"	
		else
			$this_shell_path/../alert/sms.sh "$msg"  --nomsg
			$this_shell_path/../alert/sendmail.sh "$msg"	--nomsg
		fi	
				
		f_log "$LINENO - send message success !! msg=$msg"	
		
		
		msg="$my_date $msg"	
		echo $msg >> $this_shell_path/msg.txt
	fi	
}


read_config_fun;
read_err_config_fun
read_current_disk_info_fun;




