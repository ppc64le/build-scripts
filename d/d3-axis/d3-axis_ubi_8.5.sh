#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : d3-axis
# Version	    : v3.0.0
# Source repo	    : https://github.com/d3/d3-axis
# Tested on	    : ubi 8.5
# Language          : JavaScript,HTML
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
PACKAGE_NAME="d3-axis"
PACKAGE_VERSION=${1:-"v3.0.0"}
PACKAGE_URL=https://github.com/d3/d3-axis
export NODE_VERSION=${NODE_VERSION:-16}

# Install dependencies
#yum -y update
yum install -y git gcc gcc-c++ make

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

# clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build the package
if ! npm install; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run the test cases
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
