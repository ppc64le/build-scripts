#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : googletest
# Version       : v1.14.0
# Source repo   : https://github.com/google/googletest
# Tested on     : UBI: 8.7
# Language      : c++
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
export PACKAGE_VERSION=${1:-"v1.14.0"}
export PACKAGE_NAME=googletest
export PACKAGE_URL=https://github.com/google/googletest


# Install dependencies
virtual_root=`pwd`
yum install -y make gcc gcc-c++ git cmake
export GTEST_DIR=$virtual_root/googletest/

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
mkdir builddir 
cd builddir 
cmake -Dgtest_build_tests=ON ${GTEST_DIR} 

# Build package
if !(make) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(make test); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi