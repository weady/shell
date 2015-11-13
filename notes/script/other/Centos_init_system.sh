#!/bin/bash

cat<<EOF
+‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐+
|===InitCentOSSystem_config===
+‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐‐+

EOF

#updatealiyunyum
cd/etc/yum.repos.d
mvCentOS‐Base.repoCentOS‐Base.repo.bak
wget‐O/etc/yum.repos.d/CentOS‐Base.repohttp://mirrors.aliyun.com/repo/Centos‐
repo
yummakecache

#addepel
rpm‐Uvh
tp://ftp.pbone.net/mirror/dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/epel‐
elease‐6‐5.noarch.rpm
rpm–import/etc/pki/rpm‐gpg/RPM‐GPG‐KEY‐EPEL‐6

#addrpmforge
rpm‐Uvhhttp://packages.sw.be/rpmforge‐release/rpmforge‐release‐0.5.2‐
el6.rf.x86_64.rpm
rpm–import/etc/pki/rpm‐gpg/RPM‐GPG‐KEY‐rpmforge‐dag

#updatesystempack
yum‐yinstallgccgcc‐c++makeautoconflibtool‐ltdl‐develgd‐develfreetype‐
evellibxml2‐devellibjpeg‐devellibpng‐developenssl‐develcurl‐develbison
atchunziplibmcrypt‐devellibmhash‐develncurses‐develsudobzip2mlocateflex
rzszsysstatlsofsetuptoolsystem‐config‐network‐tuisystem‐config‐firewall‐
uintplibaio‐develwgetntp

#setntp
echo"*/5****/usr/sbin/ntpdatentp.api.bz>/dev/null2>&1">>
var/spool/cron/root
servicecrondrestart

#setclock
hwclock‐‐set‐‐date="`date+%D\%T`"
hwclock‐‐hctosys

#setulimit
echo"ulimit‐SHn102400">>/etc/rc.local
cat>>/etc/security/limits.conf<<EOF
*softnofile102400
*hardnofile102400
*softnproc102400
*hardnproc102400
EOF

#setmaxuserprocesses
sed‐i's/1024/102400/'/etc/security/limits.d/90‐nproc.conf

#turnoffthecontrol‐alt‐delete
sed‐i's#exec/sbin/shutdown‐rnow#\#exec/sbin/shutdown‐rnow#'
etc/init/control‐alt‐delete.conf

#closeuselessservice
foriin`ls/etc/rc3.d/S*`
do
CURSRV=`echo$i|cut‐c15‐`
echo$CURSRV
case$CURSRVin
crond|irqbalance|network|sshd|rsyslog|sysstat)
echo"Baseservices,Skip!"
;;
*)
echo"change$CURSRVtooff"
chkconfig‐‐level2345$CURSRVoff
service$CURSRVstop
;;
esac
done
echo"serviceisinitisok.............."

#setLANG
:>/etc/sysconfig/i18n
cat>>/etc/sysconfig/i18n<<EOF
LANG="en_US.UTF‐8"
EOF

#setssh
sed‐i's/^GSSAPIAuthenticationyes$/GSSAPIAuthenticationno/'
etc/ssh/sshd_config
sed‐i's/#UseDNSyes/UseDNSno/'/etc/ssh/sshd_config
sed‐i's/#Port22/Port6343/'/etc/ssh/sshd_config
servicesshdrestart

#setsysctl
true>/etc/sysctl.conf
cat>>/etc/sysctl.conf<<EOF
net.ipv4.ip_forward=0
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.default.accept_source_route=0
kernel.sysrq=0
kernel.core_uses_pid=1
net.ipv4.tcp_syncookies=1
kernel.msgmnb=65536
kernel.msgmax=65536
kernel.shmmax=68719476736
kernel.shmall=4294967296
net.ipv4.tcp_max_tw_buckets=6000
net.ipv4.tcp_sack=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_rmem=4096873804194304
net.ipv4.tcp_wmem=4096163844194304
net.core.wmem_default=8388608
net.core.rmem_default=8388608
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.netdev_max_backlog=262144
net.core.somaxconn=262144
net.ipv4.tcp_max_orphans=3276800
net.ipv4.tcp_max_syn_backlog=262144
net.ipv4.tcp_timestamps=0
net.ipv4.tcp_synack_retries=1
net.ipv4.tcp_syn_retries=1
net.ipv4.tcp_tw_recycle=1
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_mem=94500000915000000927000000
net.ipv4.tcp_fin_timeout=1
net.ipv4.tcp_keepalive_time=1200
net.ipv4.ip_local_port_range=102465535
EOF
/sbin/sysctl‐p
echo"sysctlsetOK!!"

#disableipv6
echo"aliasnet‐pf‐10off">>/etc/modprobe.conf
echo"aliasipv6off">>/etc/modprobe.conf
/sbin/chkconfigip6tablesoff
echo"ipv6isdisabled!"

#disableiptables
/sbin/iptablesstop
/sbin/chkconfigiptablesoff

#disableselinux
sed‐i's/SELINUX=enforcing/SELINUX=disabled/g'/etc/sysconfig/selinux
setenforce0

#vimsetting

sed‐i"8s/^/aliasvi='vim'/"/root/.bashrc
sed‐i"9s/^/aliasll='ls‐lh'/"/root/.bashrc
echo'syntaxon'>/root/.vimrc
#去除系统及内核版本登录前的屏幕显示

>/etc/redhat‐release
>/etc/issue


#增加用户并sudo提权
user_add()
{
USERNAME=$(input_fun"pleaseinputnewusername:")
useradd$USERNAME
passwd$USERNAME
}
user_add

chmod+w/etc/sudoers
echo"$USERNAMEALL=(ALL)ALL">>/etc/sudoers
chmod‐w/etc/sudoers

echo"###############################################################"
