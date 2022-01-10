# -----------------------------------------------------------------------------
#
# Package       : remarkable
# Version       : v2.0.1
# Source repo   : https://github.com/jonschlinkert/remarkable.git
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

#!/bin/bash
set -e
PACKAGE_NAME=remarkable
PACKAGE_VERSION=${1:-v2.0.1}
PACKAGE_URL=https://github.com/jonschlinkert/remarkable.git

dnf install -y git
dnf module install -y nodejs:12
npm install -g yarn
yarn add lint
npm install remarkable --save
#clone the repo.
git clone  $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#build  and test the package
yarn install
yarn lint
yarn test:ci
