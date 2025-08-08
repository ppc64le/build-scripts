#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : jsonp-api
# Version       : 2.1.3-RELEASE
# Source repo   : https://github.com/jakartaee/jsonp-api
# Tested on     : UBI:9.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Set variables
WDIR=$(pwd)
PACKAGE_NAME=jsonp-api
PACKAGE_URL=https://github.com/jakartaee/${PACKAGE_NAME}.git
PACKAGE_VERSION=${1:- 2.1.3-RELEASE}

#Install deps.
yum install -y git wget gcc gcc-c++ openssl-devel java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Install Maven
MAVEN_VERSION=3.8.1
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xvzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
cp -R apache-maven-$MAVEN_VERSION /usr/local
ln -s /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/bin/mvn

# Clone the repository
cd $WDIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd api
if !  mvn -U -C clean install -DskipTests ; then
      echo "------------------$PACKAGE_NAME: API compilation Fails---------------------------------"
      echo "$PACKAGE_VERSION $PACKAGE_NAME"
      echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | API compilation Fails"
      exit 1
fi

if !  mvn test ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
      exit 0
fi
