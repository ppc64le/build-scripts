#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : yargs-unparser
# Version	    : v2.0.0
# Source repo	    : https://github.com/yargs/yargs-unparser.git
# Tested on	    : ubi 8.7
# Language          : JavaScript
# Travis-Check      : true
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="yargs-unparser"
PACKAGE_VERSION=${1:-"v2.0.0"}
PACKAGE_URL=https://github.com/yargs/yargs-unparser.git
NODE_VERSION=${NODE_VERSION:-16.20.0}
HOME_DIR=${PWD}

#Install dependencies
#yum -y update
yum install -y yum-utils wget git gcc gcc-c++ make 

#Installing node
cd $HOME_DIR
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz
tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH
node -v

# clone the repository
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build 
if ! npm install; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Test 
if ! npm test; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  both_build_and_test_success"
    exit 0
fi

