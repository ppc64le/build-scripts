#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : alasql
# Version       : v4.5.1
# Source repo   : https://github.com/AlaSQL/alasql
# Tested on     : UBI:9.3
# Language      : JavaScript
# Ci-Check  : True
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
PACKAGE_NAME=alasql
PACKAGE_URL=https://github.com/AlaSQL/${PACKAGE_NAME}.git
PACKAGE_VERSION=${1:- v4.5.1}
NODE_VERSION=v20.19.0

#Install deps.
yum install -y git 

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION
node -v

#Install yarn
npm install -g yarn 
yarn -v

# Clone the repository
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
ret=0
yarn && yarn build && yarn install-g || ret=$?
if [ "$ret" -ne 0 ]
then
    exit 1
fi

#Test
yarn test || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "FAIL: Tests failed."
    exit 2
fi

export ALASQL_BIN="$HOME/.nvm/versions/node/$NODE_VERSION/bin/alasql"

#Smoke test
$ALASQL_BIN --version || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "FAIL: Smoke test failed."
    exit 2
fi


#conclude
echo "Build and test successful!"
echo "AlaSQL binary is available at [$ALASQL_BIN]."
