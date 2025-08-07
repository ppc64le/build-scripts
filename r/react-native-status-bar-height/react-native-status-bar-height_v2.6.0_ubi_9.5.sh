#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-native-status-bar-height
# Version       : v2.6.0
# Source repo   : https://github.com/ovr/react-native-status-bar-height.git
# Tested on     : UBI 9.5 (ppc64le)
# Language      : JavaScript,TypeScript
# Travis-Check  : true
# Script License: MIT License (standard permissive open‑source license)
# Maintainer    : Sai vikram kuppala <Sai.vikram.kuppala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="react-native-status-bar-height"
PACKAGE_URL="https://github.com/ovr/react-native-status-bar-height.git"
TAG="v2.6.0"

# Install required system dependencies
yum module enable nodejs:20 -y
yum install git  -y
yum install -y nodejs


# Clone the repository
if [[ -d "$PACKAGE_NAME" ]]; then
  echo "Directory $PACKAGE_NAME already exists; pulling latest"
  cd "$PACKAGE_NAME"
  git fetch --all --tags
else
  git clone "$PACKAGE_URL"
  cd "$PACKAGE_NAME"
fi
git checkout "$TAG"

# Build the project
ret=0
npm install
npm install --save react-native-status-bar-height || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------------"
    exit 1
fi

# Run Tests
npm test || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails------------------------"
    echo "Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success---------------------------"
    echo "Both_Install_and_Test_Success"
    exit 0
fi
