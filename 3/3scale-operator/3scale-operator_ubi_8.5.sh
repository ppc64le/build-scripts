#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : 3scale-operator
# Version	    : 2.14.1
# Source repo	: https://github.com/3scale/3scale-operator.git
# Tested on	    : UBI 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=3scale-operator
PACKAGE_VERSION=2.14.1
PACKAGE_URL=https://github.com/3scale/3scale-operator.git
PACKAGE_BRANCH=master

#Install the required dependencies
yum install git gcc make wget tar zip -y

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

GO_VERSION=1.21.8

# Install Go and setup working directory
wget https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

#Clone the repository
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
	exit 1
else	
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi	