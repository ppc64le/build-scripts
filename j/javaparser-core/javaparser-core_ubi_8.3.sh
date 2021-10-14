# ----------------------------------------------------------------------------
#
# Package       : javaparser-core
# Version       : javaparser-parent-3.23.1
# Source repo   : https://github.com/javaparser/javaparser
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
echo "       PACKAGE_VERSION is an optional paramater whose default value is javaparser-parent-3.23.1"

#Variables.
PACKAGE_VERSION=javaparser-parent-3.23.1
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
PACKAGE_NAME=javaparser/javaparser-core
PACKAGE_URL=https://github.com/javaparser/javaparser.git

# Installation of required sotwares. 
yum update -y
yum install git maven -y 

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

