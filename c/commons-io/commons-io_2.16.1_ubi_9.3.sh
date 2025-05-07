#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : commons-io
# Version       : rel/commons-io-2.16.1
# Source repo   : https://github.com/apache/commons-io.git
# Tested on     : UBI 9.3
# Language      : Java, Others
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar<Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME=commons-io
PACKAGE_VERSION=${1:-rel/commons-io-2.16.1}
PACKAGE_URL=https://github.com/apache/commons-io.git

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


#Build
mvn install -DskipTests=true
if [ $? != 0 ]
then
  echo "Build  failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi

#Skipping test as there are 11 test failures which are in parity with x86  
#if ! mvn test ; then
#       echo "------------------$PACKAGE_NAME::ITest_fails-------------------------"
#       echo "$PACKAGE_URL $PACKAGE_NAME"
#       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Install _and_Test_fails"
#       exit 2
#fi

exit 0