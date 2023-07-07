#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: ajv-i18n
# Version	: v4.1.0
# Source repo	: https://github.com/ajv-validator/ajv-i18n
# Tested on	: UBI: 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ajv-i18n
PACKAGE_VERSION=${1:-v4.1.0}
PACKAGE_URL=https://github.com/ajv-validator/ajv-i18n
export NODE_VERSION=${NODE_VERSION:-v14}

yum install -y git 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install "$NODE_VERSION"
npm install -g npm@8

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install; then
	echo "------------------Build_fails---------------------"
	exit 1
else
	echo "------------------Build_success-------------------------"
	
fi

git submodule update --init

if ! npm test; then
	echo "------------------Test_fails---------------------"
	exit 1
else
	echo "------------------Test_success-------------------------"
	
fi