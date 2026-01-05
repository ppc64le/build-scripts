#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: typed-array-byte-length
# Version	: v1.0.1
# Source repo	: https://github.com/inspect-js/typed-array-byte-length
# Tested on	: UBI 9.3
# Script License: MIT License
# Maintainer	: Amit Singh <amit.singh41@ibm.com>
# Language      : Node
# Ci-Check  : True
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=typed-array-byte-length
PACKAGE_VERSION=${1:-v1.0.1}
PACKAGE_URL=https://github.com/inspect-js/typed-array-byte-length

yum -y update && yum install -y yum-utils nodejs git

npm install n -g && n latest

HOME_DIR=`pwd`
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 1
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! npm install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
if ! npm install typescript@4.7.2 --save-dev; then
    echo "------------------$PACKAGE_NAME:typescript install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
if ! npm run test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL  | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
