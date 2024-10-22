#!/bin/bash -e   
# ----------------------------------------------------------------------------
#
# Package       : undertow
# Version       : 2.3.18.Final
# Source repo   : https://github.com/undertow-io/undertow
# Tested on     : UBI: 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : kotla santhosh<kotla.santhosh@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=undertow
PACKAGE_URL=https://github.com/undertow-io/undertow.git
PACKAGE_VERSION=${1:-2.3.18.Final}


# install tools and dependent packages
yum install -y git wget java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
export M2_HOME=/usr/local/maven
 
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin


# Cloning the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
mvn clean install 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
  
mvn test 
#Test
#mvn -U -B -fae test -Pproxy '-DfailIfNoTests=false' -pl core
#if [ $? != 0 ]
#then
  #echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  #exit 2
#fi
#exit 0

