#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : FixedHeader
# Version       : 4.0.1
# Source repo   : https://github.com/DataTables/FixedHeader
# Tested on     : UBI: 9.3
# Language      : JavaScript
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
PACKAGE_NAME="FixedHeader"
PACKAGE_VERSION=${1:-"4.0.1"}
PACKAGE_URL=https://github.com/DataTables/FixedHeader
NODE_VERSION=${NODE_VERSION:-18.19.0}
HOME_DIR=`pwd`
export NODE_OPTIONS="--dns-result-order=ipv4first"


#Install dependencies
yum install -y git fontconfig-devel wget libXcomposite libXcursor procps-ng
cd $HOME_DIR

#Install node
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz
tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH
node -v
npm -v

# Clone the repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install -g bower


# Build package
if !(bower install); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

#Skipping test for this package as no documentation available for test.