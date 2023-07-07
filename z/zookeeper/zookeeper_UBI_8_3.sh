# ----------------------------------------------------------------------------
#
# Package       : Apache Zookeeper
# Version       : 3.6.2
# Source repo   : https://github.com/apache/zookeeper.git
# Tested on     : UBI 8.3
# Script License: Apache License
# Maintainer    : nishikant.thorat@ibm.com
#
# ----------------------------------------------------------------------------
#!/bin/bash
yum install -y sudo
sudo yum update -y

export PKG_CONFIG=/usr/bin/pkg-config
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

yum install -y git wget maven hostname automake libtool autoconf-2.69 gcc-c++ make
git clone git://anongit.freedesktop.org/git/libreoffice/cppunit/
cd cppunit && ./autogen.sh && ./configure --build=ppc64le && make && make install && cd ..

yum install -y pkgconf-1.4.2
#
# "-fn" option in mvn command will continue compilatio,n even if one module/ component compilation fails. Kindly check in logs, if all# components are compiled successfully or not
#
git clone https://github.com/apache/zookeeper.git -b release-3.6.2
cd zookeeper &&  mvn clean apache-rat:check verify -DskipTests spotbugs:check checkstyle:check -Pfull-build -Drat.skip=true -Dlicense.skip  -Dlicense.skipDownloadLicenses -Drat.numUnapprovedLicenses=100 -fn
