#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : jackson-core
# Version       : jackson-core-2.14.1
# Source repo   : https://github.com/FasterXML/jackson-core.git
# Tested on     : ubi: 8.5
# Travis-Check  : True
# Language      : java
# Script License: Apache License 2.0
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Variables.
PACKAGE_NAME=jackson-core
PACKAGE_VERSION=jackson-core-2.14.1
PACKAGE_VERSION=${1:-$PACKAGE_VERSION}
PACKAGE_URL=https://github.com/FasterXML/jackson-core.git

# For rerunning build
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
fi

# Install required dependencies
#yum -y update
yum install git maven java-11-openjdk-devel -y  
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.17.0.8-2.el8_6.ppc64le  
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and test

mvn clean install -DskipTests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build for $PACKAGE_NAME-$PACKAGE_VERSION ..."
else
  echo  "Failed build for $PACKAGE_NAME-$PACKAGE_VERSION ..."
  exit 1
fi

mvn install
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done test for $PACKAGE_NAME-$PACKAGE_VERSION ..."
else
  echo  "Failed test for $PACKAGE_NAME-$PACKAGE_VERSION ..."
  exit 2
fi
