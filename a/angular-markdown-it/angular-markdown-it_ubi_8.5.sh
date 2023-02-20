#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : angular-markdown-it
# Version          : v0.6.1
# Source repo      : https://github.com/macedigital/angular-markdown-it
# Tested on        : RHEL 8.5,UBI 8.5
# Language         : Node
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Saraswati Patra <Saraswati.Patra@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=angular-markdown-it
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v0.6.1}
PACKAGE_URL=https://github.com/macedigital/angular-markdown-it
yum install -y yum-utils git jq

NODE_VERSION=v10.23.1
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

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
        exit 1
fi

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install --save-dev mocha
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

#Both build and Test Passed




