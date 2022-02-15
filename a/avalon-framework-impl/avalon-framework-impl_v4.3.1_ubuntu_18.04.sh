#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package       : avalon-framework-impl
# Version       : 4.3.1
# Source repo   : https://repo1.maven.org/maven2/org/apache/avalon/avalon-framework/
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Jotirling Swami <Jotirling.Swami1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

set -ex

#Variables
PACKAGE_NAME=avalon-framework-impl
PACKAGE_VERSION=4.3.1
PACKAGE_URL=https://repo1.maven.org/maven2/org/apache/avalon/framework/avalon-framework-impl

#Extract version from command line
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is $PACKAGE_VERSION and building for ${1:-$PACKAGE_VERSION}"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
apt update -y && apt install -y git openjdk-8-jdk

#Home dir
HOME_DIR=`pwd`

#install maven 
apt install -y wget
wget https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
tar xzf apache-maven-3.8.4-bin.tar.gz
ln -s apache-maven-3.8.4 maven
export M2_HOME=$HOME_DIR/maven
export PATH=${M2_HOME}/bin:${PATH}
mvn -version

#Clone repo
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


#Get the sources
cd $HOME_DIR
mkdir ${PACKAGE_NAME}
cd $HOME_DIR/$PACKAGE_NAME
if ! wget ${PACKAGE_URL}/${PACKAGE_VERSION}/${PACKAGE_NAME}-${PACKAGE_VERSION}.pom ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

mv ${PACKAGE_NAME}-${PACKAGE_VERSION}.pom pom.xml

mkdir -p ${PACKAGE_NAME}/src/java
mkdir -p ${PACKAGE_NAME}/src/test

cd  ${PACKAGE_NAME}/src/java
if ! wget ${PACKAGE_URL}/${PACKAGE_VERSION}/${PACKAGE_NAME}-${PACKAGE_VERSION}-sources.jar ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

jar xf ${PACKAGE_NAME}-${PACKAGE_VERSION}-sources.jar
rm -f ${PACKAGE_NAME}-${PACKAGE_VERSION}-sources.jar

#Build and test
cd $HOME_DIR/$PACKAGE_NAME
if ! mvn clean install -DskipTests ; then
	echo "------------------$PACKAGE_NAME:build_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! mvn test verify; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
    find $HOME_DIR/$PACKAGE_NAME -name *.jar
    echo "Complete!"
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi
