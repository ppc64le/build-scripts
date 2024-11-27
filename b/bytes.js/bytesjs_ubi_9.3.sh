#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	    : bytes.js
# Version	    : 3.1.2
# Source repo	: https://github.com/visionmedia/bytes.js
# Tested on	    : UBI 9.3
# Language      : JavaScript
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer:   This script has been tested in root mode on given
# ==========    platform using the mentioned version of the package.
#               It may not work as expected with newer versions of the
#               package and/or distribution. In such case, please
#               contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_NAME=bytes.js
PACKAGE_VERSION=3.1.2
PACKAGE_URL=https://github.com/visionmedia/bytes.js
NODE_VERSION=${NODE_VERSION:-22}

dnf update -y
yum install -y python3 python3-devel.ppc64le git gcc gcc-c++ libffi make libpng-devel automake openssl-devel libtool procps-ng
echo "alias python=python3" >> ~/.bashrc
source ~/.bashrc
dnf install python3-pip
pip3 --version

# Install Node js 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "Installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION
npm --version
npm install -g yarn grunt-bump xo testem acorn

HOME_DIR=`pwd`
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
# PACKAGE_VERSION=$(jq -r ".version" package.json)

if ! npm install && npm audit fix && npm audit fix --force; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi