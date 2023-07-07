#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package	: onsi/ginkgo
# Version	: v2.1.6
# Source repo	: https://github.com/onsi/ginkgo
# Tested on	: UBI: 8.5
# Language	: PHP
# Travis-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Abhishek Dighe <Abhishek.Dighe@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=onsi/ginkgo
PACKAGE_URL=https://github.com/onsi/ginkgo
PACKAGE_VERSION=${1:-v2.1.6}
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

echo "----------------Installing the pre-requisite---------------------"
dnf install -y git wget make gcc gcc-c++
wget https://go.dev/dl/go1.18.linux-ppc64le.tar.gz
tar -C /usr/local -xf go1.18.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

if ! git clone $PACKAGE_URL; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | Github| Fail |  Clone_Fails" 
fi
cd ginkgo
git checkout $PACKAGE_VERSION
if ! go mod tidy && go build -v ./...; then
	echo "------------------$PACKAGE_NAME:clone_success_but_build_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Clone_success_but_build_Fails"
	exit 1
fi

if ! go test -race ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME "  
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Install_success_but_test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Both_Install_and_Test_Success"
fi

