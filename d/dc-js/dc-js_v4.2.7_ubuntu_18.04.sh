#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------
#
# Package       : dc-js
# Version       : 4.2.7
# Source repo   : https://github.com/dc-js/dc.js.git
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Jotirling Swami <Jotirling.Swami1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

set -ex

#Variables
PACKAGE_NAME=dc.js
PACKAGE_VERSION=4.2.7
PACKAGE_URL=https://github.com/dc-js/dc.js.git

#Extract version from command line
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is $PACKAGE_VERSION and building for ${1:-$PACKAGE_VERSION}"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
apt update -y && apt install -y git make build-essential python2.7 firefox

# nodejs required version (Version 10.xx)
apt install -y curl
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 14.15.0
node -v

apt install -y npm 
npm i -g npm
npm install -g grunt-cli

#Clone repo
HOME_DIR=`pwd`
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

#Build and test
cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! npm install; then
	echo "------------------$PACKAGE_NAME:build_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! grunt test --force; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	#conclude
	find $HOME_DIR/$PACKAGE_NAME -name dc.min.js
	find $HOME_DIR/$PACKAGE_NAME -name dc.min.css
	echo "Complete!"	
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi