#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : treelayout
# Version       : v1.0.3
# Source repo   : https://github.com/abego/treelayout.git
# Tested on     : UBI 9.3
# Language      : Java, Others
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=treelayout
PACKAGE_VERSION=${1:-v1.0.3}
PACKAGE_URL=https://github.com/abego/treelayout.git
DIRECTORY=org.abego.treelayout

# install tools and dependent packages
yum install -y git wget unzip sudo make gcc gcc-c++ cmake

#java 8
yum install -y git wget java-1.8.0-openjdk-devel.ppc64le java-1.8.0-openjdk-headless.ppc64le 
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

export M2_HOME=/usr/local/maven

# update the path env. variable
export PATH=$PATH:$M2_HOME/bin

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd $DIRECTORY


#Build and test
mvn clean install
if [ $? != 0 ]
then
  echo "Build and Test failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
exit 0