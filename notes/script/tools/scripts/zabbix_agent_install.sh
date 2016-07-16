#!/bin/bash
#
#
#this script used to install zabbix_agent
#
#
#	by wangdd 2015/10/8
#
#
##check_ok function

### add zabbix user
id zabbix || useradd zabbix -s /sbin/nologin
##install zabbix
clientname=`hostname`
serverip="$1"
path="/usr/local/zabbix"
dst_path="/usr/local/src"
#
function install_soft(){
        Megacli_path="/opt/MegaRAID/MegaCli"
        yum install -y -q --skip-broken bc sysstat  >/dev/null 2>&1
        if [ ! -d "$Megacli_path" ];then
                cd /usr/local/src/zabbix-2.4.6/soft
                rpm -i Lib_Utils-1.00-09.noarch.rpm --nodeps >/dev/null 2>&1
                rpm -i MegaCli-8.00.48-1.i386.rpm --nodeps >/dev/null 2>&1
        fi
}

function clean(){
	if [ ! "$clientname" == "master" ];then
		rm -rf /usr/local/src/zabbix-2.4.6
		rm -rf /usr/local/src/scripts
		rm -f /usr/local/src/zabbix-2.4.6.tar.gz
		rm -f /usr/local/src/operational_tool.sh
		rm -rf /usr/local/zabbix/etc/zabbix_agent.conf.d
		exit
	fi
}

function check_ok(){
	if [ $? -eq 0 ];then
		echo "ok"
	else
		echo "Error,please check"
		clean
	fi
}
function check_agent(){
	zb_file="/usr/local/zabbix/etc/zabbix_agentd.conf"
	if [ -f "$zb_file" ];then
		echo "zabbix_agent is installed"
		clean
	fi
}
function modify_power(){
chmod u+w /etc/sudoers
tmp=`cat /etc/sudoers | grep "zabbix"`
if [ -z "$tmp" ];then
sed -i "s/Defaults    requiretty/Defaults    \!requiretty/" /etc/sudoers
cat >>/etc/sudoers <<EOF
Cmnd_Alias MONITORING = /bin/netstat,/sbin/sudo,/bin/*,/sbin/*,/opt/MegaRAID/MegaCli/MegaCli64
zabbix        ALL=(root) NOPASSWD:MONITORING
EOF
fi
chmod u-w /etc/sudoers
}
#-----------------------------------------------------------------
check_agent
install_soft
yum install -y -q auto* autoconf automake libtool >/dev/null
cd $dst_path/zabbix-2.4.6
autoreconf -ivf
./configure --prefix=$path --enable-agent --with-net-snmp 
make && make install
check_ok
##modify config_file
cd $path/etc && rm -rf zabbix*
mkdir -p $path/scripts
\cp -ar $dst_path/zabbix-2.4.6/agent/* $path/etc/
\cp -ar $dst_path/zabbix-2.4.6/scripts/* $path/scripts/
\cp -a $dst_path/zabbix-2.4.6/scripts/zabbix_agent /etc/init.d
check_ok
sed -i "s/zabbixagentip/$clientname/" $path/etc/zabbix_agentd.conf
sed -i "s/zabbixserip/$serverip/g" $path/etc/zabbix_agentd.conf
check_ok
## start zabbix_agent
$path/sbin/zabbix_agentd -c $path/etc/zabbix_agentd.conf
[[ $? -eq 0 ]] && echo "zabbix agent installed success"
clean
