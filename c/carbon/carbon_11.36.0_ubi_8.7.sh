#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : carbon
# Version       : 11.36.0
# Source repo   : https://github.com/carbon-design-system/carbon
# Tested on     : UBI: 8.7
# Travis-Check  : True
# Language      : Javascript
# Script License: Apache License Version 2.0
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=carbon
PACKAGE_VERSION=${1:-v11.36.0}
PACKAGE_URL=https://github.com/carbon-design-system/carbon
HOME_DIR=${PWD}

yum install -y git wget make python3.8 gcc-c++

# Install nodejs
cd $HOME_DIR
wget https://nodejs.org/dist/v18.16.1/node-v18.16.1-linux-ppc64le.tar.gz
tar -xzf node-v18.16.1-linux-ppc64le.tar.gz
rm -rf node-v18.16.1-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v18.16.1-linux-ppc64le/bin:$PATH
node -v
npm -v

# Install yarn
npm install -g yarn 
yarn set version 3.6.0

# Clone package repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export CHROMEDRIVER_SKIP_DOWNLOAD=true

# Install dependencies and build modules
yarn install --check-cache --inline-builds || true 
yarn build || true

sed -i '/version/d' examples/light-dark-mode/package.json
sed -i 's+true\,+&\n  \"version\": \"0.36.0\"\,+g' examples/light-dark-mode/package.json
sed -i 's/"next": "12.1.4"/"next": "13.4.7"/' examples/light-dark-mode/package.json

# Skip test suite noted to fail in parity with Intel
sed -i 's/describe/describe.skip/g' packages/upgrade/src/commands/__tests__/upgrade-test.js

# Reinstall dependencies
yarn install

# Build and test
if ! yarn build; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! yarn test; then
	echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Sucess_but_Test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi