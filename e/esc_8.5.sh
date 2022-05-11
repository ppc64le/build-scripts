#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : esc
# Version       : v0.2.0
# Source repo   : https://github.com/mjibson/esc.git
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

PACKAGE_NAME=esc
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v0.2.0}
PACKAGE_URL=https://github.com/mjibson/esc.git

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

# Build and Test esc
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export GO111MODULE="auto"
#go install github.com/mjibson/esc@latest
if ! go install github.com/mjibson/esc@v0.2.0; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 1
fi

#install_&_test_both_success .
