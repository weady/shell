#!/bin/bash
#
#------------------------------------------------------------
# Script Author: wangdd
# Description: This script used to init system for kernel 2.6.x and kernel 3.10.x
# Date: 2018/05/23
# Version: v.01
#------------------------------------------------------------
#步骤1 系统安全配置
#步骤2 内核优化
#步骤3 建立内置用户
#步骤4 系统基本配置
#步骤5 安装软件

#------------------------------------------------------------
HOST_NAME=$1
HOST_IP=$(ip addr | grep -A 2 'state.*UP' | grep '\<inet\>' | awk '{print $2}' | awk -F '/' '{if($1) print $1}' | head -n 1)

[[ -z "$HOST_NAME" ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Parameters are empty ]" && exit
[[ -z "$HOST_IP" ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [ERROR] [ Get Host IP Failed ]" && exit

function set_system_users(){
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Configure System User ]"
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Configure System User --> Disable Sepecial User Login System ]"
	DISUSR=`cat /etc/passwd | awk -F: '($3 < 500){print}' | grep -vE "^root|^fcroot|^sync|^shutdown|^halt|^news|^ntp|^sshd" | grep -v '/sbin/nologin' | awk -F: '{print $1}'`
	if [ ! -z $DISUSR ]; then
	    for i in $DISUSR
	    do
	        usermod -s /sbin/nologin $i
	    done
	fi

    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Configure System User --> Configure APP users]"
    groupadd -g 600 usr01 >/dev/null 2>&1
    groupadd -g 800 mwopr >/dev/null 2>&1
    groupadd -g 801 appdeploy >/dev/null 2>&1
    useradd -u 800 -g mwopr -G usr01 -d /home/mwopr mwopr >/dev/null 2>&1
    useradd -u 801 -g mwopr -G usr01 -d /home/appdeploy appdeploy >/dev/null 2>&1
    # load jdk path
    source /home/mwopr/.bash_profile 
    if [ `grep -c "mwopr" /etc/passwd` -eq 1 ]; then
        echo "xxx" | passwd mwopr --stdin 1>/dev/null
        echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Configure System User --> Configure APP users --> User mwopr Is Created ]" 
    else
        echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Starting Configure System User --> Configure APP users --> User mwopr Is Not Created ]"
    fi
 
    if [ `grep -c "appdeploy" /etc/passwd` -eq 1 ]; then
        echo "xxxxxx" | passwd appdeploy --stdin 1>/dev/null
        echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Configure System User --> Configure APP users --> User appdeploy Is Created ]"
    else
        echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Starting Configure System User --> Configure APP users --> User appdeploy Is Not Created ]"
    fi
    
    if [ `grep -c "^mwopr" /etc/cron.allow` -eq 0 ]; then
        echo "mwopr" >> /etc/cron.allow
    else
        sed -i '/^mwopr/c\mwopr' /etc/cron.allow
    fi
    
	 
	[[ ! -d "/app" ]]  && mkdir -p /app

cat << END01 >> /etc/sudoers


# For mwopr
mwopr   ALL=(ALL) NOPASSWD:     /usr/sbin/tcpdump,/bin/netstat,/bin/chown,/bin/chmod,/usr/bin/yum,/usr/bin/make,/bin/ln,/bin/mkdir,/bin/cp,/sbin/chkconfig
mwopr   ALL=(ALL) NOPASSWD:     /app/haproxy/sbin/haproxy,/etc/init.d/keepalived,/app/haproxy/stopHaproxy.sh,/app/haproxy/startHaproxy.sh
mwopr   ALL=(ALL) NOPASSWD:     /usr/bin/vim /etc/keepalived/*


# For appdeploy
Defaults:appdeploy   runas_default=mwopr
Defaults        always_set_home
appdeploy       ALL=(ALL)   NOPASSWD:/bin/netstat,/app/jdk1.8.0_65/bin/jstack,/app/jdk1.8.0_65/bin/jmap,/app/jdk1.8.0_65/bin/jstat
appdeploy       ALL=(mwopr) NOPASSWD:/app/jboss/jboss-as/bin/*.sh,/app/tomcat/bin/*.sh,/app/spring-boot/bin/*.sh

END01

}


function set_system_security(){
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security ]"
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Disable Selinux ]"
	if [ `grep -c "^SELINUX=" /etc/selinux/config` -eq 0 ]; then
	    echo "SELINUX=disabled" >> /etc/selinux/config
	else
	    sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config
	fi

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Configure Sudo Not Require TTY ]"
	sed -i '/^Defaults    requiretty/c\#Defaults    requiretty' /etc/sudoers

	if [ `grep -c "^Defaults    logfile" /etc/sudoers` -eq 0 ]; then
	    echo 'Defaults    logfile=/var/log/sudo.log' >> /etc/sudoers
	else
	    echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Sodu logfile Configed ]"
	fi

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Disable Crontab Send Mail To Root ]"
	sed -i '/^MAILTO=/c\MAILTO=""' /etc/crontab
	if [[ `uname -a | grep -c '2.6'` -ge 1 ]];then
		/etc/init.d/crond reload >/dev/null 2>&1
	else
	    systemctl enable crond.service >/dev/null 2>&1
	    systemctl start crond.service >/dev/null 2>&1
	fi

echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Configure Login Warning Message ]" 
cat << END02 > /etc/motd
**********************************************************************************************************************************************
Warning: These facilities are solely for the use of authorized employees or agents of the Company,its subsidiaries and affiliates. 
Unauthorized use is prohibited and subject to criminal and civil penalties! 
Individuals using this computer system are subject to having all of their activities on this system monitored and recorded by IT security team.
**********************************************************************************************************************************************
警告：这些设施仅供授权的员工或公司代理，其分支机构和子公司使用。禁止并受到刑事和民事处罚的未经授权使用！
使用此计算机系统个人的所有的活动都会受到IT信息安全团队的监控和记录。
END02

	if [[ `uname -a | grep -c '2.6'` -eq 1 ]];then
	    sed -i '/^id:/c\id:3:initdefault:' /etc/inittab
	    sed -i '/^SINGLE=/c\SINGLE=\/sbin\/sulogin' /etc/sysconfig/init
	    sed -i 's/^start/#start/g;s/^exec/#exec/g' /etc/init/control-alt-delete.conf
	fi

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Configure Login Timeout 1800 and Umask 022 ]"

	if [ `grep -c "HISTTIMEFORMAT" /etc/profile` -eq 0 ]; then
	    echo 'LOGIP=`who -u am i 2>/dev/null | awk '"'{print \$NF}'"' | sed -e '"'s/[()]//g'"'`' >> /etc/profile
	    echo 'export HISTTIMEFORMAT="%F %T ${LOGIP} `whoami` "' >> /etc/profile
	else
	    sed -i '/LOGIP=/c\LOGIP=`who -u am i 2>/dev/null | awk '"'{print \$NF}'"' | sed -e '"'s/[()]//g'"'`' /etc/profile
	    sed -i '/HISTTIMEFORMAT/c\export HISTTIMEFORMAT="%F %T ${LOGIP} `whoami` "' /etc/profile
	fi

	if [ `grep -c "TMOUT" /etc/profile` -eq 0 ]; then
	    echo -e "TMOUT=1800\nreadonly TMOUT\nexport TMOUT" >> /etc/profile
	else
	    sed -i '/TMOUT=/c\TMOUT=1800' /etc/profile
	    sed -i '/readonly TMOUT/c\readonly TMOUT' /etc/profile
	    sed -i '/export TMOUT/c\export TMOUT' /etc/profile
	fi

	if [ `grep -c "^umask" /etc/profile` -eq 0 ]; then
	    echo "umask 022" >> /etc/profile
	else
	    sed -i '/umask/c\umask 022' /etc/profile
	fi

. /etc/profile

if [ ! -f /etc/profile.d/ps1.sh ]; then
cat << END03 > /etc/profile.d/ps1.sh
if [ "\`whoami\`" = "root" ];then
        export PS1="[\$USER@\`hostname\`:"'\$PWD]#'
else
        export PS1="[\$USER@\`hostname\`:"'\$PWD]\$'
fi
END03

chmod +x /etc/profile.d/ps1.sh
fi

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Configure SSH And Disable Root Login From Remote ]"

	if [ `grep -c "PermitRootLogin" /etc/ssh/sshd_config` -eq 0 ]; then
	    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
	else
	    sed -i '/PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
	fi

	if [ `grep -c "UseDNS" /etc/ssh/sshd_config` -eq 0 ]; then
	    echo "UseDNS no" >> /etc/ssh/sshd_config
	else
	    sed -i '/UseDNS/c\UseDNS no' /etc/ssh/sshd_config
	fi

	if [ `grep -c "GSSAPIAuthentication" /etc/ssh/sshd_config` -eq 0 ]; then
	    echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config
	else
	    sed -i '/^GSSAPIAuthentication/c\GSSAPIAuthentication no' /etc/ssh/sshd_config
	fi

	if [[ `uname -a | grep -c '2.6' ` -eq 1 ]];then
		/etc/init.d/sshd reload >/dev/null 2>&1
	else
		systemctl restart sshd.service >/dev/null 2>&1
	fi

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Contral The Power For Cron and At ]"
	echo -e "root\nmwopr" > /etc/cron.allow
	echo "root" > /etc/at.allow

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Configure The Strategy of Password ]"

	if [ `grep -cE "^PASS_MIN_LEN|^PASS_WARN_AGE" /etc/login.defs` -eq 0 ]; then
	    echo -e "PASS_MIN_LEN   10\nPASS_WARN_AGE   7" >> /etc/login.defs
	else
	    sed -i '/^PASS_MIN_LEN/c\PASS_MIN_LEN   10' /etc/login.defs
	    sed -i '/^PASS_WARN_AGE/c\PASS_WARN_AGE   7' /etc/login.defs
	fi

cat > /etc/pam.d/system-auth << END04
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
auth        sufficient    pam_fprintd.so
auth        sufficient    pam_unix.so nullok try_first_pass
auth        requisite     pam_succeed_if.so uid >= 500 quiet
auth        required      pam_tally2.so even_deny_root root_unlock_time=1800 deny=5 unlock_time=1800
auth        required      pam_deny.so

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 500 quiet
account     required      pam_permit.so

password    requisite     pam_cracklib.so try_first_pass retry=5 type= minclass=3
password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok remember=4
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
END04

	sed -i '/pam_access.so/d' /etc/pam.d/crond

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Configure The Permissions of /var/log ]"
	find /var/log/ -type f -exec chmod u-x,g-x,o-wx {} \;

	auflag=`grep "^authpriv.*" /etc/rsyslog.conf | awk '{print $NF}'`
	if [ -z $auflag ]; then
	    echo "authpriv.*    /var/log/secure" >> /etc/rsyslog.conf
	fi

	if [ "$auflag" != "/var/log/secure" ]; then
	    sed -i '/^authpriv.*/c\authpriv.*    \/var\/log\/secure' /etc/rsyslog.conf
	fi

	if [[ `uname -a | grep -c '2.6' ` -eq 1 ]];then
		/etc/init.d/rsyslog restart >/dev/null 2>&1
	else
		systemctl restart rsyslog.service >/dev/null 2>&1
	fi

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Configure Log For Root In Login ]"
	[[ ! -d /root/bin ]] && mkdir -p /root/bin

cat > /root/bin/rtrace.sh << END05
#!/bin/bash
umask 277
LOGDIR=/root/slogs
[ ! -d \${LOGDIR} ] && /bin/mkdir -p -m 500 \${LOGDIR}
chmod 600 \${LOGDIR}/*.log 2>/dev/null

waistr=\`/usr/bin/who am i | awk '{print \$2"!"\$6"!"\$1}'\`
U_TTY=\`echo \${waistr} | awk -F! '{print \$1}'\`
LOGFROM=\`echo \${waistr} | awk -F! '{print \$2}'\`
LOGUSER=\`echo \${waistr} | awk -F! '{print \$NF}'\`
[ -z \${LOGUSER} ] && LOGUSER=\`/usr/bin/whoami\`

echo \`date +%Y%m%d%H%M%S\`:\${LOGUSER}" -> "\`/bin/basename \$HOME\`:\${LOGFROM} >>\${LOGDIR}/loginfo.trc

echo "**************************************************************************"
echo "*                                                                        *"
echo "*  Attention: Auditing process will report your every action!            *"
echo "*  Warning: Don't delete any files in directory \${LOGDIR}!             *"
echo "*                                                                        *"
echo "*                                      --xxxxxx COMPANY OF CHINA,LTD.     *"
echo "**************************************************************************"

if [[ -n \${U_TTY} ]]
then
    UTTY=\`echo \${U_TTY} | sed 's/\//-/'\`
    [ -d \${LOGDIR} ] && exec script \${LOGDIR}/\`date +%F_%T\`\${UTTY}\${LOGUSER}.log||/bin/bash
fi
END05

	for i in `grep ":x:0:" /etc/passwd | awk -F: '{print $6}'`
	do
	    sed -i '/\/root\/bin\/rtrace.sh/d' $i/.bash_profile
	    echo '[ -x /root/bin/rtrace.sh ] && exec /root/bin/rtrace.sh' >> $i/.bash_profile
	done
	chown root:root /root/bin/rtrace.sh
	chmod 500 /root/bin/rtrace.sh

	echo "options ipv6 disable=1" > /etc/modprobe.d/ipv6.conf
	sed -i '/net.ipv6.conf.all.disable_ipv6/d;/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
	echo -e "net.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Security --> Stop Some Default Service ]"

	if [[ `uname -a | grep -c '2.6'` -ge 1 ]];then
		for i in chargen chargen-udp cups-lpd cups daytime daytime-udp eklogin finger gssftp imap imaps ipop2 ipop3 krb5-telnet klogin ktalk ntalk pop3s rexec rlogin rsh rsync sendmail postfix servers services sgi_fam talk tftp  vsftpd wu-ftpd apmd canna FreeWnn gpm hpoj innd irda isdn kdcrotate lvs mars-nwe oki4daemon privoxy rstatd rusersd rwalld rwhod spamassassin wine xfs nfs nfslock autofs ypbind ypserv ypasswdd smb netfs lpd apache httpd tux named postgresql webmin squid ip6tables iptables pcmcia bluetooth mDNSResponder avahi-dnsconfd
		do
    		if [ -f /etc/init.d/$i ]; then
        		/etc/init.d/$i stop >/dev/null 2>&1
        		chkconfig $i off
    		fi
		done
	else
		for svr in postfix.service atd.service NetworkManager.service firewalld.service
		do
			systemctl disable $svr >/dev/null 2>&1
			systemctl stop $svr >/dev/null 2>&1
		done
	fi

}

#5.内核参数优化
function set_kernel_info(){
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Optimize Kernel ]"
	modprobe bridge
	#kernel.sysrq = 1
	if [ `grep -c "^kernel.sysrq" /etc/sysctl.conf` -eq 0 ]; then
	    echo "kernel.sysrq = 1" >> /etc/sysctl.conf
	else
	    sed -i '/^kernel.sysrq/c\kernel.sysrq = 1' /etc/sysctl.conf
	fi
	#kernel.pid_max = 131072
	if [ `grep -c "^kernel.pid_max" /etc/sysctl.conf` -eq 0 ]; then
	    echo "kernel.pid_max = 131072" >> /etc/sysctl.conf
	else
	    sed -i '/^kernel.pid_max/c\kernel.pid_max = 131072' /etc/sysctl.conf
	fi
	#net.ipv4.ip_local_port_range = 10000 65000
	if [ `grep -c "^net.ipv4.ip_local_port_range" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.ip_local_port_range = 10000 65000" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.ip_local_port_range/c\net.ipv4.ip_local_port_range = 10000 65000' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_keepalive_time = 1200
	if [ `grep -c "^net.ipv4.tcp_keepalive_time" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_keepalive_time = 1200" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_keepalive_time/c\net.ipv4.tcp_keepalive_time = 1200' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_fin_timeout = 30
	if [ `grep -c "^net.ipv4.tcp_fin_timeout" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_fin_timeout/c\net.ipv4.tcp_fin_timeout = 30' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_syncookies = 1
	if [ `grep -c "^net.ipv4.tcp_syncookies" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_syncookies/c\net.ipv4.tcp_syncookies = 1' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_tw_reuse = 1
	if [ `grep -c "^net.ipv4.tcp_tw_reuse" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_tw_reuse/c\net.ipv4.tcp_tw_reuse = 1' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_tw_recycle = 1
	if [ `grep -c "^net.ipv4.tcp_tw_recycle" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_tw_recycle/c\net.ipv4.tcp_tw_recycle = 1' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_retries2 = 5
	if [ `grep -c "^net.ipv4.tcp_retries2" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_retries2 = 5" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_retries2/c\net.ipv4.tcp_retries2 = 5' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_max_syn_backlog = 8192
	if [ `grep -c "^net.ipv4.tcp_max_syn_backlog" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_max_syn_backlog = 8192" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_max_syn_backlog/c\net.ipv4.tcp_max_syn_backlog = 8192' /etc/sysctl.conf
	fi
	#net.ipv4.tcp_max_tw_buckets = 5000
	if [ `grep -c "^net.ipv4.tcp_max_tw_buckets" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf
	else
	    sed -i '/^net.ipv4.tcp_max_tw_buckets/c\net.ipv4.tcp_max_tw_buckets = 5000' /etc/sysctl.conf
	fi
	#net.core.rmem_default = 1048576
	if [ `grep -c "^net.core.rmem_default" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.core.rmem_default = 1048576" >> /etc/sysctl.conf
	else
	    sed -i '/^net.core.rmem_default/c\net.core.rmem_default = 1048576' /etc/sysctl.conf
	fi
	#net.core.rmem_max = 1048576
	if [ `grep -c "^net.core.rmem_max" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.core.rmem_max = 1048576" >> /etc/sysctl.conf
	else
	    sed -i '/^net.core.rmem_max/c\net.core.rmem_max = 1048576' /etc/sysctl.conf
	fi
	#net.core.wmem_default = 262144
	if [ `grep -c "^net.core.wmem_default" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.core.wmem_default = 262144" >> /etc/sysctl.conf
	else
	    sed -i '/^net.core.wmem_default/c\net.core.wmem_default = 262144' /etc/sysctl.conf
	fi
	#net.core.wmem_max = 262144
	if [ `grep -c "^net.core.wmem_max" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.core.wmem_max = 262144" >> /etc/sysctl.conf
	else
	    sed -i '/^net.core.wmem_max/c\net.core.wmem_max = 262144' /etc/sysctl.conf
	fi
	#net.core.somaxconn = 1024
	if [ `grep -c "^net.core.somaxconn" /etc/sysctl.conf` -eq 0 ]; then
	    echo "net.core.somaxconn = 1024" >> /etc/sysctl.conf
	else
	    sed -i '/^net.core.somaxconn/c\net.core.somaxconn = 1024' /etc/sysctl.conf
	fi


	#*    soft    nproc    65536
	if [ `grep -c "*    soft    nproc" /etc/security/limits.conf` -eq 0 ]; then
	    echo "*    soft    nproc    65536" >> /etc/security/limits.conf
	else
	    sed -i '/*    soft    nproc/c\*    soft    nproc    65536' /etc/security/limits.conf
	fi
	#*    hard    nproc    65536
	if [ `grep -c "*    hard    nproc" /etc/security/limits.conf` -eq 0 ]; then
	    echo "*    hard    nproc    65536" >> /etc/security/limits.conf
	else
	    sed -i '/*    hard    nproc/c\*    hard    nproc    65536' /etc/security/limits.conf
	fi
	#*    soft    nofile    131072
	if [ `grep -c "*    soft    nofile" /etc/security/limits.conf` -eq 0 ]; then
	    echo "*    soft    nofile    131072" >> /etc/security/limits.conf
	else
	    sed -i '/*    soft    nofile/c\*    soft    nofile    131072' /etc/security/limits.conf
	fi
	#*    hard    nofile    131072
	if [ `grep -c "*    hard    nofile" /etc/security/limits.conf` -eq 0 ]; then
	    echo "*    hard    nofile    131072" >> /etc/security/limits.conf
	else
	    sed -i '/*    hard    nofile/c\*    hard    nofile    131072' /etc/security/limits.conf
	fi
	#*    soft    nproc    65536
	if [[ `uname -a | grep -c 3.10` -gt 0 ]];then
		if [ `grep -c "*    soft    nproc" /etc/security/limits.d/20-nproc.conf` -eq 0 ]; then
		    echo "*    soft    nproc    65536" >> /etc/security/limits.d/90-nproc.conf
		else
		    sed -i '/*    soft    nproc/c\*    soft    nproc    65536' /etc/security/limits.d/20-nproc.conf
		fi
			

	else
		if [ `grep -c "*    soft    nproc" /etc/security/limits.d/90-nproc.conf` -eq 0 ]; then
		    echo "*    soft    nproc    65536" >> /etc/security/limits.d/90-nproc.conf
		else
		    sed -i '/*    soft    nproc/c\*    soft    nproc    65536' /etc/security/limits.d/90-nproc.conf
		fi
	fi

	sysctl -p > /dev/null 2>&1

	fsmax=`sysctl -a | grep 'fs.file-max' | awk '{print $NF}'`

	if [ "$fsmax" -lt "6553600" ]; then
	        if [ `grep -c "fs.file-max" /etc/sysctl.conf` -eq 0 ]; then
	            echo "fs.file-max = 6553600" >>  /etc/sysctl.conf && sysctl -p 2>/dev/null 1>/dev/null
	        else
	            sed -i '/^fs.file-max/c\fs.file-max = 6553600' /etc/sysctl.conf && sysctl -p 2>/dev/null 1>/dev/null
	        fi
	else
	    sed -i "/^fs.file-max/c\fs.file-max = $fsmax" /etc/sysctl.conf && sysctl -p 2>/dev/null 1>/dev/null
	fi

}

#6.yum 源配置 基本模块安装 域名配置 ntp配置
function set_system_info(){

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Configure The Domain Name For Host ]"
	interface_name=$(ip addr | grep 'state.*UP' | awk '{print $2}' | tr -d ':')
	for line in $interface_name
	do
		inter_file="/etc/sysconfig/network-scripts/ifcfg-${interface_name}"
		dns_tag=$(grep 'DNS1' $inter_file 2>/dev/null| awk -F'=' '{print $2}' | wc -l)
		if [[ -f $inter_file && $dns_tag -ge 1 ]];then

			if [[ $HOST_NAME =~ .*yun.* ]]; then
        			sed -i 's/DNS1=.*/DNS1=111.111.112.70/' $inter_file
        			sed -i 's/DNS2=.*/DNS2=111.111.24.1/' $inter_file
			elif [[ $HOST_NAME =~ .*gray.* ]]; then
        			sed -i 's/DNS1=.*/DNS1=111.111.66.100/' $inter_file
        			sed -i 's/DNS2=.*/DNS2=111.111.243.31/' $inter_file
			else
        			sed -i 's/DNS1=.*/DNS1=111.111.24.1/' $inter_file
        			sed -i 's/DNS2=.*/DNS2=111.111.243.21/' $inter_file
			fi
		else
                        if [[ $HOST_NAME =~ .*yun.* ]]; then
				[[ `grep -c '111.111.112.70' /etc/resolv.conf` -eq 0 ]] && echo "nameserver 111.111.112.70" >>/etc/resolv.conf
				[[ `grep -c '111.111.24.1' /etc/resolv.conf` -eq 0 ]] && echo "nameserver 111.111.24.1" >>/etc/resolv.conf
                        elif [[ $HOST_NAME =~ .*gray.* ]]; then
				[[ `grep -c '111.111.66.100' /etc/resolv.conf` -eq 0 ]] && echo "nameserver 111.111.66.100" >>/etc/resolv.conf
				[[ `grep -c '111.111.243.31' /etc/resolv.conf` -eq 0 ]] && echo "nameserver 111.111.243.31" >>/etc/resolv.conf
			else
				[[ `grep -c '111.111.24.1' /etc/resolv.conf` -eq 0 ]] && echo "nameserver 111.111.24.1" >>/etc/resolv.conf
				[[ `grep -c '111.111.243.21' /etc/resolv.conf` -eq 0 ]] && echo "nameserver 111.111.243.21" >>/etc/resolv.conf
				
			fi
		fi
	done

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Configure Yum ]"
	wget -P /usr/lib64/ ftp://111.111.72.10/lib/connect_hack.so &>/dev/null
	rm -rf /etc/yum.repos.d/*
	if [[ `uname -a | grep -c '2.6'` -ge 1 ]];then
		wget ftp://111.111.72.xx/repo/centos6.repo -P /etc/yum.repos.d/ >/dev/null 2>&1
		[[ $? -eq 0 ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Configure Yum --> Deploy Yum Success ]" || echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [ERROR] [ Configure System Info --> Configure Yum --> Deploy Yum Failed ]"
	else
		wget ftp://111.111.72.10/repo/centos7.repo -P /etc/yum.repos.d/ >/dev/null 2>&1
		[[ $? -eq 0 ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Configure Yum --> Deploy Yum Success ]" || echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [ERROR] [ Configure System Info --> Configure Yum --> Deploy Yum Failed ]"
	fi
	yum clean all >/dev/null 2>&1
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Yum Install Some tools ]"
	yum -y install moosefs* libselinux-python telnet nc strace apr tree lrzsz vim iotop net-tools >/dev/null 2>&1
	[[ $? -eq 0 ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Yum Install Some Tools Success ]" || echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Configure System Info --> Yum Install Some Tools Success Failed ]"

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Configure hostname ]"
	if [[ `uname -a | grep -c '2.6'` -ge 1 ]];then
		sed -i "s/HOSTNAME=.*/HOSTNAME=$HOST_NAME/" /etc/sysconfig/network
	else
		echo "$HOST_NAME" >/etc/hostname
	fi
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Configure /etc/hosts File ]"
	hostname $HOST_NAME >/dev/null 2>&1
cat > /etc/hosts << END06
127.0.0.1    localhost    localhost.localdomain
$HOST_IP	$HOST_NAME
END06


	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Configure The Server of NTP ]"
cat > /etc/ntp.conf << END07
server  ntp.xxx.com true
server  ntp01.int.sfdc.com.cn
server  ntp02.int.sfdc.com.cn
driftfile  /var/lib/ntp/drift
keys  /etc/ntp/keys
END07

	ntpdate ntp.xxxxxx.com 2>&1 > /dev/null
	if [ $? -eq 0 ]; then
    		echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure System Info --> Time Update From ntp.xxxxxx.com Successful ]"
	else
    		echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Configure System Info --> Time Update From ntp.xxxxxx.com Failed ]"
	fi
	hwclock -w >/dev/null 2>&1

	if [[ `uname -a | grep -c 3.10` -ge 1 ]];then
        systemctl enable ntpd.service >/dev/null 2>&1
        systemctl restart ntpd.service >/dev/null 2>&1
	else
        chkconfig ntpd on >/dev/null 2>&1
        /etc/init.d/ntpd restart >/dev/null 2>&1
	fi

}

#7.基本软件安装
function install_base_soft(){
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent ]"
	if [[ `uname -a | grep -c '2.6'` -ge 1 ]]; then
		if [[ $HOST_NAME =~ .*yun.* || $HOST_NAME =~ .*esn.* ]]; then
			echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Deploy The Area of ESN or Tencent-yun ]"
			rpm -ih ftp://111.111.72.10/soft/proxy-zabbix-agent-3.0.2-1.x86_64.rpm >/dev/null 2>&1
			[[ $? -eq 0 ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Install Zabbix Agent Success ]" || echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Starting Install Zabbix Agent --> Install Zabbix Agent Failed ]"
		elif [[ $HOST_NAME =~ .*dcn.* || $HOST_NAME =~ .*gray.* || $HOST_NAME =~ .*mysql.* ]];then
			echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Deploy The Area of DCN or Gray ]"
			rpm -ih ftp://111.111.72.10/soft/zabbix-agent-3.0.2-1.x86_64.rpm >/dev/null 2>&1
			[[ $? -eq 0 ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Install Zabbix Agent Success ]" || echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Starting Install Zabbix Agent --> Install Zabbix Agent Failed ]\n"
		fi
			chkconfig --add zabbix_agentd >/dev/null 2>&1
			chkconfig --level 35 zabbix_agentd on >/dev/null 2>&1
	else
		if [[ $HOST_NAME =~ .*yun.* || $HOST_NAME =~ .*esn.* ]]; then
			echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Deploy The Area of ESN or Tencent-yun ]"
			[[ -d "/app" ]] && mkdir /app >/dev/null 2>&1
			wget ftp://111.111.72.10/soft/zabbix_agent.7.tar.gz -P /app >/dev/null 2>&1
			tar xf /app/zabbix_agent.7.tar.gz -C /app >/dev/null 2>&1
			flag=`grep -c zabbix /etc/passwd`
    			if [ "$flag" -eq 0 ]; then
        			useradd -M -s /sbin/noglogin zabbix >/dev/null 2>&1
				chown -R zabbix.zabbix /app/zabbix_agent
    			fi
			\cp /app/zabbix_agent/zabbix_agentd /etc/init.d/
			sed -i 's/ServerActive=.*/ServerActive=111.111.72.8/' /app/zabbix_agent/etc/zabbix_agentd.conf
			sed -i 's/Server=.*/Server=111.111.72.8/' /app/zabbix_agent/etc/zabbix_agentd.conf
			/app/zabbix_agent/zabbix_agentd start >/dev/null 2>&1
			[[ $? -eq 0 ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Install Zabbix Agent Success ]" || echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Starting Install Zabbix Agent --> Install Zabbix Agent Failed ]"
			[[ -f "/app/zabbix_agent.7.tar.gz" ]] && rm -f /app/zabbix_agent.7.tar.gz

		elif [[ $HOST_NAME =~ .*dcn.* || $HOST_NAME =~ .*gray.* || $HOST_NAME =~ .*mysql.* ]];then
			echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Deploy The Area of DCN or Gray ]"
			[[ -d "/app" ]] && mkdir /app >/dev/null 2>&1
                        wget ftp://111.111.72.10/soft/zabbix_agent.7.tar.gz -P /app >/dev/null 2>&1
                        tar xf /app/zabbix_agent.7.tar.gz -C /app >/dev/null 2>&1
                        flag=`grep -c zabbix /etc/passwd`
                        if [ "$flag" -eq 0 ]; then
                                useradd -M -s /sbin/noglogin zabbix >/dev/null 2>&1
                                chown -R zabbix.zabbix /app/zabbix_agent
                        fi
                        \cp /app/zabbix_agent/zabbix_agentd /etc/init.d/
                        /app/zabbix_agent/zabbix_agentd start >/dev/null 2>&1

			[[ $? -eq 0 ]] && echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install Zabbix Agent --> Install Zabbix Agent Success ]" || echo -e "[ `date '+%Y-%m-%d %H:%M:%S'` ] [\033[31mERROR\033[0m] [ Starting Install Zabbix Agent --> Install Zabbix Agent Failed ]"
			[[ -f "/app/zabbix_agent.7.tar.gz" ]] && rm -f /app/zabbix_agent.7.tar.gz
		fi
		[[ `grep -c 'zabbix' /etc/rc.d/rc.local` -eq 0 ]] && echo "/app/zabbix_agent/zabbix_agentd start" >> /etc/rc.d/rc.local
		chmod +x /etc/rc.d/rc.local >/dev/null 2>&1
	fi

	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Install JDK Soft,Version 1.8.0_65 ]"

    wget ftp://111.111.72.10/soft/jdk-8u65-linux-x64.tar.gz -P /app >/dev/null 2>&1
    tar -xzf /app/jdk-8u65-linux-x64.tar.gz -C /app
    JAVA_HOME=`alternatives --display java | grep "link currently" | awk '{print $NF}' | sed -e 's/\(.*\)\/bin\/java$/\1/g'`
    
    if [ "$JAVA_HOME" == "/app/jdk1.8.0_65"  ]; then
        echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ jdk1.8.0_65 already exits. Nothing to do ]" 
    else
	
        alternatives --install /usr/bin/java java /app/jdk1.8.0_65/bin/java 1800201 >/dev/null 2>&1
        alternatives --install /usr/bin/javac javac /app/jdk1.8.0_65/bin/javac 1800201 >/dev/null 2>&1
        num1=`echo "" | alternatives --config java | grep "/app/jdk1.8.0_65" | awk '{print $2}'`
        echo -e "$num1\n" | alternatives --config java >/dev/null 2>&1
        num2=`echo "" | alternatives --config javac | grep "/app/jdk1.8.0_65" | awk '{print $2}'`
        echo -e "$num2\n" | alternatives --config javac >/dev/null 2>&1
	[[ -f "/app/jdk-8u65-linux-x64.tar.gz" ]] && rm -f /app/jdk-8u65-linux-x64.tar.gz
    fi
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Download Default Scripts ]"
	[[ ! -d "/app/scripts" ]] && mkdir /app/scripts
	wget ftp://111.111.72.10/scripts/default_script/* -P /app/scripts/ >/dev/null 2>&1

    	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Configure /etc/profile ]"
if [[ `grep -c '/app/jdk1.8.0_65/bin' /home/mwopr/.bash_profile` -eq 0 ]];then

cat >> /home/mwopr/.bash_profile << END08
JAVA_HOME=/app/jdk1.8.0_65
CLASS_PATH=.:/app/jdk1.8.0_65/lib/dt.jar:/app/jdk1.8.0_65/lib/tools.jar
PATH=/app/jdk1.8.0_65/bin:$PATH
export JAVA_HOME CLASS_PATH PATH
END08

fi

if [[ `grep -c '/app/jdk1.8.0_65/bin' /etc/profile` -eq 0 ]];then
cat >> /etc/profile << END09
JAVA_HOME=/app/jdk1.8.0_65
CLASS_PATH=.:/app/jdk1.8.0_65/lib/dt.jar:/app/jdk1.8.0_65/lib/tools.jar
PATH=/app/jdk1.8.0_65/bin:$PATH
export JAVA_HOME CLASS_PATH PATH
END09

fi


    /bin/chown -R mwopr.mwopr /app
    /bin/chown -R zabbix.zabbix /app/zabbix_agent 
    /bin/chmod -R 755 /app
}


#主函数
function main(){
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Starting Init System,Please Warning.... ]"
	sleep 1
	if [ -f /etc/init.d/functions ]; then
	    . /etc/init.d/functions
	elif [ -f /etc/rc.d/init.d/functions ] ; then
	    . /etc/rc.d/init.d/functions
	else
	    exit 0
	fi

	if [[ `uname -a | grep -c '2.6'` -ge 1 ]];then
		sed -i '/LANG=/c\LANG="en_US.UTF-8"' /etc/sysconfig/i18n
	else
	    sed -i '/LANG=/c\LANG="en_US.UTF-8"' /etc/locale.conf
	fi

	CMDS="fdisk shutdown reboot init dd kill mkfs killall fsck chown"
	for i in $CMDS
	do
	    alias $i 2>/dev/null
	    [[ $? -eq 0 ]] && unalias $i
	done
	sleep 1
	#步骤1 系统安全配置
	set_system_security
	sleep 1
	#步骤2 内核优化
	set_kernel_info
	sleep 1
	#步骤3 建立内置用户
	set_system_users
	sleep 1
	#步骤4 系统基本配置
	set_system_info
	sleep 1
	#步骤5 安装软件
	install_base_soft
	sleep 1
	echo "[ `date '+%Y-%m-%d %H:%M:%S'` ] [INFO] [ Initial System Success,Starting Reboot System!!! ]"
	sync;reboot
}
main
