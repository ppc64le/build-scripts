#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package         : ehcache3
# Version         : v3.10.8
# Source repo     : https://github.com/ehcache/ehcache3
# Tested on       : UBI:9.3
# Language        : Java
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ehcache3
PACKAGE_VERSION=${1:-v3.10.8}
PACKAGE_URL=https://github.com/ehcache/ehcache3

# Install dependencies and tools.
yum install -y git wget java-1.8.0-openjdk-devel.ppc64le java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-headless.ppc64le xz
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Clone and build source
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! ./gradlew build -x test; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! ./gradlew test -x ':ehcache-impl:test'; then
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
