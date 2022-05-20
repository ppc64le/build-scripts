# ----------------------------------------------------------------------------
#
# Package       : jackson-dataformat-csv
# Version       : 2.11.0
# Source repo   : https://github.com/FasterXML/jackson-dataformats-text
# Tested on     : ubi_8
# Language      : Java
# Travis-Check  : True
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

PACKAGE_VERSION=jackson-dataformats-text-2.11.0

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is jackson-dataformats-text-2.11.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
PACKAGE_NAME=jackson-dataformats-text/csv/
PACKAGE_URL=https://github.com/FasterXML/jackson-dataformats-text.git

set -e

#For rerunning build
if [ -d "jackson-dataformats-text" ] ; then
  rm -rf jackson-dataformats-text
fi

# Installation of required sotwares.
# yum update -y
yum install git wget java-11-openjdk-devel -y

# Maven installation steps.
yum install maven -y
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

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