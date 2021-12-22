# ----------------------------------------------------------------------------
#
# Package       : Jackson-dataformat-xml
# Version       : 2.13
# Source repo   : https://github.com/FasterXML/jackson-dataformat-xml
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is 2.13"

# Variables.
PACKAGE_VERSION=2.13
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
PACKAGE_NAME=jackson-dataformat-xml
PACKAGE_URL=https://github.com/FasterXML/jackson-dataformat-xml.git

#For rerunning build
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
fi

# Installation of required sotwares. 
yum update -y
yum install git maven java-11-openjdk-devel -y  
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${PACKAGE_VERSION} found to checkout"
else
  echo  "${PACKAGE_VERSION} not found"
  exit
fi

# Build and test.
mvn test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi

mvn install -DskipTests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi
