#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : zjsonpatch
# Version       : 0.4.16
# Source repo   : https://github.com/flipkart-incubator/zjsonpatch
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

PACKAGE_NAME=zjsonpatch
PACKAGE_VERSION=${1:-0.4.16}
PACKAGE_URL=https://github.com/flipkart-incubator/zjsonpatch

# Install dependencies and tools.
yum update -y
yum install -y git wget java-11-openjdk.ppc64le java-11-openjdk-devel.ppc64le java-11-openjdk-headless.ppc64le python3 xz
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk


# Install maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
tar -xvzf apache-maven-3.9.9-bin.tar.gz
cp -R apache-maven-3.9.9 /usr/local
ln -s /usr/local/apache-maven-3.9.9/bin/mvn /usr/bin/mvn
rm -f apache-maven-3.9.9-bin.tar.gz
mvn -version


# Clone and build source
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if !mvn clean install -DskipTests -Dgpg.skip; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if !mvn test; then
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
