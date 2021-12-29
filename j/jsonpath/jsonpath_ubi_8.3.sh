# ----------------------------------------------------------------------------
#
# Package       : jsonpath
# Version       : 1.1.0
# Source repo   : https://github.com/dchester/jsonpath
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# variables
REPO=https://github.com/dchester/jsonpath
PACKAGE_VERSION=1.1.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.1.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

# install required dependencies
yum update -y
yum install git wget -y
yum module install nodejs:10 -y

# clone package
git clone $REPO
cd jsonpath/
git checkout $PACKAGE_VERSION

# to install
npm install yarn -g
yarn install

# to execute tests
yarn test