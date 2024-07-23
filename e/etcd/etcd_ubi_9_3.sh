#!/bin/bash 
# -----------------------------------------------------------------------------
#
# Package	    : etcd
# Version	    : v3.5.14
# Source repo	    : https://github.com/etcd-io/etcd
# Tested on	    : UBI: 9.3
# Language          : go
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

#variables
PACKAGE_NAME=etcd
PACKAGE_VERSION=${1:-v3.5.14}
PACKAGE_URL=https://github.com/etcd-io/etcd

#install dependencies
yum install -y git golang make

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export GOPATH=$HOME/go

#clone the repository
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build and test the package
if ! make build; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! make test; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Build_and_Test_Success"
fi