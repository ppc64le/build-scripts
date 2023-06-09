#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : graphql-js/
# Version       : v16.3.0
# Source repo   : https://github.com/graphql/graphql-js.git
# Tested on     : UBI 8.3
# Language      : NPM
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=graphql-js/
PACKAGE_VERSION=${1:-v16.3.0}
PACKAGE_URL=https://github.com/graphql/graphql-js.git

dnf install -y git
dnf module install -y nodejs:14

#clone the package

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package.
#Note: one test case is failing related to path on both Power and Intel VMs.
npm ci
npm install
npm test
