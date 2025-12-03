#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : react-grid-layout
# Version       : 1.4.1
# Source repo   : https://github.com/STRML/react-grid-layout
# Tested on     : UBI:9.3
# Language      : Node
# Ci-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=react-grid-layout
PACKAGE_VERSION=${1:-1.4.1}
PACKAGE_URL=https://github.com/STRML/react-grid-layout
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export NODE_VERSION=${NODE_VERSION:-18}
export NODE_OPTIONS="--dns-result-order=ipv4first"

yum update -yq && yum install -yq git make

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION
npm i --global yarn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# install deps & build
if ! yarn && yarn build; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

# test
if ! yarn test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
