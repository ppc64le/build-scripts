# ----------------------------------------------------------------------------
#
# Package	: apache directory-server
# Version	: 2.0.0-M24
# Source repo	: https://github.com/apache/directory-server
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

sudo yum update -y
sudo yum install -y make gcc-c++ java-1.8.0-openjdk-devel git wget zip tar

#Install maven
wget http://www-us.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar -zxvf apache-maven-3.5.2-bin.tar.gz

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH:`pwd`/apache-maven-3.5.2/bin

WDIR=`pwd`
cd $WDIR
git clone https://github.com/apache/directory-server
cd $WDIR/directory-server
git checkout 1a6205e780ec66e2a6094b0f65f6cab62d4b8d0b
mvn clean install
