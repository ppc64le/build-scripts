#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : cacache
# Version	    : v12.0.3
# Source repo	: https://github.com/npm/cacache
# Tested on	    : UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar <spana.khemkar@ibm.com>/ Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cacache
PACKAGE_VERSION=${1:-v12.0.3}
PACKAGE_URL=https://github.com/npm/cacache

yum install -y git npm

mkdir -p /home/tester
cd /home/tester

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install

#Test summary is 
#failed 1 of 15 tests
# This is in parity with x86
npm test

exit 0