#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: babel-runtime-corejs3
# Version	: v7.14.0
# Source repo	: https://github.com/babel/babel
# Tested on	: UBI 8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.Khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=babel-runtime-corejs3
PACKAGE_VERSION=${1:-v7.14.0}
PACKAGE_URL=https://github.com/babel/babel

yum -y install git wget gcc-c++ make 

NODE_VERSION=v12.22.1
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

#install yarn
npm install yarn -g

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL
cd babel
git checkout $PACKAGE_VERSION

#build babel
make bootstrap
make build

#test only requested npm package
TEST_ONLY=$PACKAGE_NAME make test

exit 0

