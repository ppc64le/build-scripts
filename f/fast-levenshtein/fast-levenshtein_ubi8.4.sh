#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : fast-levenshtein
# Version       : 3.0.0
# Source repo   : https://github.com/hiddentao/fast-levenshtein
# Tested on     : UBI: 8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Mohit Pawar <mohit.pawar@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# variables
REPO=https://github.com/hiddentao/fast-levenshtein

PACKAGE_VERSION=${1:-3.0.0}

# install required dependencies
yum install git wget -y
yum module install nodejs:12 -y

# clone package
git clone $REPO
cd fast-levenshtein/
git checkout $PACKAGE_VERSION

# to install
npm install yarn -g
yarn install

# to execute tests
yarn test
