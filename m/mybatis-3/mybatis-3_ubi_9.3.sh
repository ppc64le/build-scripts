#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : mybatis-3
# Version       : mybatis-3.5.16
# Source repo   : https://github.com/mybatis/mybatis-3
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

PACKAGE_NAME=mybatis-3
PACKAGE_VERSION=${1:-mybatis-3.5.16}
PACKAGE_URL=https://github.com/mybatis/mybatis-3

yum install -y java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless git wget gcc gcc-c++
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz
tar -zxf apache-maven-3.9.6-bin.tar.gz
cp -R apache-maven-3.9.6 /usr/local
ln -s /usr/local/apache-maven-3.9.6/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./mvnw clean install -B -V  --no-transfer-progress -D"license.skip=true" -D"jacoco.skip=true" ; then
    echo "------------------$PACKAGE_NAME:Install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ./mvnw test -B -V  --no-transfer-progress -D"license.skip=true" -D"jacoco.skip=true" ; then
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