#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : session
# Version	    : v1.17.3
# Source repo	: https://github.com/expressjs/session.git
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

PACKAGE_NAME=session
PACKAGE_VERSION=${1:-v1.17.3}
PACKAGE_URL=https://github.com/expressjs/session.git
HOME_DIR=${PWD}

yum install -y yum-utils git wget tar gzip 

#Installing Nodejs v16.20.0
cd $HOME_DIR
wget https://nodejs.org/dist/v16.20.0/node-v16.20.0-linux-ppc64le.tar.gz
tar -xzf node-v16.20.0-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v16.20.0-linux-ppc64le/bin:$PATH
node -v
npm -v

#Cloning session repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

npm config set strict-ssl false
npm config set shrinkwrap false

#Install session
if ! npm install; then
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