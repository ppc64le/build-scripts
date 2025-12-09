#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : neo4j-java-driver
# Version       : 5.23.0
# Source repo   : https://github.com/neo4j/neo4j-java-driver
# Tested on     : UBI:9.3
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=neo4j-java-driver
PACKAGE_VERSION=${1:-5.23.0}
PACKAGE_URL=https://github.com/neo4j/neo4j-java-driver

# Install dependencies and tools.
yum update -y
yum install -y git wget java-17-openjdk.ppc64le java-17-openjdk-devel.ppc64le java-17-openjdk-headless.ppc64le python3 xz
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk


# Install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn
rm -f apache-maven-3.8.6-bin.tar.gz
mvn -version


# Clone and build source
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! mvn clean install -DskipTests; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

#Integration tests require another docker environment hence they are skipped.
if ! mvn clean install -DskipITs -P skip-testkit; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
	exit 0
fi
