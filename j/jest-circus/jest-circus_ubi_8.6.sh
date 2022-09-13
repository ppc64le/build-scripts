#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jest-circus
# Version	: v27.0.5
# Source repo	: https://github.com/facebook/jest
# Tested on	: UBI 8.6
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jest-circus
PACKAGE_VERSION=${1:-v27.0.5}
PACKAGE_URL=https://github.com/facebook/jest

dnf install -y wget git yum-utils nodejs nodejs-devel nodejs-packaging npm  

curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#Install jest-circus
npm install $PACKAGE_NAME@$PACKAGE_VERSION

#Run tests
git clone $PACKAGE_URL jest
cd jest 
git checkout $PACKAGE_VERSION
yarn add --dev jest@v27.0.5
yarn add --dev jest-circus@v27.0.5
npx browserslist@latest --update-db
yarn install
yarn build


#Note that there are test failures which are in parity with Intel. Details are provided in the README file.

if ! yarn jest ./packages/jest-circus/ 2>&1 | tee test.log ; then
     	echo "------------------$PACKAGE_NAME:test_fails-------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" 
		exit 1
else
		echo "------------------$PACKAGE_NAME:test_success-------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  test_success" 
		exit 1
fi