#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : 3scale-operator
# Version	    : 3scale-2.15.1-GA
# Source repo	: https://github.com/3scale/3scale-operator
# Tested on	    : UBI:9.3
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Shubham Gupta (Shubham.Gupta43@ibm.com)
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME=3scale-operator
PACKAGE_VERSION=${1:-3scale-2.15.1-GA}
PACKAGE_URL=https://github.com/3scale/3scale-operator

#Install the required dependencies
yum install git gcc make wget tar zip -y

# Install Go and setup working directory
#with {Version : 3scale-2.15.1-GA}, go version 1.20+ is required
GO_VERSION=1.20.1
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go && \
export GOPATH=$HOME && \
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION\

# Install the dependencies
if ! make download; then
	echo "------------------$PACKAGE_NAME:install_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
fi

if ! make test-unit; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else	
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
