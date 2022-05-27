#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : node-http-proxy-agent
# Version       : 5.0.0,4.0.1
# Source repo   : https://github.com/TooTallNate/node-http-proxy-agent.git
# Tested on     : UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas Kumar <kumar.vikas@in.ibm.com> , Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=node-http-proxy-agent
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-5.0.0}
PACKAGE_URL=https://github.com/TooTallNate/node-http-proxy-agent.git

yum install -y git jq

curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install latest version of node and npm
nvm install --latest-npm v12.22.9

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
    rm -rf $PACKAGE_NAME
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 0
fi

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
PACKAGE_VERSION=$(jq -r ".version" package.json)
# run the test command from test.sh

if ! npm install && npm audit fix && npm audit fix --force; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! npm run build --if-present; then
	echo "------------------$PACKAGE_NAME:install_success_but_build_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_build_Fails"
	exit 1
fi

if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_and_build_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_and_build_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_build_&_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Build_and_Test_Success"
	exit 0
fi
