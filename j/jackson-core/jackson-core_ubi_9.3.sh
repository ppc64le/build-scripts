#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : jackson-core
# Version       : 2.17.0
# Source repo   : https://github.com/FasterXML/jackson-core
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

PACKAGE_NAME=jackson-core
PACKAGE_VERSION=${1:-jackson-core-2.17.0}
PACKAGE_URL=https://github.com/FasterXML/jackson-core

# install tools and dependent packages
yum install -y git wget

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
cd
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
./mvnw -B -q -ff -ntp verify
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
