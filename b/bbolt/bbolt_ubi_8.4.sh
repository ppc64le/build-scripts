#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : bbolt
# Version       : v1.3.6
# Source repo   : https://github.com/etcd-io/bbolt.git
# Tested on     : UBI 8.4
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
#Run the script:./bbolt_ubi_8.4.sh v1.3.6(version_to_test)
PACKAGE_NAME=bbolt
PACKAGE_VERSION=${1:-v1.3.6}
GO_VERSION=1.17.1
PACKAGE_URL=https://github.com/etcd-io/bbolt.git

dnf install git wget sudo make gcc gcc-c++ -y

mkdir -p /home/tester/output
cd /home/tester

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$PATH:$GOPATH/bin


rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

INSTALL_SUCCESS="false"


if ! go build; then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

# Ensure go.mod file exists
if ! go test -v; then
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

#Test case TestBucket_Delete_FreelistOverflow failed because of time out
