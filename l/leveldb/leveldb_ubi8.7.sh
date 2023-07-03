#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: leveldb
# Version	: 1.23
# Source repo	: https://github.com/google/leveldb.git
# Tested on	: UBI 8.7
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=leveldb
PACKAGE_VERSION=${1:-1.23}
PACKAGE_URL=https://github.com/google/leveldb.git

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install -y git gcc-c++ gcc wget make  python38 yum-utils apr-devel perl openssl-devel automake autoconf libtool cmake

# Clone and build code.
cd $HOME
git clone --recurse-submodules $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
mkdir build
cd build
cmake ..

if ! cmake --build . ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

 if ! ctest --verbose; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
