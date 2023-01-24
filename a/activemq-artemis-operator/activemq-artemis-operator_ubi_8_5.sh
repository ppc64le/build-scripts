#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : artemiscloud
# Version       : master
# Source repo   : https://github.com/artemiscloud/activemq-artemis-operator.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhimrao Patil <Bhimrao.Patil@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------
set -e

PACKAGE_NAME=activemq-artemis-operator
SDK_PACKAGE_NAME=operator-sdk
PACKAGE_URL=https://github.com/artemiscloud/activemq-artemis-operator.git
SDK_PACKAGE_URL=https://github.com/operator-framework/operator-sdk

dnf install -y git wget gcc-c++ gcc make

#Go installation
wget https://go.dev/dl/go1.17.linux-ppc64le.tar.gz
tar -C /usr/local -xf go1.17.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go	
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export GO111MODULE=on

#operator-sdk
if [ -d "$SDK_PACKAGE_NAME" ] ; then
	rm -rf $SDK_PACKAGE_NAME
    echo "$SDK_PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $SDK_PACKAGE_URL $SDK_PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$SDK_PACKAGE_URL $SDK_PACKAGE_NAME"
    echo "$SDK_PACKAGE_NAME  |  $SDK_PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 0
fi

cd $SDK_PACKAGE_NAME
git checkout v1.15.0
make install
cd ../

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
	rm -rf $PACKAGE_NAME
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_Fails"
    exit 0
fi

cd $PACKAGE_NAME/
git checkout main

#building and testing 
if !  make build; then
    echo "------------------$PACKAGE_NAME:install_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_build_Fails"
    exit 1
fi
 
if !  make test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

#Test case is failing due to quay.io/artemiscloud/fake-broker:latest is a placeholder image 
#And the image is not available for ppc64 architecture
#Discussed with Red-Hat team and added images on RTC task
