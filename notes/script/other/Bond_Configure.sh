
#---------- Bonding IP Config for ifcfg-bond0 ----------
#centos 3.x kernel的bond配置
REPORT='result.log'
IPBonding_3(){
    #判断系统内核然后获取出激活状态的网卡信息
    system_kernel=`uname -r | awk -F'.' '{print $1}'`

    if [ ! -f $IPCFG ]; then
        echo "FAILED: The IP Config file \"Host_IP.conf\" Is Not Existed!" | tee -a $REPORT
        exit 1
    fi
    bond_tag=`ls -l /etc/sysconfig/network-scripts| grep ifcfg-bond* | wc -l`
    if [ "$bond_tag" -ge 1 ];then
        echo "[Warning] [Bond has exist,Please check!]" | tee -a $REPORT
        exit 1
    fi

    ETH_LIST=`ip add | grep -E 'mtu.*UP' | awk -F ':' '{print $2}' | tr -d ' ' | head -n 2`
    ETH_NUM=`ip add | grep -E 'mtu.*UP' | awk -F ':' '{print $2}' | tr -d ' ' | head -n 2| wc -l`
    
    if [[ "$ETH_NUM" -ne 2 ]]; then
        echo "[FAILED] [The Number of interfaces is less than 2 ]" |tee -a $REPORT
        exit
    fi

    for ETH in $ETH_LIST
    do
        iptag=`grep '^IPADDR' /etc/sysconfig/network-scripts/ifcfg-${ETH} | awk -F'=' '{print $2}'`
        if [[ -n "$iptag" ]]; then
            GW=`grep '^GATEWAY' /etc/sysconfig/network-scripts/ifcfg-${ETH} | awk -F'=' '{print $2}'`
            break
        fi
    done

#-------------配置bond-------------
modprobe bonding
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0  
TYPE=Bond  
NAME=bond0  
BONDING_MASTER=yes  
BOOTPROTO=static  
USERCTL=no  
ONBOOT=yes  
IPADDR=$iptag  
PREFIX=24  
GATEWAY=$GW 
BONDING_OPTS="mode=1 miimon=100"  

EOF

cat << EOF >> /etc/modprobe.d/bonding.conf
alias bond0 bonding
options bond0 mode=1 miimon=100
EOF

#-------------配置网卡信息-------------
    for ETH in $ETH_LIST
    do
        cp /etc/sysconfig/network-scripts/ifcfg-${ETH} /etc/sysconfig/network-scripts/ifcfg-${ETH}.bak

cat << EOF >/etc/sysconfig/network-scripts/ifcfg-${ETH}
TYPE=Ethernet  
BOOTPROTO=none  
DEVICE=$ETH  
ONBOOT=yes  
MASTER=bond0  
SLAVE=yes  
EOF
    done

#-------------关闭NetworkManager-------------
echo "Stop NetworkManager" | tee -a $REPORT
systemctl stop NetworkManager.service

#-------------重启network服务-------------
systemctl restart network.service

#验证bond 绑定结果
bond_status=`ip add | grep -E 'bond.*UP'`
if [[ -n "$bond_status" ]]; then
    echo "[Success] [ Bond Configure Compleate!]" | tee -a $REPORT
else
    echo "[FAILED] [ Bond configure Failed ]" | tee -a $REPORT
fi
}

#cnetos 2.x kernel的bond 配置
IPBonding_2()
{

if [ ! -f $IPCFG ]; then
    echo "FAILED: The IP Config file \"Host_IP.conf\" Is Not Existed!" | tee -a $REPORT
    exit 1
fi

for (( i=0; i<=5; i++ ))
do
    if [ ! -f /etc/sysconfig/network-scripts/ifcfg-bond$i ]; then
        break
    fi
done 


for ETH in `ifconfig -a | grep HWaddr | grep -vE "^bond|^usb|^lo" | awk '{print $1}'`
do
    ipflag=`ifconfig $ETH | grep -w inet | awk '{print $2}' | cut -d: -f2`
    bnflag=`grep -i bond /etc/sysconfig/network-scripts/ifcfg-$ETH`
    dhflag=`grep -iw dhcp /etc/sysconfig/network-scripts/ifcfg-$ETH`

    if [ -n "$ipflag" -a -n "$dhflag" ]; then
        HWADDR=`ifconfig -a | grep -w "^$ETH" | awk '{print $NF}'`
        HOST=`grep -i "$HWADDR" $IPCFG | awk -F, '{print $1}'`
        IP=`grep -i "$HWADDR" $IPCFG | awk -F, '{print $2}'`
        GW=`grep -i "$HWADDR" $IPCFG | awk -F, '{print $2}' | cut -d. -f1-3`
        MASK='255.255.255.0'
            
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$ETH
DEVICE=$ETH
HWADDR=$HWADDR
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
USERCTL=no
BOOTPROTO=none
MASTER=bond$i
SLAVE=yes
EOF
            
        echo "---------- ifcfg-$ETH Config ----------" | tee -a $REPORT
        cat /etc/sysconfig/network-scripts/ifcfg-$ETH | tee -a $REPORT
        if [ $((++n)) -eq 2 ]; then
                break
        fi
    fi
        
    if [ -z "$ipflag" -a -z "$bnflag" ]; then
        HWADDR=`ifconfig -a | grep -w "^$ETH" | awk '{print $NF}'`
        HOST=`grep -i "$HWADDR" $IPCFG | awk -F, '{print $1}'`
        IP=`grep -i "$HWADDR" $IPCFG | awk -F, '{print $2}'`
        GW=`grep -i "$HWADDR" $IPCFG | awk -F, '{print $2}' | cut -d. -f1-3`
        MASK='255.255.255.0'
            
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$ETH
DEVICE=$ETH
HWADDR=$HWADDR
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
USERCTL=no
BOOTPROTO=none
MASTER=bond$i
SLAVE=yes
EOF
            
        echo "---------- ifcfg-$ETH Config ----------" | tee -a $REPORT
        cat /etc/sysconfig/network-scripts/ifcfg-$ETH | tee -a $REPORT
        if [ $((++n)) -eq 2 ]; then
                break
        fi
    fi
done

modprobe bonding
    
cat << EOF >> /etc/modprobe.d/bonding.conf
alias bond$i bonding
options bond$i mode=1 miimon=100
EOF
    
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond$i
BONDING_OPTS="miimon=100 mode=1"
DEVICE=bond$i
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=no
USERCTL=no
BOOTPROTO=none
IPADDR=$IP
NETMASK=$MASK
GATEWAY=${GW}.254
EOF

echo "---------- ifcfg-bond$i Config ----------" | tee -a $REPORT
cat /etc/sysconfig/network-scripts/ifcfg-bond$i | tee -a $REPORT
}
IPBonding_3
