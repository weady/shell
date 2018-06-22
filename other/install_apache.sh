#install apache
pack_path01="/usr/local/src/soft/test"
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
