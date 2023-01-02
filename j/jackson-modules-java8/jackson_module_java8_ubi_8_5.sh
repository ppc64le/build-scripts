#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jackson-module-parameter-names
# Version       : 2.14.1
# Source repo   : https://github.com/FasterXML/jackson-modules-java8
# Tested on     : ubi: 8.5
# Script License: Apache License 2.0
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
# Language      : Java
# Travis-Check  : True
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is jackson-modules-java8-2.14.1"

#Variables.
PACKAGE_VERSION=jackson-modules-java8-2.14.1
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
PACKAGE_NAME=jackson-modules-java8
PACKAGE_URL=https://github.com/FasterXML/jackson-modules-java8

# Required Dependencies
yum update -y
yum -y install git wget java-11-openjdk-devel.ppc64le

# maven installation
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Removed existing package if any"  
fi


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
mvn install -DskipTests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ......"
else
  echo  "Failed build ......"
fi


mvn test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done  Test..."
else
  echo  "Failed Test......"
  exit
fi
