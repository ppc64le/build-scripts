#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-native-safe-area-context
# Version       : v4.10.8
# Source repo   : https://github.com/AppAndFlow/react-native-safe-area-context.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=react-native-safe-area-context
PACKAGE_VERSION=${1:-v4.10.8}
PACKAGE_URL=https://github.com/AppAndFlow/${PACKAGE_NAME}.git
BUILD_HOME=$(pwd)

# Install required dependencies
yum install -y git

# Install NVM + Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install 20
nvm alias default 20
nvm use 20

# Install yarn package manager
npm install -g yarn

# Clone the repo
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies
yarn install

# Build the project
if ! yarn prepare; then
    echo "------------------$PACKAGE_NAME:build_failed--------------------------------------------"
    exit 1
fi

# Run the test ( skipping yarn test (package.json), as clang-format not supported by power)
if ! ( yarn validate:eslint && yarn validate:typescript && yarn validate:jest); then
    echo "------------------$PACKAGE_NAME:test_failed---------------------------------------------"
    exit 1
fi

# Smoke Test: Check version
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS:$PACKAGE_NAME version v$PACKAGE_BUILD_VERSION built successfully."
else
    echo "FAIL: $PACKAGE_NAME version mismatch."
    exit 2
fi
