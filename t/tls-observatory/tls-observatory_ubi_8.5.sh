#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tls-observatory
# Version       : 1.3.20
# Source repo   : https://github.com/mozilla/tls-observatory.git
# Tested on     : ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K <sachin.kakatkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./tls-observatory_ubi_8.5.sh 1.3.20(version_to_test)
PACKAGE_NAME=tls-observatory
PACKAGE_VERSION=${1:-1.3.20}
GO_VERSION=1.18.3
ARCH=ppc64le
PACKAGE_URL=https://github.com/mozilla/tls-observatory.git

#Install dependency
dnf install gcc git wget make gcc-c++ sudo unzip -y
#Install go language
mkdir -p /home/tester/output
cd /home/tester
wget https://golang.org/dl/go$GO_VERSION.linux-$ARCH.tar.gz
rm -rf /usr/local/go && tar -C /usr/local/ -xzf go$GO_VERSION.linux-$ARCH.tar.gz
rm -rf go$GO_VERSION.linux-$ARCH.tar.gz
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-/home/tester/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
export GO111MODULE=on

#Create directory structure
mkdir -p $GOPATH/src/github.com/mozilla
cd $GOPATH/src/github.com/mozilla
rm -rf $PACKAGE_NAME
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Clone repository
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

#Checkout the version and build
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply ../0001-ppc64le-added-support-for-ppc64le-architecture.patch

if ! (make all); then
       echo "------------------$PACKAGE_NAME:build failed---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_Fails"
       exit 1
fi

#Run the test cases
if ! (make test); then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

