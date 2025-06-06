#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : less.js
# Version       : v4.2.0
# Source repo   : https://github.com/less/less.js.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=less.js
PACKAGE_VERSION=${1:-v4.2.0}
PACKAGE_URL=https://github.com/less/$PACKAGE_NAME.git
BUILD_HOME=$(pwd)

# Install required dependencies
yum install -y git 

# Install Node.js manually (compatible version)
export NODE_VERSION=20.14.0
cd /tmp
curl -O https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-ppc64le.tar.gz
tar -xzf node-v$NODE_VERSION-linux-ppc64le.tar.gz
export PATH=/tmp/node-v$NODE_VERSION-linux-ppc64le/bin:$PATH

# Install required global packages
npm install -g grunt-cli pnpm

# Clone the repo
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies
pnpm install

# Build the package
cd packages/less
ret=0
pnpm exec grunt clean shell:testbuild || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME: testbuild failed--------------------------------------------"
    exit 1
fi

# Test the package
pnpm exec grunt shell:opts shell:plugin connect || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME: test_failed--------------------------------------------"
    exit 2
fi

# Smoke Test : Check package build version
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
else
    echo "FAIL: $PACKAGE_NAME version mismatch."
    exit 2
fi
