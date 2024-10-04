#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : spring-framework
# Version       : v6.2.0-M6
# Source repo   : https://github.com/spring-projects/spring-framework
# Tested on     : UBI:9.3
# Language      : Java
# Travis-Check  : True
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

PACKAGE_NAME=spring-framework
PACKAGE_VERSION=${1:-v6.2.0-M6}
PACKAGE_URL=https://github.com/spring-projects/spring-framework

# Install dependencies and tools.
yum install -y git wget xz

#Install Liberica JDK 21
wget https://download.bell-sw.com/java/21.0.4+9/bellsoft-jdk21.0.4+9-linux-ppc64le.tar.gz
tar -C /usr/local -zxf bellsoft-jdk21.0.4+9-linux-ppc64le.tar.gz
export JAVA_HOME=/usr/local/jdk-21.0.4
export PATH=$PATH:/usr/local/jdk-21.0.4/bin
ln -sf /usr/local/jdk-21.0.4/bin/java /usr/bin
rm -f bellsoft-jdk21.0.4+9-linux-ppc64le.tar.gz

# Clone and build source
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! ./gradlew check antora; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! ./gradlew test; then
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
