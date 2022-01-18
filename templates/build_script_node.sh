#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: {package_name}
# Version	: {package_version}
# Source repo	: {package_url}
# Tested on	: {distro_name} {distro_version}
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=${PACKAGE_NAME}
PACKAGE_VERSION=${PACKAGE_VERSION}
PACKAGE_URL=${PACKAGE_URL}

yum -y update && yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake

npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
PACKAGE_VERSION=$(jq -r ".version" package.json)
# run the test command from test.sh

if ! npm install && npm audit fix && npm audit fix --force; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

cd /home/tester/$PACKAGE_NAME
if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
