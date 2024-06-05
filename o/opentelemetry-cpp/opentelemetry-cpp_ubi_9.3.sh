#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opentelemetry-cpp
# Version       : v1.15.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : UBI:9.3
# Language      : C++
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
PACKAGE_NAME=opentelemetry-cpp
PACKAGE_VERSION=${1:-v1.15.0}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-cpp


yum install -y git gcc-c++ gcc wget make  python3 yum-utils apr-devel perl openssl-devel automake autoconf libtool cmake

#install gtest
git clone https://github.com/google/googletest.git
cd googletest/
git checkout v1.14.0
mkdir build
cd build
cmake .. 
make &&  make install
cd ../..

#install benchmark 
git clone https://github.com/google/benchmark.git
cd benchmark
cmake -E make_directory "build"
cmake -E chdir "build" cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on -DCMAKE_BUILD_TYPE=Release ../
cmake --build "build" --config Release
cmake -E chdir "build" ctest --build-config Release
cmake --build "build" --config Release --target install
cd ../..

git clone --recursive $PACKAGE_URL 
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
