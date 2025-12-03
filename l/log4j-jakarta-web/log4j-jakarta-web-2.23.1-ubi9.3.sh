#!/bin/bash -ex
# --------------------------------------------------------------------------------------------
#
# Package       : log4j-jakarta-web
# Version       : rel/2.23.1
# Source repo   : https://github.com/apache/logging-log4j2
# Tested on     : UBI 9.3 (docker)
# Language      : Java
# Ci-Check  : True
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

PACKAGE_NAME=log4j-jakarta-web
PACKAGE_VERSION=${1:-rel/2.23.1}
PACKAGE_URL=https://github.com/apache/logging-log4j2.git
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
WDIR=$(pwd)
MAVEN_VERSION=${MAVEN_VERSION:-3.9.11}
ARTIFACT_PATH=${WDIR}/logging-log4j2/${PACKAGE_NAME}/target/${PACKAGE_NAME}-${PACKAGE_VERSION#rel/}.jar

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git wget java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install maven
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz
mv apache-maven-${MAVEN_VERSION} /opt/maven-${MAVEN_VERSION}
rm apache-maven-${MAVEN_VERSION}-bin.tar.gz
ln -sf /opt/maven-${MAVEN_VERSION}/bin/mvn /usr/bin/mvn
export MAVEN_HOME=/opt/maven-${MAVEN_VERSION}
export PATH=$MAVEN_HOME/bin:$PATH

git clone $PACKAGE_URL
cd logging-log4j2 && git checkout $PACKAGE_VERSION
cd $PACKAGE_NAME

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

