#! /bin/bash


# ���Ӳ�� ��Ҫ��������

# 1.��ȡ�����ļ�#######################
# 2.���������ļ����м��Ӳ��
	# 1.���uuid�Ƿ�����Ч�� �����Ч����������ļ��Ѿ������� ɾ������ 
		# 1.�鿴uuid�Ƿ����
		# 2.����������Ӳ��mount�Ƿ�����
			# 1.��df������ 2.д�ļ����
				# 1.���ͨ�� �����κβ���
				# 2.��鲻ͨ�� ������mount
					# 1.mount�ɹ��򷢶��� ���������ļ�
					# 2.mountʧ�ܼ���Ƿ�����Ӳ��
						# 1.��ȡ�̷�
						# 2.��ȡmount״̬
						# 3.��ȡ������Ϣ
							# 1.����Ѿ�mount����û��������Ϣ �����д������ýű�, ��ȡ��������
						# 4.��ȡӲ�̷�����Ϣ,���û�з����ͷ��� ��ʽ��
						# 5.��ȡӲ�̸�ʽ��Ϣ,���û�и�ʽ�� ��ʽ��
						# 6.��ȡuuid��Ϣ
						# 7.�鿴uuid�Ƿ��Ѿ�����
					# 3.����uuid�������ļ� �ж�����Ӳ��
						# 1.����Ӳ�̱�ǩ
						# 2.mount
						# 3.������Ӳ��
						# 4.���Ͷ���
					# 4.����uuid�������ļ� �ж�û����Ӳ��
						# 1.��������Ϣд��Ӳ�̴��������ļ�����#######################
						# 2.���Ͷ���
		# 3.������������� 
	# 2.����ǩ�Ƿ񱻸ı� ���иı� ������ ���������ļ� ���ͱ�����Ϣ#######################
	# 3.�鿴Ӳ���Ƿ���Ư�� ����Ѿ�Ư�� ����������ļ� ���ͱ�����Ϣ#######################
	# 4.�鿴�Ƿ����� ���˾ͷ����Ÿ澯
	# 5.���Ӳ��mount�Ƿ�����
		# 1.��df������ 2.д�ļ����
			# 1.���ͨ�� �����κβ���
			# 2.��鲻ͨ�� ������mount
				# 1.mount�ɹ��򷢶��� ���������ļ�
				# 2.mountʧ�ܼ���Ƿ�����Ӳ��
					# 1.��ȡ�̷�
					# 2.��ȡmount״̬
					# 3.��ȡ������Ϣ
						# 1.����Ѿ�mount����û��������Ϣ �����д������ýű�, ��ȡ��������
					# 4.��ȡӲ�̷�����Ϣ,���û�з����ͷ��� ��ʽ��
					# 5.��ȡӲ�̸�ʽ��Ϣ,���û�и�ʽ�� ��ʽ��
					# 6.��ȡuuid��Ϣ
					# 7.�鿴uuid�Ƿ��Ѿ�����
				# 3.����uuid�������ļ� �ж�����Ӳ��
					# 1.����Ӳ�̱�ǩ
					# 2.mount
					# 3.������Ӳ��
					# 4.���Ͷ���
				# 4.����uuid�������ļ� �ж�û����Ӳ��
					# 1.��������Ϣд��Ӳ�̴��������ļ�����#######################
					# 2.���Ͷ���
	# 6.����Ƿ�����Ӳ��
		# 1.��ȡ�̷�
		# 2.��ȡmount״̬
		# 3.��ȡ������Ϣ
			# 1.����Ѿ�mount����û��������Ϣ �����д������ýű�, ��ȡ��������
		# 4.��ȡӲ�̷�����Ϣ,���û�з����ͷ��� ��ʽ��
		# 5.��ȡӲ�̸�ʽ��Ϣ,���û�и�ʽ�� ��ʽ��
		# 6.��ȡuuid��Ϣ
		# 7.����uuid�鿴Ӳ���Ƿ�����Ӳ�� �����Ѿ����� �����Ǵ���Ӳ��
	# 7.������Ӳ��
		# 1.���mount �Ƿ��Ѿ�mount /dataX
		# 2.������� �Ƿ��Ѿ����� /dataX
		# 3.����Ӳ�̱�ǩ
		# 4.mount
		# 5.������Ӳ��
		# 6.���Ͷ���
	# 8.����ȱʧ��Ӳ��#######################
		# 0.��ȡ��Ϣ ����................
		# 1.����Ӳ�̱�ǩ
		# 2.mount
		# 3.������Ӳ�� ɾ��Ӳ�̴��������ļ����������#######################
		# 4.���Ͷ���





source /etc/profile	


#this_shell_name=`basename $0`
#this_shell_path=`dirname $0`
#echo this_shell_path=$this_shell_path

#Ӳ��Ĭ�ϸ�ʽ
df_type=ext4
#��־����
log_level="DEBUG"
#ִ��ģʽ �Ƿ��Ǻ�ִ̨��
#is_silent="false"

#Ӳ�̼�������ļ� ��������
declare -A disk_conf
#Ӳ�̼�������ļ� ȱʧ����
declare -A err_disk_conf
#ϵͳmount�����ļ�
fstab="/etc/fstab"
#�����ļ�·��
conf_path=$this_shell_path/disk_config.txt
err_conf_path=$this_shell_path/err_disk_config.txt




#��ȡ�����ļ� ���������������ļ����б�
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


#��ȡ�����ļ� ���������������ļ����б�
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


#���Ӳ���Ƿ�������� ������������� �޲��˾�������Ӳ��
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
		

		#���uuid�Ƿ�����Ч�� �����Ч����������ļ��Ѿ������� ɾ������ 
		 uuid_flag=`echo $blkid_info | grep $uuid`
		 if [ -z "$uuid_flag" ] 
		 then
			clean_config;
			check_disk_mount;
			disk_status_=$?
			if [ $disk_status_ -eq 0 ]
			then
				#��ȡuuid
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
		
		
		#����ǩ�Ƿ񱻸ı� ���иı� ������
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
		
		
		#�鿴�̷��Ƿ����仯 ����	

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
		
		#�鿴�Ƿ����� ���˾ͷ����Ÿ澯
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

		#�鿴�Ƿ���ʧЧ��Ŀ¼ �������¹���Ӳ�� ��������о�����Ӳ��
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

	
	#���Ӳ��mount״̬ ��д

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



#ɾ��������Ϣ
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

#ɾ��������Ϣ
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



#���������ļ�
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


#���������ļ�
function build_err_config()
{
	f_log "function,build_err_config"
	
	clean_err_config;
	
	f_log "$LINENO - uuid=$uuid,panfu=$panfu,label=$label,type=$type"
	
	f_log "$LINENO - update config file $conf_path, add new disk"
	
	echo $uuid,$panfu,$dirname,$label,$df_type >> $err_conf_path
}



#���Ӳ��mount ��д ������0
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


#���Ӳ��mount 
function check_disk_mount()
{
	#�鿴�Ƿ���ʧЧ��Ŀ¼ �������¹���Ӳ�� ��������о�����Ӳ��

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
		#Ӳ��û����
		f_log "$LINENO - disk status good!!! panfu=$panfu, label=$label,dirname=$dirname, uuid=$uuid"
		return 0;
	fi
	

}


#�����Ӳ��
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

		#�鿴��û��mount��ȥ 
		local tmp=`df -l | grep $panfu`
		if [ "$tmp" ]
		then
			f_log "$LINENO - $panfu is not new disk"
			
			#��û�и�Ӳ�̵�������Ϣ ��
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
		
		#����Ӳ�̵�������Ϣ
		f_log "$LINENO - check $panfu, check mount, check partition, check format ..."
				
		
		#�鿴���Ƿ��Ѿ�����		
		fenqu=`fdisk -l $panfu | grep $fenqu1`

		#�Ѿ�����
		if [ "$fenqu" ] 
		then
			f_log "$LINENO - $panfu has been partitioned"
			
			#�鿴�Ƿ��Ѿ���ʽ��
			gsh=`blkid | grep $fenqu1`
			#�Ѿ���ʽ��
			if [ "$gsh" ]
			then	
				#��ȡuuid
				uuid_=${gsh/*UUID=\"/}
				uuid_=${uuid_/\"*/}

			#û�и�ʽ��
			else
				f_log "$LINENO - format disk $panfu"
				
				#��ʽ��
				mkfs -t $df_type -i 10240 $fenqu1
				
				uuid_=`tune2fs -l $fenqu1 |grep 'UUID'|awk '{print $3}'`
				f_log "$LINENO - find disk $panfu uuid, uuid=$uuid_"
				
			fi	

		else
		#û�з���
			f_log "$LINENO - disk $panfu has no partition yet"
			
			#��Ҫ���� ��ʽ�� ��ӱ�ǩ mount �޸�fstab
			fenqu_fun;
			#��ʽ��
			mkfs -t $df_type -i 10240 $fenqu1
		
			uuid_=`tune2fs -l $fenqu1 |grep 'UUID'|awk '{print $3}'`
			f_log "$LINENO - find disk $panfu uuid, uuid=$uuid_"
			
		fi

		
		f_log "$LINENO - use the disk uuid to find disk info"
		
		get_disk_info_by_uuid_fun;	
		local tmp=$?
		#û������ ������ȱʧ��Ӳ��
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


#����uuid�Լ����� �ж��Ƿ�����Ӳ��    ����0��ʾ����Ӳ�� ����1��ʾ�Ѿ����õ�Ӳ�� ����2��ʾȱʧ���ߴ���Ӳ�� 
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


#������Ӳ��
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


#����
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


#���ͱ�����Ϣ
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




