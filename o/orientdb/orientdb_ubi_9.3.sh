#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : orientdb
# Version       : 3.2.31
# Source repo   : https://github.com/orientechnologies/orientdb.git
# Tested on     : UBI:9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
# Disclaimer    : This script has been tested in root mode on given
# ==========       platform using the mentioned version of the package.
#                  It may not work as expected with newer versions of the
#                  package and/or distribution. In such case, please
#                  contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=orientdb
PACKAGE_VERSION=${1:-3.2.31}
PACKAGE_URL=https://github.com/orientechnologies/orientdb.git

yum install -y git make wget gcc-c++
#install temurin java21
wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz
tar -C /usr/local -zxf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz
export JAVA_HOME=/usr/local/jdk-21.0.2+13/
export JAVA21_HOME=/usr/local/jdk-21.0.2+13/bin/
export PATH=$PATH:/usr/local/jdk-21.0.2+13/bin/
ln -sf /usr/local/jdk-21.0.2+13/bin/java /usr/bin/
rm -rf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! mvn clean install -Dskiptests=true ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! mvn clean test ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
