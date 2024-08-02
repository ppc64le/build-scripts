#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : lz4-java
# Version       : master
# Source repo   : https://github.com/lz4/lz4-java
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

PACKAGE_NAME=lz4-java
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/lz4/lz4-java

yum install git wget unzip gcc-c++ gcc java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless lz4 lz4-devel lz4-libs -y
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#install ant
wget -c https://mirrors.advancedhosters.com/apache/ant/binaries/apache-ant-1.10.14-bin.zip
unzip apache-ant-*.zip
mv apache-ant-*/ /usr/local/ant
export ANT_HOME="/usr/local/ant"
export PATH="$PATH:/usr/local/ant/bin"

dnf -y install https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/xxhash-libs-0.8.2-1.el9.ppc64le.rpm
dnf -y install https://rpmfind.net/linux/centos-stream/9-stream/CRB/ppc64le/os/Packages/xxhash-devel-0.8.2-1.el9.ppc64le.rpm

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule init
git submodule update
mkdir -p src/lz4/lib

if ! ant ivy-bootstrap ; then
    echo "------------------$PACKAGE_NAME:Install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ant test ; then
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
