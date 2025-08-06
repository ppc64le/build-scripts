#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pako
# Version       : 2.1.0
# Source repo   : https://github.com/nodeca/pako
# Tested on     : UBI 9.5
# Script License: Apache License, Version 2 or later
# Maintainer    : Anusha Heralagi (Anusha.Heralagi@ibm.com)
#
# Disclaimer: This script has been tested in root mode on the given
#             platform using the mentioned version of the package.
#             It may not work with newer versions of the package or distro.
# -----------------------------------------------------------------------------

PACKAGE_NAME=pako
PACKAGE_VERSION=2.1.0
PACKAGE_URL=https://github.com/nodeca/pako

dnf install -y git nodejs npm python3 python3-devel gcc-c++ make jq
OS_NAME=$(grep '^PRETTY_NAME' /etc/os-release | cut -d= -f2 | tr -d '"')

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout tags/$PACKAGE_VERSION -b build_branch
ACTUAL_VERSION=$(jq -r ".version" package.json)
echo "Building $PACKAGE_NAME version $ACTUAL_VERSION on $OS_NAME"

npm install
npm audit fix || true
npm audit fix --force || true
if npm test; then
    echo "$PACKAGE_NAME | $PACKAGE_URL | $ACTUAL_VERSION | $OS_NAME | Pass | Install_&_Test_Success"
else
    echo "$PACKAGE_NAME | $PACKAGE_URL | $ACTUAL_VERSION | $OS_NAME | Fail | Test_Fails"
    exit 1
fi
