#!/bin/bash -e   
# ----------------------------------------------------------------------------
#
# Package       : jboss-logging
# Version       : 3.5.3.Final
# Source repo   : https://github.com/jboss-logging/jboss-logging
# Tested on     : UBI: 9.3
# Language      : Java
# Ci-Check  : True
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
PACKAGE_NAME=jboss-logging
PACKAGE_URL=https://github.com/jboss-logging/jboss-logging.git
PACKAGE_VERSION=${1:-3.5.3.Final}


# install tools and dependent packages
yum install -y git wget java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
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
mvn -B clean install -fae 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
  
 
#Test
mvn test
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0

