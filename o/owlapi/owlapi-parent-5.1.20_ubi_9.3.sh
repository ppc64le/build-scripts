#!/bin/bash -e   
# ----------------------------------------------------------------------------
#
# Package       : owlapi
# Version       : owlapi-parent-5.1.20
# Source repo   : https://github.com/owlcs/owlapi
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
PACKAGE_NAME=owlapi
PACKAGE_URL=https://github.com/owlcs/owlapi.git
PACKAGE_VERSION=${1:-owlapi-parent-5.1.20}


# install tools and dependent packages
yum install -y git wget java-1.8.0-openjdk-devel.ppc64le java-1.8.0-openjdk-headless.ppc64le xz
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# install maven
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
mvn install  >> /tmp/BUILD.log 2>&1
cat /tmp/BUILD.log | grep SUCCESS
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi
  
 
#Test
mvn test  >> /tmp/BUILD.log 2>&1
cat /tmp/BUILD.log | grep SUCCESS
if [ $? != 0 ]
then
  echo "Test execution failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 2
fi
exit 0

