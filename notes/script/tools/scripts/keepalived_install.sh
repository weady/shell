#!/bin/bash
#
#This script used to install keepalived soft
#	by wangdd 2016/3/1
#
#


soft_path="/usr/local/src"
VIPS=$1
PORTS=$2
real_server_ips=$3
LVS_TYPE=$4
INTER=$5
LVS_priority=$6
LB_algo=$7
#---------------------------------------------------------------------
yum install -q -y ipvsadm openssl-devel >>/dev/null
num=`/bin/rpm -qa | grep -E "ipvsadm|openssl-devel" | wc -l`
if [ $num -eq 2 ];then
	echo "ipvsadm and openssl-devel install success!"
else
	echo "ipvsadm or openssl-devel install failed"
	exit
fi


function install_keepalived(){
	if [ -d "/usr/local/keepalived" ];then
		echo "keepalived has installed"
	else
		cd $soft_path
		if [ -f "$soft_path/keepalived-1.2.19.tar.gz" ];then
			tar zxvf keepalived-1.2.19.tar.gz
			./configure --prefix=/usr/local/keepalived
			make && make install
			cp /usr/local/keepalived/sbin/keepalived /usr/sbin/
			cp /usr/local/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
			cp /usr/local/keepalived/etc/rc.d/init.d/keepalived /etc/init.d/
			mkdir /etc/keepalived
			[[ $? -eq 0 ]] && echo "keepalived install success"
		else
			echo "Not find keepalived-1.2.19.tar.gz in $soft_path document!"
		fi
	fi
	
}

function config_vip(){

if [ ! -f "/etc/keepalived/keepalived.conf" ];then
echo "#" >/etc/keepalived/keepalived.conf
cat > /etc/keepalived/keepalived.conf << EOF

global_defs {
   notification_email {
     boss@ipanel.cn
   }
   notification_email_from boss@ipanel.cn
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}

vrrp_instance LVS {
    state $LVS_TYPE
    interface $INTER
    virtual_router_id 51
    lvs_sync_daemon_inteface $INTER
    priority $LVS_priority
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
    }
}

EOF
fi
#--------------------------------------------
for VIP in $VIPS
do
exsit_vip=`cat /etc/keepalived/keepalived.conf | egrep  "^$VIP"` 
if [ -z "exsit_vip" ];then
sed -i "/virtual_ipaddress/a $VIP" /etc/keepalived/keepalived.conf
fi
for PORT in $PORTS
do
cat >>/etc/keepalived/keepalived.conf << EOF

#----------------------------------------------
#VIP $VIP $PORT
#----------------------------------------------
virtual_server $VIP $PORT {
    delay_loop 3
    lb_algo $LB_algo
    lb_kind DR
    persistence_timeout 5
    protocol TCP
EOF

for client_ip in $real_server_ips
do
cat >>/etc/keepalived/keepalived.conf << EOF
    real_server $client_ip $PORT {
        weight 3
        TCP_CHECK {
            connect_timeout 3
            nb_get_retry 3
            delay_before_retry 3
            connect_port 80
        }
    }

EOF
done
done
echo "}" >>/etc/keepalived/keepalived.conf
done
}

#wget -q http://www.keepalived.org/software/keepalived-1.2.19.tar.gz -P $soft_path >>/dev/null
wget -q --ftp-user=homedmaintain --ftp-password=HomedMaintain44 http://ftp.ipanel.cn:30/homedmaintain/soft/keepalived-1.2.19.tar.gz  -P $soft_path >>/dev/null
if [ $? -ne 0 ];then
	echo "Download keepalived-1.2.19.tar.gz for FTP Failed!"
	install_keepalived
else
	install_keepalived
fi
#--------------------------------------------------
#main
config_vip
[[ $? -eq 0 ]] && echo "keepalived.conf configure success!"
service keepalived restart
