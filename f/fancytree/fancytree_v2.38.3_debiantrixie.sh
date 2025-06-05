#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package        : fancytree
# Version        : v2.38.3
# Source repo    : https://github.com/mar10/fancytree.git
# Tested on      : UBI 9.3 (ppc64le)
# Maintainer     : Amit Kumar <amit.kumar282@ibm.com>
# Language       : Node.js
# Travis-Check   : False
# Script License: Apache License, Version 2 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="fancytree"
PACKAGE_VERSION="${1:-v2.38.3}"
PACKAGE_URL="https://github.com/mar10/${PACKAGE_NAME}.git"
NODE_VERSION="${2:-20}"
BUILD_HOME="$(pwd)"

echo "Installing required packages..."
apt update -y
apt install -y git curl chromium

# ---------------------------
# Node.js Setup (via NVM)
# ---------------------------
echo "Installing Node.js using NVM (version ${NODE_VERSION})..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install "${NODE_VERSION}"
nvm alias default "${NODE_VERSION}"
nvm use "${NODE_VERSION}"

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# ---------------------------
# Puppeteer Setup (chrome)
# ---------------------------
export PUPPETEER_PRODUCT=chrome
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export CHROMIUM_FLAGS='--no-sandbox'

# ---------------------------
# Install Dependencies and Run Tests
# ---------------------------
echo "Installing package dependencies..."
npm install

ret=0
npm test || ret=$?
if [ $ret -ne 0 ]; then
    echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
	exit 1
else
    echo "------------------ ${PACKAGE_NAME}: Test Passed ------------------"
    exit 0
fi

# ---------------------------
# Smoke test: Check version
# ---------------------------
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS: $PACKAGE_NAME version $PACKAGE_VERSION built successfully."
    exit 0
else
    echo "FAIL: $PACKAGE_NAME version mismatch."
    exit 2
fi
