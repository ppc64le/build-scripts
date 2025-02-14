#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xnio
# Version       : 3.8.15.Final
# Source repo   : https://github.com/xnio/xnio
# Tested on     : UBI:9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xnio
PACKAGE_VERSION=${1:-3.8.15.Final}
PACKAGE_URL=https://github.com/xnio/xnio

yum install -y g++ wget git gcc gcc-c++

#Install temurin java17
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
tar -C /usr/local -zxf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
export JAVA_HOME=/usr/local/jdk-17.0.9+9
export JAVA17_HOME=/usr/local/jdk-17.0.9+9
export PATH=$PATH:/usr/local/jdk-17.0.9+9/bin
ln -sf /usr/local/jdk-17.0.9+9/bin/java /usr/bin
rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
tar -zxf apache-maven-3.8.8-bin.tar.gz
cp -R apache-maven-3.8.8 /usr/local
ln -s /usr/local/apache-maven-3.8.8/bin/mvn /usr/bin/mvn
mvn --version

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn -U -B -fae -DskipTests clean install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
mvn clean

if ! mvn test; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
