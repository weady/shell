#!/bin/bash
#
#
#
soft_file="/usr/local/src/soft"
dec_path="/usr/loca/test"

for file in `dir $dec_path/php`
do
	tar zxvf $file
done

cd $dec_path/libxml2-2.7.2
./configure --prefix=/usr/local/libxml2
make &&make install

cd $dec_path/php-5.5.7
./configure --prefix=/usr/local/php \
--with-apxs2=/usr/local/apache/bin/apxs \
--with-libxml-dir=/usr/local/libxml2 \
--enable-sockets \
--with-mysql=mysqlnd \
--with-mysqli \ 
--with-sqlite3 \
make && make install
