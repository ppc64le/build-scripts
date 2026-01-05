#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rocksdb
# Version       : v9.4.0
# Source repo   : https://github.com/facebook/rocksdb
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
PACKAGE_NAME=rocksdb
PACKAGE_VERSION=${1:-v9.4.0}
PACKAGE_URL=https://github.com/facebook/rocksdb

curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y epel-release-latest-9.noarch.rpm
rm -f epel-release-latest-9.noarch.rpm

yum install -y git gcc-c++ gcc wget make  python3 yum-utils apr-devel perl openssl-devel automake autoconf libtool cmake gflags  gflags-devel

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

if ! ctest -R "DBBasicTest"; then
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


