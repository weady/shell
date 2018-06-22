#!/bin/bash
#
#
#
#
#config_jdk
soft_file="/usr/local/src/soft"
dec_path="/usr/local/test"

#cat << EOF >>/etc/profile
#JAVA_HOME=/usr/local/test/jdk1.7.0_55
#PATH=$JAVA_HOME/bin:$PATH
#export PATH USER LOGNAME MAIL HOSTNAME HISTSIZE INPUTRC JAVA_HOME
#source /etc/profile

#config_tomcat
cd $dec_path/tomcat/bin
./startup.sh
cat << EOF >>/etc/rc.d/rc.local
/usr/local/test/tomcat/bin/startup.sh &
EOF

#config_apache
cp $dec_path/apache/bin/apachctl /etc/init.d/httpd
chkconfig --add httpd
service httpd restart
