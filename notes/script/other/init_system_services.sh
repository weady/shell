#/bin/bash
#
#This script is used to init system service!
#
#	by wangdd 2015/8/15
#
# Services should be retained  "acpid, haldaemon, messagebus, klogd, network, syslogd ,sshd, crond"
#Stop all Services
for server in `chkconfig --list | grep "3:on"|awk '{print $1}'`
do 
	chkconfig $server off
done
#Start base services
for server in crond network sshd rsyslog
do 
	chkconfig $server on
done
#Start need services,stop not need services
for server in `chkconfig --list | grep "3:on"|awk '{print $1}'|grep -vE "crond|network|sshd|rsyslog"`
do 
	chkconfig $server off
done
# Check start services
echo “chkconfig --list | grep '3:on'|awk '{print $1}'”
echo "chkconfig --list|grep '3:on'"

