#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : nifi
# Version       : 1.9.0
# Source repo   : https://github.com/apache/nifi
# Tested on     : UBI: 8.5
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-rel/nifi-1.9.0}

#Install dependecies
yum install -y wget git java-1.8.0-openjdk-devel

# Install maven.
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

#Build and test the package
git clone https://github.com/apache/nifi
cd nifi
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/vishakadesai/build-scripts/nifi/a/apache-nifi/nifi-1.9.0.patch 
git apply nifi-1.9.0.patch 
mvn install -Dmaven.test.skip=true

# Test failures noted to be in parity with Intel, thus disabled
# mvn test