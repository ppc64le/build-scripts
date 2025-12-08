#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : javassist
# Version       : rel_3_30_2_ga
# Source repo   : https://github.com/jboss-javassist/javassist
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

PACKAGE_NAME=javassist
PACKAGE_VERSION=${1:-rel_3_30_2_ga}
PACKAGE_URL=https://github.com/jboss-javassist/javassist

# install tools and dependent packages
yum install -y git wget unzip sudo make gcc gcc-c++ cmake

# setup java environment
yum install -y java java-devel

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

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

#Build and test
mvn clean install >> /tmp/BUILD.log 2>&1
cat /tmp/BUILD.log | grep 'SUCCESS'
if [ $? != 0 ]
then
  echo "Build and Test failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
exit 0
