#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : x/net
# Version       : 694bf12d69, d418f374d309
# Source repo   : https://go.googlesource.com/net
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
#Run the script:./x_net_ubi_8.5.sh 694bf12d69(version_to_test)
PACKAGE_NAME=net
PACKAGE_VERSION=${1:-694bf12d69}
GO_VERSION=1.18.3
ARCH=ppc64le
PACKAGE_URL=https://go.googlesource.com/net

#Install dependency
dnf install gcc gcc-c++ make git wget sudo unzip -y
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
mkdir -p $GOPATH/src/golang.org/x
cd $GOPATH/src/golang.org/x
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
if [ ! -f go.mod ]
then
if ! (go mod init && go mod tidy); then
       echo "------------------$PACKAGE_NAME:build failed---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_Fails"
       exit 1
fi
fi

#Run the test cases
if ! (go test -v ./...); then
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
#One of the test case TestRace failed on UBI container(race condition) and passed on rhel VM. 
