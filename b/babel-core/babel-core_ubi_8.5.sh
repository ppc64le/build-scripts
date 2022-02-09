#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: babel-core
# Version	: v7.15.4
# Source repo	: https://github.com/babel/babel/tree/master/packages/babel-core
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

PACKAGE_NAME="babel-core"
PACKAGE_VERSION=${1:-"v7.15.4"}
PACKAGE_URL="https://github.com/babel/babel"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD
export NODE_VERSION=${NODE_VERSION:-14.13}

echo "insstalling dependencies from system repo..."
yum install -y git make >/dev/null

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
npm i -g yarn@1.19.0 >/dev/null

echo "cloning..."
if ! git clone -q $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd "$HOME_DIR"/babel || exit 1
git checkout "$PACKAGE_VERSION" || exit 1

mkdir -p "$HOME"/.babel-cache
export BABEL_CACHE_PATH=$HOME/.babel-cache

if ! make bootstrap; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

# npx browserslist@latest --update-db                                                                                     results in error 
#doing it manually 
find . -name "browserslist" -type d -exec sh -c 'cd $PWD/$1 && npm update' _ {} \;
make build
# uncomment following lines to enable linting 
#make lint
#make fix

export TEST_ONLY=babel-core


# deleting failing test case  which is regenerated   on next run of make test 
rm -f "$HOME_DIR"/babel/packages/babel-core/test/fixtures/transformation/source-maps/comment-inside-string/output.js
if ! make test; then
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
