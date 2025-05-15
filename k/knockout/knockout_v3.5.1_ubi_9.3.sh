#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : knockout
# Version       : v3.5.1
# Source repo   : https://github.com/knockout/knockout.git
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript,TypeScript,CSS,HTML
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

PACKAGE_NAME=knockout
PACKAGE_VERSION=${1:-v3.5.1}
PACKAGE_URL=https://github.com/$PACKAGE_NAME/$PACKAGE_NAME.git
BUILD_HOME=$(pwd)

# Install required dependencies
yum install -y git java-17-openjdk-devel

# Set Java environment variables
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Install NVM and Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"

nvm install 20
nvm alias default 20
nvm use 20

# Install npm required dependencies
npm install -g grunt-cli typescript@3.7.5

# Clone the repo
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies
npm install

# Build the project using grunt
ret=0
grunt || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "------------------$PACKAGE_NAME:build_failed--------------------------------------------"
	exit 1
fi

# Run tests using Node.js runner (phantomjs is not supported on ppc64le)
npm test || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "------------------$PACKAGE_NAME:test_failed--------------------------------------------"
	exit 2
fi

# Smoke Test : Check version
PACKAGE_BUILD_VERSION=$(node -e "console.log(require('./package.json').version)")
if [[ "$PACKAGE_BUILD_VERSION" == "${PACKAGE_VERSION#v}" ]]; then
    echo "PASS:$PACKAGE_NAME version v$PACKAGE_BUILD_VERSION built successfully."
else
    echo "FAIL: $PACKAGE_NAME version mismatch."
    exit 2
fi
