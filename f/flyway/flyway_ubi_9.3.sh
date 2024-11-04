#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : flyway
# Version       : cxf-4.0.4
# Source repo   : https://github.com/flyway/flyway
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

PACKAGE_NAME=flyway
PACKAGE_VERSION=${1:-flyway-10.15.2}
PACKAGE_URL=https://github.com/flyway/flyway

yum install git wget -y

#Install temurin java17
wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
tar -C /usr/local -zxf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
export JAVA_HOME=/usr/local/jdk-17.0.9+9
export JAVA17_HOME=/usr/local/jdk-17.0.9+9
export PATH=$PATH:/usr/local/jdk-17.0.9+9/bin
ln -sf /usr/local/jdk-17.0.9+9/bin/java /usr/bin
rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -zxf apache-maven-3.6.3-bin.tar.gz
cp -R apache-maven-3.6.3 /usr/local
ln -s /usr/local/apache-maven-3.6.3/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn -B install -e --file pom.xml -pl -:flyway-database-mongodb ; then
    echo "------------------$PACKAGE_NAME:Install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! mvn -B test -e --file pom.xml -pl -:flyway-database-mongodb ; then
    echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Install_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi