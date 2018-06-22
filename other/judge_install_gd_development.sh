#!/bin/bash
#install gd
function soft_check() {
        for installed_soft in "libxml2" "libmcrypt" "zlib" "autoconf" "pcre" "ncurses" "libpng" "freetype" "jpeg"
        do
                find_bin=`find /usr/local/$installed_soft -maxdepth 2 -name bin`
                if [ -d "$find_bin" ];then
			echo $installed_soft install seccuss!
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
        ./configure --prefix=/usr/local/gd \
	 --with-zlib=/usr/lib/zlib \
	 --with-jpeg==/usr/local/jpeg \
	 --with-png=/usr/local/libpng \
	 --with-freetype=/usr/local/freetype   
	 make && make install
fi
