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

set -e

# variables
REPO=https://github.com/dchester/jsonpath
PACKAGE_VERSION=${1:-1.1.0} 

# install required dependencies
yum update -y
yum install git wget -y

# install node10, since gulp 3 is not compatible with either node12 or node14
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