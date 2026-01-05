#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	: rclone
# Version	: v1.68.1
# Source repo	: https://github.com/rclone/rclone.git
# Tested on	: UBI 9.3
# Language      : Go
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e 
SCRIPT_PACKAGE_VERSION=v1.68.1
PACKAGE_NAME=rclone
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/rclone/rclone.git
BUILD_HOME=$(pwd)

# Install required dependencies
yum install git make gcc gcc-c++ wget fuse3 fuse3-libs fuse3-devel -y

# Install go
wget https://go.dev/dl/go1.23.1.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone the repository 	
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! make ; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Check rclone version
./rclone version

# Run smoke tests
cd cmdtest
if ! go test ; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Success_but_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi