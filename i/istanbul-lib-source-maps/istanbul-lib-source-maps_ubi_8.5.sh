#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : istanbul-lib-source-maps
# Version       : 4.0.1
# Source repo   : https://github.com/istanbuljs/istanbuljs
# Tested on     : UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Ambuj Kumar <Ambuj.Kumar3@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORK_DIR=`pwd`

PACKAGE_NAME=istanbul-lib-source-maps
PACKAGE_VERSION=${1:-istanbul-lib-source-maps-v4.0.1}
PACKAGE_URL=https://github.com/istanbuljs/istanbuljs

# install dependencies
#yum update -y
yum install git wget unzip -y

# install nodejs
dnf module install nodejs:12 -y
#dnf install nodejs -y

# clone package
cd $WORK_DIR
if [ -d "istanbuljs" ] ; then
  rm -rf istanbuljs
fi

git clone $PACKAGE_URL
cd istanbuljs
git checkout $PACKAGE_VERSION
cd /istanbuljs/packages/istanbul-lib-source-maps

# to install
npm install yarn -g
yarn install

# to execute tests
yarn test
