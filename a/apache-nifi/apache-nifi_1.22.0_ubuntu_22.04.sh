#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : nifi
# Version       : 1.22.0
# Source repo   : https://github.com/apache/nifi
# Tested on     : Ubuntu: 22.04
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_VERSION=${1:-rel/nifi-1.22.0}
HOME_DIR=`pwd`

# Install dependecies
apt update
apt install -y wget git

# Install java
apt install -y openjdk-17-jdk
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
export PATH=$JAVA_HOME/bin:$PATH

# Install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

# Build the package
git clone https://github.com/apache/nifi
cd nifi
git checkout $PACKAGE_VERSION

find="<additionalJOption>\-J\-Xmx512m<\/additionalJOption>"
replace="<additionalJOptions>\
<additionalJOption>\-J\-Xmx3g</additionalJOption>\
<additionalJOption>\-J\-XX:+UseG1GC<\/additionalJOption>\
<additionalJOption>\-J\-XX:ReservedCodeCacheSize=1g<\/additionalJOption>\
<\/additionalJOptions>"
sed -i "s#$find#$replace#g" pom.xml

if ! mvn install -Dmaven.test.skip=true; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_success-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Success |  Install_Success"
	exit 0
fi

# Test failures noted to be in parity with Intel, thus disabled
# if ! mvn test; then
# 	echo "------------------$PACKAGE_NAME:test_fails---------------------"
#   echo "$PACKAGE_URL $PACKAGE_NAME"
#   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
# 	exit 1
# else
# 	echo "------------------$PACKAGE_NAME:test_success-------------------------"
#   echo "$PACKAGE_URL $PACKAGE_NAME"
# 	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Test_Success"
# 	exit 0
# fi