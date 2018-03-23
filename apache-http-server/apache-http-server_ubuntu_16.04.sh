# ----------------------------------------------------------------------------
#
# Package	: apache-http-server
# Version	: 2.4.29
# Source repo	: http://svn.apache.org/repos/asf/httpd/httpd/trunk
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y curl libxml2-dev libjzlib-java liblua5.1-0 \
    zlib1g-dev libopenblas-dev wget subversion libtool make autoconf \
    python-dev libtool-bin libpcre2-dev

svn checkout http://svn.apache.org/repos/asf/httpd/httpd/trunk
cd trunk
svn co http://svn.apache.org/repos/asf/apr/apr/trunk srclib/apr
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
