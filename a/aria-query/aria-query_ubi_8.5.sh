#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: aria-query
# Version	: v4.2.2
# Source repo	: https://github.com/A11yance/aria-query
# Tested on	: ubi 8.5
# Language      : node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="aria-query"
PACKAGE_VERSION=${1:-"v4.2.2"}
PACKAGE_URL="https://github.com/A11yance/aria-query"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD
export NODE_VERSION=${NODE_VERSION:-v12}
export PATH=$PATH:$HOME_DIR/$PACKAGE_NAME/node_modules/.bin

yum install -y git

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

nvm install "$NODE_VERSION"
npm install -g npm@6

HOME_DIR=$PWD

echo "cloning..."
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION" || exit 1
export ESLINT=${1:-6}
npm uninstall --no-save eslint-config-airbnb-base
npm install --no-save eslint@"$ESLINT"

if ! npm install && npm audit fix; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
if ! npm run | grep -q "test"; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_not_present---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub |  |  Install_success_but_test_not_present"
	exit 0
fi

npm run build
if ! npm run jest; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
