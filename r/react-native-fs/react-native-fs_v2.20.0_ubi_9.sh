#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-native-fs
# Version       : v2.20.0
# Source repo   : https://github.com/itinance/react-native-fs
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript, Java
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
# ----------------------------------------------------------------------------

PACKAGE_NAME=react-native-fs
PACKAGE_VERSION=${1:-v2.20.0}
PACKAGE_URL=https://github.com/itinance/${PACKAGE_NAME}
BUILD_HOME=$(pwd)
NODE_VERSION=${2:-20}

# Install system dependencies
yum install -y git java-17-openjdk-devel

# Set JAVA_HOME dynamically
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH="$JAVA_HOME/bin:$PATH"

# Install nvm and Node.js
export NVM_DIR="$HOME/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$NVM_DIR/nvm.sh"
nvm install $NODE_VERSION
nvm use $NODE_VERSION

# Install global npm packages
npm install -g yarn typescript@5.3.3 @react-native-community/cli

# Clone the library
cd "$BUILD_HOME"
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build the library
ret=0
npm install || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------------"
    exit 1
fi

# Smoke Test: Check version and package integrity
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('/$PACKAGE_NAME/package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS: React Native version matches."
else
    echo "FAIL: React Native version mismatch."
    exit 2
fi

echo "Build completed successfully."
