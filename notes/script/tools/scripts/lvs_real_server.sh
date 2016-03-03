#!/bin/bash
#
# Script to start LVS DR real server.
# description: LVS DR real server
#
. /etc/rc.d/init.d/functions
VIP=192.168.101.250
VIP02=192.168.101.249
host=`/bin/hostname`
case "$1" in
start)
       # Start LVS-DR real server on this machine.
  /sbin/ifconfig lo down
  /sbin/ifconfig lo up
  echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore
  echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce
  echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
  echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
  /sbin/ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up
  /sbin/route add -host $VIP dev lo:0
  /sbin/ifconfig lo:1 $VIP02 broadcast $VIP netmask 255.255.255.255 up
  /sbin/route add -host $VIP dev lo:1
;;
stop)
  # Stop LVS-DR real server loopback device(s).
  /sbin/ifconfig lo:0 down
  /sbin/ifconfig lo:1 down
  echo 0 > /proc/sys/net/ipv4/conf/lo/arp_ignore
  echo 0 > /proc/sys/net/ipv4/conf/lo/arp_announce
  echo 0 > /proc/sys/net/ipv4/conf/all/arp_ignore
  echo 0 > /proc/sys/net/ipv4/conf/all/arp_announce
;;
*)
      # Invalid entry.
      echo "$0: Usage: $0 {start|status|stop}"
      exit 1
;;
esac

