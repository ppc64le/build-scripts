#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : nashorn
# Version       : main
# Source repo   : https://github.com/openjdk/nashorn
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

PACKAGE_NAME=nashorn
PACKAGE_VERSION=${1:-main}
PACKAGE_URL=https://github.com/openjdk/nashorn

yum install -y wget git java-17 java-17-devel java-17-openjdk-devel unzip make
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

#Install ant
wget -c https://mirrors.advancedhosters.com/apache/ant/binaries/apache-ant-1.10.14-bin.zip
unzip apache-ant-*.zip
mv apache-ant-*/ /usr/local/ant
export ANT_HOME="/usr/local/ant"
export PATH="$PATH:/usr/local/ant/bin"

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd make/nashorn

if ! ant jar ; then
    echo "------------------$PACKAGE_NAME:Install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ant get-test262 && ant test262-parallel ; then
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