#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package         : ejs
# Version         : 3.1.10
# Source repo     : https://github.com/mde/ejs.git
# Tested on       : UBI:9.3
# Language        : Node
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME="ejs"
PACKAGE_VERSION="${1:-v3.1.10}"
PACKAGE_URL="https://github.com/mde/ejs.git"
BUILD_HOME="$(pwd)"
export NODE_VERSION=${NODE_VERSION:-20.14.0}

# ------------------------------------
# Install dependencies
# ------------------------------------
yum install -y  git gcc-c++ make python3 python3-pip wget tar

# ------------------------------------
# Install nvm and Node.js
# ------------------------------------
export NVM_DIR="$HOME/.nvm"
cd /tmp
wget https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh
bash install.sh
source "$NVM_DIR/nvm.sh"
nvm install "${NODE_VERSION}"
nvm alias default "${NODE_VERSION}"
nvm use "${NODE_VERSION}"

# ------------------------------------
# Clone the package
# ------------------------------------
cd "$BUILD_HOME"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# ------------------------------------
# Install dependencies
# ------------------------------------
ret=0
npm install || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    exit 1
fi

# ------------------------------------
# Run tests
# ------------------------------------
npx jake test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    exit 2
else
    echo "------------------${PACKAGE_NAME}_${PACKAGE_VERSION}::install_&_test_both_success---"
    exit 0
fi
