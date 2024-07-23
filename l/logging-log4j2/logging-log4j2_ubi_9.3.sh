#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : logging-log4j2
# Version       : rel/2.22.1
# Source repo   : https://github.com/apache/logging-log4j2.git
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
#            It may not work as expected with newer versions of the
#            package and/or distribution. In such case, please
#            contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=logging-log4j2
PACKAGE_VERSION=${1:-rel/2.22.1}
PACKAGE_URL=https://github.com/apache/logging-log4j2.git

# install tools and dependent packages
yum install -y git wget

# setup java environment
yum install -y gcc gcc-c++ java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless tzdata-java

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

#Build
mvn clean install -DskipTests
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi

#Test
mvn clean install -pl -:log4j-mongodb3,-:log4j-mongodb4,-:log4j-core-test >> /tmp/BUILD.log 2>&1
cat /tmp/BUILD.log | grep 'SUCCESS'

if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0
