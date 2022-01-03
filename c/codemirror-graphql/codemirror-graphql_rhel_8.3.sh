# ---------------------------------------------------------------------
# 
# Package       : graphiql
# Version       : v2.0.1
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/graphql/graphiql.git
PACKAGE_VERSION=2.0.1

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
dnf update -y
dnf module install -y nodejs:12
#install dependencies
dnf install -y git 
#export the path

npm install -g yarn

yarn add global escope eslint-plugin-babel babel-eslint@6.0.0-beta.6 flow-bin@0.61

#clone the repo
git clone $REPO
cd graphiql/
git checkout v$PACKAGE_VERSION
#build and install the repo.
yarn install

#test 
#Note: 1 test case is failing related to platform not supported.
yarn test
