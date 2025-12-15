#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : leveldb
# Version       : 1.23
# Source repo   : https://github.com/google/leveldb
# Tested on     : UBI:9.3
# Language      : C++
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
PACKAGE_NAME=leveldb
PACKAGE_VERSION=${1:-1.23}
PACKAGE_URL=https://github.com/google/leveldb

yum install -y git gcc-c++ gcc wget make  python3 yum-utils apr-devel perl openssl-devel automake autoconf libtool cmake

git clone --recurse-submodules $PACKAGE_URL 
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mkdir build
cd build
cmake ..

if ! cmake --build .; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ctest --verbose; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
