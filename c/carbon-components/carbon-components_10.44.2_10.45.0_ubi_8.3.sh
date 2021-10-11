# ---------------------------------------------------------------------
#
# Package       : carbon-components
# Version       : 10.44.2. 10.45.0
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

#Variables
REPO=https://github.com/carbon-design-system/carbon.git
PACKAGE_VERSION=10.44.2

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 10.44.1, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git make gcc-c++ python3 sed -y
dnf module install -y nodejs:14
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $REPO
cd carbon/
git checkout v$PACKAGE_VERSION
yarn install

#apply patches
sed -i 's/x64/ppc64/g' node_modules/chromedriver/install.js
sed -i 's/x64/ppc64/g' node_modules/gulp-axe-webdriver/node_modules/chromedriver/install.js
sed -i 's/x64/ppc64/g' node_modules/node-sass/test/errors.js

#build
yarn rebuild node-sass
yarn install
yarn build
yarn test

#conclude
echo "Complete!"
