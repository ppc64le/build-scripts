#!/bin/bash -e
###############################################################################
#
# Package         : eslint
# Version         : v8.57.0
# Source repo     : https://github.com/eslint/eslint.git
# Language        : JavaScript
# Tested on       : UBI 9.3 (ppc64le)
# Travis-Check    : True
# Maintainer      : Amit Kumar <amit.kumar282@ibm.com>
# License         : Apache License, Version 2.0 or later
#
# Disclaimer      : This script has been tested in root mode on the specified
#                   platform using the stated version. It may not work as 
#                   expected with newer versions or different environments.
#
###############################################################################

# -------------------------------
# Configuration & Initialization
# -------------------------------
PACKAGE_NAME="eslint"
PACKAGE_VERSION="${1:-v8.57.0}"
PACKAGE_URL="https://github.com/${PACKAGE_NAME}/${PACKAGE_NAME}.git"
NODE_VERSION="${NODE_VERSION:-20}"
BUILD_HOME="$(pwd)"

# -------------------------------
# Install Dependencies
# -------------------------------
yum install -y git make gcc-c++ python3

# Install NVM and Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME/.bashrc"
nvm install "$NODE_VERSION" > /dev/null
nvm use "$NODE_VERSION"

# -------------------------------
# Clone Repository
# -------------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}" 
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# -------------------------------
# Install Package Dependencies
# -------------------------------
ret=0
npm install || ret=$?
if [ $ret -ne 0 ]; then
   echo "------------------ ${PACKAGE_NAME}: Install abd build failed ------------------"
   exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Install abd build Passed ------------------"
fi

# -------------------------------
# Run Tests
# -------------------------------
npm test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
	exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Test Passed ------------------"
fi

# -------------------------------
# Smoke Test - Validate Version
# -------------------------------
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS: $PACKAGE_NAME version $PACKAGE_VERSION built successfully."
	exit 0
else
    echo "FAIL: $PACKAGE_NAME version mismatch."
    exit 2
fi
