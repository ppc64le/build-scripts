#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : jackson-dataformat-xml
# Version       : jackson-dataformat-xml-2.14.1
# Source repo   : https://github.com/FasterXML/jackson-dataformat-xml
# Tested on     : ubi 8.5
# Language      : java
# Travis-Check  : True
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
PACKAGE_NAME=jackson-dataformat-xml
PACKAGE_VERSION=jackson-dataformat-xml-2.14.1
PACKAGE_VERSION=${1:-$PACKAGE_VERSION}
PACKAGE_URL=https://github.com/FasterXML/jackson-dataformat-xml

# Install required dependencies
yum install git maven java-11-openjdk-devel -y  
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.17.0.8-2.el8_6.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build
mvn install -DskipTests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit 1
fi

# Test
mvn test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi
