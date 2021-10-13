# ---------------------------------------------------------------------
#
# Package       : carbon-components
# Version       : 10.9.1, 10.7.3, 10.5.0
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
PACKAGE_VERSION=10.9.1

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 10.9.1, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git make gcc-c++ python2 sed -y
dnf module install -y nodejs:10
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $REPO
cd carbon/
git checkout v$PACKAGE_VERSION
yarn install

#apply patches
YARN_CACHE=$(yarn cache dir)
FILES=$(find $YARN_CACHE -name install.js)
sed -i 's/x64/ppc64/g' $FILES

#build
yarn install
yarn build
yarn test

#conclude
echo "Complete!"
