#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : sizeof
# Version       : v0.4.3
# Source repo   : https://github.com/ehcache/sizeof
# Tested on     : UBI:9.3
# Language      : Java
# Ci-Check  : True
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

PACKAGE_NAME=sizeof
PACKAGE_VERSION=${1:-v0.4.3}
PACKAGE_URL=https://github.com/ehcache/sizeof

yum install git wget java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless -y
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -zxf apache-maven-3.6.3-bin.tar.gz
cp -R apache-maven-3.6.3 /usr/local
ln -s /usr/local/apache-maven-3.6.3/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn clean install -DskipTests=true ; then
    echo "------------------$PACKAGE_NAME:Install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! mvn test ; then
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
