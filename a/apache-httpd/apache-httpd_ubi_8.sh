# ----------------------------------------------------------------------------
#
# Package       : httpd
# Version       : v2.4.46
# Source repo   : https://github.com/apache/httpd
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

PACKAGE_NAME="apachehttpserver"
HTTPD_VERSION="2.4.46"
APR_VERSION="1.7.0"
APR_UTIL_VERSION="1.6.1"
CUR_DIR="$(pwd)"

yum update -y

yum install sudo git openssl openssl-devel python2 gcc libtool autoconf make pcre pcre-devel libxml2 libxml2-devel expat-devel which wget tar -y
ln -s /usr/bin/python2 /usr/bin/python

cd $CUR_DIR
git clone https://github.com/apache/httpd
cd $CUR_DIR/httpd
git checkout $HTTPD_VERSION

cd $CUR_DIR/httpd/srclib
git clone https://github.com/apache/apr.git
cd $CUR_DIR/httpd/srclib/apr  && git checkout $APR_VERSION

cd $CUR_DIR/httpd/srclib
git clone https://github.com/apache/apr-util.git
cd $CUR_DIR/httpd/srclib/apr-util && git checkout $APR_UTIL_VERSION


cd $CUR_DIR/httpd
#sudo alternatives --set python /usr/bin/python2 (For RHEL 8.0 & UBI container)
./buildconf
./configure --with-included-apr
make
sudo make install

# Make following changes in /usr/local/apache2/conf/httpd.conf file.
# In Listen changed port 80 to 8081 as port was already being used.
# Uncommented Servername field and changed it to ServerName localhost
# After making the above changes run below command to succesfully start
# the server.

sudo sed -i '52s/Listen 80/Listen 8081/' /usr/local/apache2/conf/httpd.conf
sudo sed -i '197s/#ServerName www.example.com:80/ServerName localhost/' /usr/local/apache2/conf/httpd.conf
sudo /usr/local/apache2/bin/apachectl start

# test
curl localhost:8081
