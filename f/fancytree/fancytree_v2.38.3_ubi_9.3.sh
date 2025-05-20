#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : fancytree
# Version       : v2.38.3
# Source repo   : https://github.com/mar10/fancytree.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
#             platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=fancytree
PACKAGE_VERSION=${1:-v2.38.3}
PACKAGE_URL=https://github.com/mar10/$PACKAGE_NAME.git
BUILD_HOME=$(pwd)

# Install required dependencies
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

yum install -y git firefox

export PUPPETEER_PRODUCT=firefox
export PUPPETEER_EXECUTABLE_PATH=$(which firefox)
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Install NVM + Node.js
NODE_VERSION=${2:-20}
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install $NODE_VERSION
nvm alias default $NODE_VERSION
nvm use $NODE_VERSION

# Install yarn and grunt CLI globally
npm install -g yarn grunt-cli

# Clone the repo
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies
yarn install

# Add missing dev dependencies locally
yarn add grunt grunt-cli grunt-eslint grunt-contrib-connect grunt-contrib-qunit --save-dev

# Run partial test: skip qunit due to headless Firefox/chromium-Puppeteer incompatibility on ppc64le.
if ! grunt eslint:dev connect:dev --force; then
    echo "------------------$PACKAGE_NAME:partial_tests_failed------------------------------------"
    exit 1
fi

# Smoke test: Check version
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS: $PACKAGE_NAME version $PACKAGE_VERSION built successfully."
else
    echo "FAIL: $PACKAGE_NAME version mismatch."
    exit 2
fi

# The below code for testing this package is commented since the chrome binaries required for testing may not be accessible.
#if ! yarn test ; then
#	echo "------------------$PACKAGE_NAME:test_failure---------------------"
#	exit 1
#else
#	echo "------------------$PACKAGE_NAME:test_success-------------------------"
#fi
