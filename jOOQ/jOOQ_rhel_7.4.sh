# ----------------------------------------------------------------------------
#
# Package	: jOOQ
# Version	: master
# Source repo	: https://github.com/jOOQ/jOOQ
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum update 
sudo yum install -y make gcc-c++ java-1.8.0-openjdk-devel git

#Install maven
wget http://www-us.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar -zxvf apache-maven-3.5.2-bin.tar.gz

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH:`pwd`/apache-maven-3.5.2/bin

WDIR=`pwd`
cd $WDIR
git clone https://github.com/jOOQ/jOOQ
cd $WDIR/jOOQ
mvn install
