#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : prettier
# Version       : 2.8.8
# Source repo   : https://github.com/prettier/prettier
# Tested on     : UBI:9.5
# Language      : JavaScript
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Set variables
BUILD_HOME=$(pwd)
PACKAGE_NAME=prettier
PACKAGE_URL=https://github.com/prettier/${PACKAGE_NAME}.git
PACKAGE_VERSION=${1:- 2.8.8}
NODE_VERSION=v18.20.8

#Install deps.
yum install -y git gcc gcc-c++ openssl-devel make

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION
node -v

npm install yarn

# Clone the repository
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Install dependencies and run build
ret=0
#yarn install --immutable && yarn build || ret=$?
npx yarn install --immutable && npx yarn build || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "FAIL: Build failed."
    exit 1
fi

#Test
npx yarn test || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "FAIL: Tests failed."
    exit 2
fi

ln -sf $(pwd)/bin/prettier.js /usr/local/bin/prettier

#Smoke test
prettier --version || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "FAIL: Smoke test failed."
    exit 2
else
    echo "Build and test successful!"
fi
