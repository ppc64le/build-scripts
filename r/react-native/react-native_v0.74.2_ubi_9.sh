#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-native
# Version       : 0.74.2
# Source repo   : https://github.com/facebook/react-native.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript, C, C++
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=react-native
PACKAGE_VERSION=${1:-v0.74.2}
PACKAGE_URL=https://github.com/facebook/$PACKAGE_NAME.git
BUILD_HOME=$(pwd)

# Install required system dependencies
yum install -y git gcc gcc-c++ make cmake python3 python3-pip \
    autoconf automake libtool binutils glibc-devel xz-devel zlib-devel

# Install and configure NVM + Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install 20
nvm alias default 20
nvm use 20

# Global npm/yarn setup with dependencies
npm install -g yarn typescript@5.3.3

# Clone the repository
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies - yarn 
yarn install

# Build the project
ret=0
yarn build || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------------"
    exit 1
fi

# Smoke Test: Check version and package integrity
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./node_modules/${PACKAGE_NAME}/package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS: React Native version matches."
else
    echo "FAIL: React Native version mismatch."
    exit 2
fi

# Run Tests
yarn test || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails------------------------"
    echo "Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success---------------------------"
    echo "Both_Install_and_Test_Success"
    exit 0
fi
