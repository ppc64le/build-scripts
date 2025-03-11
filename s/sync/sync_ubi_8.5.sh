#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : sync
# Version       : master(036812b2)
# Source repo   : https://github.com/golang/sync.git
# Tested on     : ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K {sachin.kakatkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./sync_ubi_8.5.sh master(version_to_test)
PACKAGE_NAME=sync
PACKAGE_VERSION=${1:-036812b2}
GO_VERSION=1.17.1
PACKAGE_URL=https://github.com/golang/sync.git

dnf install git wget -y

mkdir -p /home/tester/output
cd /home/tester

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$PATH:$GOPATH/bin

mkdir -p $GOPATH/src/github.com/golang
cd $GOPATH/src/github.com/golang
rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


COMPONENT=errgroup
cd $COMPONENT

if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

if ! go test -v; then
        echo "------------------$PACKAGE_NAME $COMPONENT:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
else
        echo "------------------$PACKAGE_NAME $COMPONENT:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  $COMPONENT |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
fi

cd ..
COMPONENT=semaphore
cd $COMPONENT

if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

if ! go test -v; then
        echo "------------------$PACKAGE_NAME $COMPONENT:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
else
        echo "------------------$PACKAGE_NAME $COMPONENT:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  $COMPONENT |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
fi

cd ..
COMPONENT=singleflight
cd $COMPONENT

if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

if ! go test -v; then
        echo "------------------$PACKAGE_NAME $COMPONENT:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
else
        echo "------------------$PACKAGE_NAME $COMPONENT:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  $COMPONENT |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
fi

cd ..
COMPONENT=syncmap
cd $COMPONENT

if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

if ! go test -v; then
        echo "------------------$PACKAGE_NAME $COMPONENT:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
else
        echo "------------------$PACKAGE_NAME $COMPONENT:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME $COMPONENT" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  $COMPONENT |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
fi

