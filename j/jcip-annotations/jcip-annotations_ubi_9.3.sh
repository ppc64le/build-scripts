#!/bin/bash -e   
# ----------------------------------------------------------------------------
#
# Package       : jcip-annotations 
# Version       : jcip-annotations-1.0-1
# Source repo   : https://github.com/stephenc/jcip-annotations 
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
PACKAGE_NAME=jcip-annotations
PACKAGE_URL=https://github.com/stephenc/jcip-annotations.git
PACKAGE_VERSION=${1:-jcip-annotations-1.0-1}


# install tools and dependent packages
yum install -y git wget java-1.8.0-openjdk-devel.ppc64le java-1.8.0-openjdk-headless.ppc64le xz
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn
rm -f apache-maven-3.8.6-bin.tar.gz
mvn -version


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
  
 
#Test
mvn test
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0

