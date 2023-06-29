#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : date-format
# Version	    : v4.0.14
# Source repo	: https://github.com/nomiddlename/date-format.git
# Tested on	    : UBI: 8.7
# Language      : Javascript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=date-format
PACKAGE_VERSION=${1:-v4.0.14}
PACKAGE_URL=https://github.com/nomiddlename/date-format.git
HOME_DIR=${PWD}

yum install -y yum-utils git wget tar gzip 

#Installing Nodejs v14.21.2
cd $HOME_DIR
wget https://nodejs.org/dist/v14.21.2/node-v14.21.2-linux-ppc64le.tar.gz
tar -xzf node-v14.21.2-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v14.21.2-linux-ppc64le/bin:$PATH
node -v
npm -v

#Cloning date-format repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Install date-format
if ! npm install && npm audit fix && npm audit fix --force; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

#Run test cases
if ! npm test; then
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