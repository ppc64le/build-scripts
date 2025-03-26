#!/bin/bash -ex
# --------------------------------------------------------------------------------------------
#
# Package       : log4j-jakarta-web
# Version       : rel/2.23.1
# Source repo   : https://github.com/apache/logging-log4j2
# Tested on     : UBI 9.3 (docker)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# --------------------------------------------------------------------------------------------

PACKAGE_NAME=logging-log4j2/log4j-jakarta-web
ARTIFACT_VERSION=${1:-2.23.1}
ARTIFACT_NAME=log4j-jakarta-web-${ARTIFACT_VERSION}
PACKAGE_VERSION=${2:-rel/${ARTIFACT_VERSION}}
PACKAGE_URL=https://github.com/apache/logging-log4j2
WDIR=$(pwd)
ARTIFACT_PATH=${WDIR}${PACKAGE_NAME}/target/${ARTIFACT_NAME}.jar

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git wget java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn clean install -DskipTests; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
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
      echo "Artifact built at location: $ARTIFACT_PATH"
      exit 0
fi

