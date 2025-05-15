#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-native-device-info
# Version       : v11.1.0
# Source repo   : https://github.com/react-native-device-info/react-native-device-info.git
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

PACKAGE_NAME=react-native-device-info
PACKAGE_VERSION=${1:-v11.1.0}
PACKAGE_URL=https://github.com/${PACKAGE_NAME}/${PACKAGE_NAME}.git
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
if ! yarn build; then
    echo "------------------$PACKAGE_NAME:build_failed--------------------------------------------"
    exit 1
fi

# Run the test
if ! yarn test; then
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
