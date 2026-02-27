#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pako
# Version       : v2.1.0
# Source repo   : https://github.com/nodeca/pako
# Tested on     : UBI 9.5
# Language      : JavaScript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anusha Heralagi (Anusha.Heralagi@ibm.com)
#
# Disclaimer: This script has been tested in root mode on the given
#             platform using the mentioned version of the package.
#             It may not work with newer versions of the package or distro.
# -----------------------------------------------------------------------------

PACKAGE_NAME=pako
PACKAGE_VERSION=${1:-v2.1.0}
PACKAGE_URL=https://github.com/nodeca/pako
CURRENT_DIR="${PWD}"

dnf install -y git nodejs npm python3 python3-devel gcc-c++ make jq
OS_NAME=$(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '"')

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION 
ACTUAL_VERSION=$(jq -r ".version" package.json)
echo "Building $PACKAGE_NAME version $ACTUAL_VERSION on $OS_NAME"

if ! npm install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $ACTUAL_VERSION | $OS_NAME | Fail | Install_Fails"
    exit 1
fi

# Attempt to fix vulnerabilities (non-blocking)
npm audit fix || true
npm audit fix --force || true

# Run tests
if ! npm test; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $ACTUAL_VERSION | $OS_NAME | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $ACTUAL_VERSION | $OS_NAME | Pass | Both_Install_and_Test_Success"
    exit 0
fi
