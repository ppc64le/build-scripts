# ---------------------------------------------------------------------
# 
# Package       : graphiql
# Version       : v2.0.1
# Tested on     : UBI 8.3
# Language      : NPM
# Travis-Check  : True
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

set -e

PACKAGE_NAME=graphiql
PACKAGE_VERSION=${1:-v2.0.1}
PACKAGE_URL=https://github.com/graphql/graphiql.git

dnf module install -y nodejs:12

#install dependencies
dnf install -y git 
npm install -g yarn

yarn add global escope eslint-plugin-babel babel-eslint@6.0.0-beta.6 flow-bin@0.61

#clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
#build and test the repo.
#Note: One test case is failing with 'Not supported on platform" issue. This is due to flow binary is not available on Power.
#      Raised issue on flow community : https://github.com/facebook/flow/issues/8732. Test works fine after this issue fix.
yarn install
yarn test
