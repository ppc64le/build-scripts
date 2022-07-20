#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: inert
# Version	: v3.1.1
# Source repo	: https://github.com/WICG/inert.git
# Tested on	: UBI 8.5
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Saraswati Patra <Saraswati.patra2ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=inert
PACKAGE_VERSION=${1:-v3.1.1}
PACKAGE_URL=https://github.com/WICG/inert.git

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm git jq

npm install n -g && n latest && npm install -g npm@latest

export npm_config_yes=true

HOME_DIR=`pwd`
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

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install && npm audit fix && npm audit fix --force; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
else
		echo "------------------$PACKAGE_NAME:install_success-------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
		exit 0
	fi

#cd $HOME_DIR/$PACKAGE_NAME
#if ! npm test; then
#	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#	echo "$PACKAGE_URL $PACKAGE_NAME"
#	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
#	exit 1
#else
#	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#	echo "$PACKAGE_URL $PACKAGE_NAME"
#	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
#	exit 0
#fi




# The code for testing this package is commented since the chrome binaries required for testing may not be accessible by the developer .
# Please refer to README.md to install the chrome binaries required for the testing

# ************** test ******************** 
