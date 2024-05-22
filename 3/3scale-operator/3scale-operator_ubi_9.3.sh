#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : 3scale-operator
# Version	    : 3scale-2.14.1-GA
# Source repo	: https://github.com/3scale/3scale-operator
# Tested on	    : UBI:9.3
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Shubham Bhagwat (shubham.bhagwat@ibm.com)
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=3scale-operator
PACKAGE_VERSION=${1:-3scale-2.14.1-GA}
PACKAGE_URL=https://github.com/3scale/3scale-operator
GO_VERSION=1.21.8

#Install the required dependencies
yum install git gcc make wget tar zip -y

# Install Go and setup working directory
wget https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go
mkdir -p $GOPATH/src && cd $GOPATH/src

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
