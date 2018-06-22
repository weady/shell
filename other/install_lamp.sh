#!/bin/bash
############################

# This scritp is used to installed LAMP
# by wangdd 2015/6/28

############################

#Install development by yum,mysql_5.5 compile need cmake bison ncurses
yum -y install make gcc gcc-c++ zlib-devel libaio cmake bison ncurses-devel*

#unistall php mysql httpd
rpm -e php mysql httpd

#####################################################################################

#get soft packs include libxml2,libmcrypt,zlib,jpeg,libpng,freetype,autoconf
wget_path01="http://down1.chinaunix.net/distfiles"
pack_path01="/usr/local/src/soft/test"
if [ ! -d $pack_path01 ];then
	mkdir -p $pack_path01
	for pack in "libxml2-2.7.8.tar.gz" "libmcrypt-2.5.7.tar.gz" "zlib-1.2.7.tar.gz" "libpng-1.5.4.tar.xz" "jpegsrc.v7.tar.gz" "freetype-2.4.6.tar.bz2" "autoconf-2.69.tar.xz" "ncurses-5.9.tar.gz";
	do 
	    wget -P $pack_path01 $wget_path01/$pack
	done
fi
#wget gd
#wget -P $pack_path01 http://liquidtelecom.dl.sourceforge.net/project/gd2/gd-2.0.35.tar.gz
wget -P $pack_path01 http://jaist.dl.sourceforge.net/project/gd2/gd-2.0.35.tar.gz

#wget httpd apr apr-util apr-iconv pcre,you should be install apr first,then install apr-util adn apr-inconv
wget -P $pack_path01 http://apache.fayea.com//apr/apr-1.5.2.tar.gz
wget -P $pack_path01 http://mirrors.cnnic.cn/apache//apr/apr-util-1.5.4.tar.gz
wget -P $pack_path01 http://mirrors.cnnic.cn/apache//apr/apr-iconv-1.2.1.tar.gz
wget -P $pack_path01 http://ncu.dl.sourceforge.net/project/pcre/pcre/8.36/pcre-8.36.zip
#wget httpd
wget -P $pack_path01 http://mirrors.cnnic.cn/apache//httpd/httpd-2.4.12.tar.gz
#wget mysql
#If the Mysql database version higher than 5.5, compiled using cmake, at the same time need to bison, ncurse 
wget -P $pack_path01 http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.44.tar.gz
#wget php
wget -P $pack_path01 http://cn2.php.net/distributions/php-5.5.26.tar.gz

#######################################################################################
#unpack_soft
for file in `ls -l $pack_path01 | awk -F' ' '{print $NF}'`
do
        if [ "${file##*.}" = "gz" ];then
         	tar zxvf $pack_path01/$file -C $pack_path01
	fi

        if [ "${file##*.}" = "xz" ];then
           	tar xvJf $pack_path01/$file -C $pack_path01
        fi

	if [ "${file##*.}" = "zip" ];then
		unzip $pack_path01/$file -d $pack_path01
	else
                tar xf $pack_path01/$file -C $pack_path01
	fi
done
########################################################################################
#install software
soft=`ls /usr/local/src/soft/test | awk -F' ' '{print $NF}' | grep -v '^[0-9].*'`
for soft_pack in $soft
do
if [ $soft_pack = "libxml2-2.7.8" ] || [ $soft_pack = "libmcrypt-2.5.7" ] || [ $soft_pack = "zlib-1.2.7" ] || [ $soft_pack = "autoconf-2.69" ] || [ $soft_pack = "pcre-8.36" ] || [ $soft_pack = "ncurses-5.9" ];then
        cd $pack_path01/$soft_pack/
        bash $pack_path01/$soft_pack/configure --prefix=/usr/local/${soft_pack%-*}/
        make && make install
fi

if [ $soft_pack = "libpng-1.5.4" ] || [ $soft_pack = "freetype-2.4.6" ];then
        cd $pack_path01/$soft_pack/
        bash $pack_path01/$soft_pack/configure --prefix=/usr/local/${soft_pack%-*}/ --enable-shared
        make && make install
fi

if [ $soft_pack = "jpeg-7" ];then
        cd $pack_path01/$soft_pack/
        bash $pack_path01/$soft_pack/configure --prefix=/usr/local/${soft_pack%-*}/ --enable-shared --enable-static
        make && make install
fi
done

######################################################################################
#install gd
function soft_check() {
        for installed_soft in "libxml2" "libmcrypt" "zlib" "autoconf" "pcre" "ncurses" "libpng" "freetype" "jpeg"
        do
                find_bin=`find /usr/local/$installed_soft -maxdepth 2 -name bin`
                if [ -d "$find_bin" ];then
                        echo $installed_soft install sucess!
                else
                        echo $installed_soft install failed!
                        return 2
                        break
                fi
        done
}
soft_check
if [ "$?" -eq "2" ];then
        echo "Install GD Failed,Because $installed_soft is not install,Please Check!"
else
        cd $pack_path01/gd-2.0.35
	sed -i 's#png.h#/usr/local/libpng/include/png.h#g' gd_png.c
        ./configure --prefix=/usr/local/gd \
         --with-zlib=/usr/lib/zlib \
         --with-jpeg==/usr/local/jpeg \
         --with-png=/usr/local/libpng \
         --with-freetype=/usr/local/freetype
         make && make install
fi
#####################################################################################
#install mysql
function install_mysql() {
groupadd mysql
useradd -r -g mysql mysql
cd $pack_path01/mysql-5.5.44
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DDEFAULT_CHARSET=utf8 
make && make install
}
install_mysql
if [ "$?" -eq "0" ];then
	cd /usr/local/mysql
	chown -R mysql.mysql /usr/local/mysql
	chown -R mysql data
	bash scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
	cp support-files/my_medium.cnf /etc/my.cnf
	cp support-files/mysql.server /etc/init.d/mysqld
	chmod +x /etc/init.d/mysqld
	chkconfig --add mysqld
else
	echo install mysql failed!
fi
#####################################################################################
#install apache
cd $pack_path01/apr-1.5.2
sed -i "s#RM='\$RM'#RM='\$RM -f'#g" configure
./configure --prefix=/usr/local/apr
make && make install
function http_dev() {
        find_apr=`find /usr/local/apr -maxdepth 2 -name bin`
        apr_dev=`find $pack_path01 -maxdepth 1 -name "apr-*-*" | awk -F'/' '{print $NF}'`
        for find_apr_dev in $apr_dev
        do
                if [ -d "$find_apr" ] && [ ! -z "$apr_dev" ];then
                        cd $pack_path01/$find_apr_dev
                        ./configure --prefix=/usr/local/${find_apr_dev%-*}/ --with-apr=/usr/local/apr
                        make && make install
                else
                        echo http_development install faild,please check!
                        return 2
                        break
                fi
        done
}
http_dev
if [ $? -eq "2" ];then
        echo Apache Install Failed!
else
        cd $pack_path01/httpd-2.4.12
        ./configure --prefix=/usr/local/apache/ \
        --enable-so \
        --enable-rewrite \
        --with-apr=/usr/local/apr \
        --with-apr-util=/usr/local/apr-util \
        --with-pcre=/usr/local/pcre 
        make && make install
        cp /usr/local/apache/bin/apachectl /etc/init.d/httpd
        chmod +x /etc/init.d/httpd
        chkconfig --add httpd
        echo "Apache Isatll Sucess!"
fi
####################################################################################
#install php
function install_php() {
	cd $pack_path01/php-5.5.26
	./configure --prefix=/usr/local/php/ \
	--with-apxs2=/usr/local/apache/bin/apxs \
	--with-libxml-dir=/usr/local/libxml2/ \
	--with-jpeg-dir=/usr/local/jpeg/ \
	--with-freetype-dir=/usr/local/freetype/ \
	--with-gd-dir=/usr/local/gd/ \
	--with-zlib-dir=/usr/local/zlib/ \
	--with-mcrypt=/usr/local/libmcrypt/ \
	--with-mysqli=/usr/local/mysql/bin/mysql_config \
	--enable-soap \
	--enable-mbstring=all \
	--enable-sockets
	make && make install
	cp php.ini-development /usr/local/php/lib/php.ini
}
install_php
#modify http.conf
#cd /usr/local/apach

