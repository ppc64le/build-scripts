#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : flatbuffers
# Version       : v1.12.0,v23.1.21
# Source repo   : https://github.com/google/flatbuffers.git
# Tested on     : UBI 8.5
# Language      : C++
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Ankit.Paraskar@ibm.com, Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=flatbuffers
PACKAGE_VERSION=v23.1.21
PACKAGE_URL=https://github.com/google/flatbuffers.git

# Install required dependencies
yum install -y git wget gcc-c++ cmake

rm -rf $PACKAGE_NAME

# Cloning the repository
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

cmake ./

# Build 
if ! make; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Test
if ! make test; then
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

# We can also test with following command
# ./flattests
