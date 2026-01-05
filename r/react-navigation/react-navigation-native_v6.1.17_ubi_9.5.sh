#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-navigation
# Version       : 6.1.17
# Source repo   : https://github.com/react-navigation/react-navigation.git
# Tested on     : UBI 9.5 (ppc64le)
# Language      : JavaScript,TypeScript
# Ci-Check  : true
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
PACKAGE_NAME=react-navigation
PACKAGE_URL="https://github.com/react-navigation/$PACKAGE_NAME.git"
TAG="@react-navigation/native@6.1.17"

# Install required system dependencies
yum module enable nodejs:18 -y
yum install nodejs git sudo  -y
export NODE_OPTIONS="--dns-result-order=ipv4first"
curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
yum install yarn -y
yarn global add gitpkg

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

# Install dependencies - yarn 
yarn install 

# Build the project
ret=0
yarn lerna run prepack || ret=$?
if [ "$ret" -ne 0 ]
then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------------"
    exit 1
fi

# Running lint checks
yarn lint || ret=1

# Auto-fixing lint issues
yarn lint --fix || ret=1

# Compiling TypeScript
yarn typescript || ret=1

# Running test suite
yarn test || ret=2

if [ "$ret" -eq 1 ]; then
    echo "------------------$PACKAGE_NAME:lint_or_build_failed------------------------"
    echo "Lint or Build Failed"
    exit 1
elif [ "$ret" -eq 2 ]; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails------------------------"
    echo "Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success---------------------------"
    echo "Both_Install_and_Test_Success"
    exit 0
fi