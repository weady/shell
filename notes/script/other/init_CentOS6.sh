#!/bin/bash
#
#by wangdd 2017/08/17
#
#CentOS release 6.4 系统安全和优化脚本,最小化安装
#

#----------------------------------------------------------
#安装必要的服务

function install_base_soft(){
	yum install -y gcc kernel-devel man ntpdate sysstat tcpdump zlib-devel openssl-devel wget nfs-utils cronolog openssh-clients cmake >/dev/null 2>&1 
	
	if [[ $? -eq 0 ]];then
		echo "Yum install basesoft success!"
	else
		echo "Yum install basesoft failed!"
	fi
}


#----------------------------------------------------------
#防火墙优化

function init_firewall(){
	iptables -P INPUT ACCEPT
	iptables -F
	iptables -X
	iptables -Z
	iptables -A INPUT -i lo -j ACCEPT
	iptables -A INPUT -p tcp --dport 22 -j ACCEPT
	iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
	iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
	iptables -A INPUT -p icmp -j ACCEPT
	iptables -P INPUT DROP
	/etc/init.d/iptables save
	service iptables restart

	if [[ $? -eq 0 ]];then
		echo "Firewall initial success!"
	else
		echo "Firewall initial failed!"
	fi
	
}

#----------------------------------------------------------
#停用不必要系统默认服务

function stop_some_service(){
	all_srv_list=$(chkconfig --list | grep 3:on | awk '{print $1}')
	need_start_list="crond sshd iptables network rsyslog mysqld nginx apache"
	echo "$all_srv_list" | while read srv
	do
		tag=$(echo "$need_start_list" | grep "$srv")
		if [[ -z "$tag" ]];then
			echo "Stop $srv service"
			service $srv stop
			chkconfig $srv off
		fi
	done
}

#----------------------------------------------------------
#关闭不必要的用户或者锁定某些用户的登录

function stop_some_user(){
	need_stop_users="adm lp shutdown halt uucp operator games gopher postfix"
	for user in $need_stop_users
	do
		tag=$(id $user)
		if [[ -n "$tag" ]];then
			echo "[ Delete user $user ]"
			userdel -r $user
		fi
	done	
}

function lock_some_user(){
	lock_user_list="xfs news nscd dbus vcsa games nobody avahi haldaemon gopher ftp mailnull pcap mail shutdown halt uucp operator sync adm lp"
	for lock_user in ${lock_user_list}
	do
		passwd -l ${lock_user}
		[[ $? -eq 0 ]] && echo "[ ${lock_user} Lock success ]" || echo "[ ${lock_user} Lock failed ]"
	done
}

#----------------------------------------------------------
#系统内核优化

function optimize_kernel(){
cat>>/etc/sysctl.conf<<EOF
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_max_syn_backlog = 40960
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.ip_local_port_range = 4096 65000
net.core.netdev_max_backlog =  10240
net.core.somaxconn = 2048
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF
/sbin/sysctl -p >/dev/null 2>&1

}

#----------------------------------------------------------
#其他一些系统优化

function optimize_system(){
	echo "[ Start Optimize System ]"
	setenforce 0
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 	
	echo "HISTSIZE=10">>/etc/profile
	echo "export TMOUT=3600" >> /etc/profile
}

#----------------------------------------------------------
#记录用户的操作记录

function record_user_operation(){
tag=$(grep '^#Set History' /etc/profile)
if [[ -z "$tag" ]];then
cat>>/etc/profile<<EOF

#Set History
#
USER_IP=\`who -u am i 2>/dev/null| awk '{print \$NF}'|sed -e 's/[()]//g'\`
if [ "\$USER_IP" = "" ]
then
USER_IP=\`hostname\`
fi
if [ ! -d /usr/local/.history ]
then
mkdir -p /usr/local/.history
chmod 777 /usr/local/.history
fi
if [ ! -d /usr/local/.history/\${LOGNAME} ]
then
mkdir -p /usr/local/.history/\${LOGNAME}
chmod 300 /usr/local/.history/\${LOGNAME}
fi
export HISTSIZE=4096
DT=\`date +"%Y%m%d_%H%M%S"\`
export HISTFILE="/usr/local/.history/\${LOGNAME}/\${USER_IP}_history_\$DT"
chmod 600 /usr/local/.history/\${LOGNAME}/*history* 2>/dev/null
EOF
source /etc/profile
echo "[ Record User Operation Success!! ]"
fi
}


record_user_operation
