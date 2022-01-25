
# ----------------------------------------------------------------------------
#
# Package       : mod_proxy
# Version       : v2.4.41
# Source repo   : https://github.com/allenai/allennlp
# Tested on     : docker container, UBI 8
# Script License: Apache License, Version 2 or later
# Maintainer    : Rashmi Sakhalkar <srashmi@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Build HTTPD
yum update -y
yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel python2 autoconf libtool make pcre pcre-devel libxml2 libxml2-devel expat-devel which git wget -y

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PACKAGE_NAME="apachehttpserver" 
export HTTPD_VERSION="2.4.41" 
export APR_VERSION="1.6.5" 
export APR_UTIL_VERSION="1.6.1" 
export SRC=/usr/local/src 
HTTPD_HOME=/usr/local/apache2

cd $SRC 
git clone https://github.com/apache/httpd 
cd $SRC/httpd 
git checkout $HTTPD_VERSION 
cd $SRC/httpd/srclib 
git clone https://github.com/apache/apr.git 
cd $SRC/httpd/srclib/apr 
git checkout $APR_VERSION 
cd $SRC/httpd/srclib 
git clone https://github.com/apache/apr-util.git 
cd $SRC/httpd/srclib/apr-util 
git checkout $APR_UTIL_VERSION 
alternatives --set python /usr/bin/python2 
cd $SRC/httpd 
./buildconf 
./configure --with-included-apr 
make 
make install 
sed -i '195s/#ServerName www.example.com:80/ServerName localhost/' ${HTTPD_HOME}/conf/httpd.conf


#Configure mod_proxy in Apache HTTP Server
#Non-load-balancing Proxy
echo '<VirtualHost *:80>
# Your domain name
ServerName localhost
ProxyPreserveHost On
LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
# The IP and port of JBoss
# These represent the default values, if your httpd is on the same host
# as your JBoss managed domain or server
ProxyPass / http://localhost:8080/
ProxyPassReverse / http://localhost:8080/
# The location of the HTML files, and access control information
DocumentRoot /
<Directory /hello/>
Options -Indexes
Order allow,deny
Allow from all
</Directory>
</VirtualHost>
' >> $HTTPD_HOME/conf/httpd.conf