#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : node-fetch-npm
# Version       : v2.0.4,v2.0.2
# Source repo   : https://github.com/npm/node-fetch-npm
# Tested on	: UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="node-fetch-npm"
PACKAGE_VERSION=${1:-"v2.0.2"}
PACKAGE_URL="https://github.com/npm/node-fetch-npm"
export NODE_VERSION=${NODE_VERSION:-v12.22.4}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
yum install -y git
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install "$NODE_VERSION"
npm install -g npm@latest
HOME_DIR=$PWD

#Observed one failure and is in Parity with Intel
#  145 passing (4s)
#  1 failing
#  1)  "after all" hook:
#     Error: Timeout of 2000ms exceeded. For async tests and hooks, ensure "done()" is called; if returning a Promise, ensure it resolves.
#      at listOnTimeout (internal/timers.js:554:17)
#      at processTimers (internal/timers.js:497:7)

echo "cloning..."
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi
cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION" || exit 1
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
if ! npm test; then
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
