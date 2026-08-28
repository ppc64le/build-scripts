#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : gonum
# Version       : 4340aa3071a0
# Source repo   : https://github.com/gonum/gonum.git
# Tested on     : UBI 8.5
# Travis-Check  : True
# Language      : Go
# Script License: Apache License, Version 2 or later
# Maintainer    : saraswati patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=gonum
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-4340aa3071a0}
PACKAGE_URL=https://github.com/gonum/gonum.git

yum update -y
yum install -y vim cmake make git gcc-c++ perl
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`

if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi

# Dependency installation
yum module install -y go-toolset
dnf install -y git

# Download the repos

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

# Build and Test yaml
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export GO111MODULE="auto"

if ! go get -v -t ./...; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
#build_success test in parity 
#3 test case fail due to below error.

#        cb: 13806701373219750527, nb: 13806701348765483035
#    amos_test.go:497: Case zseri yi_idx_2: Float64 mismatch. c = 0.00813340543351962, native = 0.00813341306156214
#         cb: 4575842210796048912, nb: 4575842215193316042
#--- FAIL: TestZseri (5.26s)


if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

