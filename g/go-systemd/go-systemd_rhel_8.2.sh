#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : go-systemd
# Version       : v9
# Source repo   : https://github.com/coreos/go-systemd.git
# Tested on     : rhel 8.2
# Language      : go
# Travis-Check  : false
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
#Run the script:./go-systemd_ubi_8.4.sh v9(version_to_test)
PACKAGE_NAME=go-systemd
PACKAGE_VERSION=${1:-v9}
GO_VERSION=1.17.1
PACKAGE_URL=https://github.com/coreos/go-systemd.git

dnf install git wget systemd-devel.ppc64le sudo make gcc gcc-c++ -y

mkdir -p /home/tester/output
cd /home/tester

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$PATH:$GOPATH/bin

mkdir -p $GOPATH/src/github.com/coreos
cd $GOPATH/src/github.com/coreos
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

INSTALL_SUCCESS="false"
COMPONENT=activation
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
COMPONENT=daemon
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
COMPONENT=dbus
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
COMPONENT=journal
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
COMPONENT=sdjournal
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
COMPONENT=login1
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
COMPONENT=machine1
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
COMPONENT=unit
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

#Tested on VM. All packages test passed for version v22.3.0 and Only activation and unit packages test passed on v9
