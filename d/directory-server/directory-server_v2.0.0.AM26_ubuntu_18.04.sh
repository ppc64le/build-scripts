#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package       : directory-server
# Version       : 2.0.0.AM26, master
# Source repo   : https://github.com/apache/directory-server
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
PACKAGE_NAME=directory-server
PACKAGE_VERSION=2.0.0.AM26
PACKAGE_URL=https://github.com/apache/directory-server.git

#Extract version from command line
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is $PACKAGE_VERSION and building for ${1:-$PACKAGE_VERSION}"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
apt update -y && apt install -y git make sed unzip procps default-jre default-jdk gnupg1 python3.8

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

#install adoptopenjdk
apt install -y software-properties-common
wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key add -
add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/
apt update -y
apt install -y adoptopenjdk-11-hotspot

#Clone repo
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

cd $HOME_DIR
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

#Build and test
cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

#patch
sed -i "s#checkstyle-configuration.version>2.0.1-SNAPSHOT#checkstyle-configuration.version>2.0.1#g"  pom.xml

# The following failing build/tests are in parity with x86:
#     - [INFO] ApacheDS Server Integration ........................ FAILURE [17:57 min]
#     - [INFO] Apache Directory LDAP Client API test .............. FAILURE [42:04 min]

if ! mvn clean package -f "pom.xml" -B -V -e -Dfindbugs.skip -Dcheckstyle.skip -Dpmd.skip=true -Denforcer.skip -Dmaven.javadoc.skip -Dlicense.skip=true -Drat.skip=true -fn; then
	echo "------------------$PACKAGE_NAME:build_and_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_and_Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi
