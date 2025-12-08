#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: commons-daemon
# Version	: rel/commons-daemon-1.2.3
# Source repo	: https://github.com/apache/commons-daemon.git
# Tested on	: UBI 9.3
# Language      : Java
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=commons-daemon
PACKAGE_URL=https://github.com/apache/${PACKAGE_NAME}.git
PACKAGE_VERSION=${1:-rel/commons-daemon-1.2.3}
PACKAGE_BASENAME=${PACKAGE_VERSION#rel/}
MAVEN_VERSION=3.9.9
BUILD_HOME=$(pwd)

# install tools and dependent packages
yum update -y
yum install -y git wget tar java-1.8.0-openjdk-devel

#Install maven
wget https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz
rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz
PATH=$BUILD_HOME/apache-maven-${MAVEN_VERSION}/bin:$PATH

# Cloning the repository from remote to local
cd ${BUILD_HOME}
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build the package
ret=0
mvn -T $(nproc) package || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi

# Test
mvn test || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 2
fi

echo "${PACKAGE_NAME} JAR file is located at: ${BUILD_HOME}/${PACKAGE_NAME}/target/$PACKAGE_BASENAME.jar"
echo "SUCCESS: Build and test success!"
