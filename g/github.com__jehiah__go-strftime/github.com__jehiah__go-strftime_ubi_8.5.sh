#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : github.com/jehiah/go-strftime
# Version       : 1d33003b386959af197ba96475f198c114627b5e
# Source repo   : https://github.com/jehiah/go-strftime
# Tested on     : UBI 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=go-strftime
PACKAGE_VERSION=${1:-1d33003b386959af197ba96475f198c114627b5e}
PACKAGE_URL=https://github.com/jehiah/go-strftime


yum install -y git wget
wget https://golang.org/dl/go1.15.6.linux-ppc64le.tar.gz
tar -C /bin -xf go1.15.6.linux-ppc64le.tar.gz
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 0
fi

cd $PACKAGE_NAME

echo " --------------------------------- checkout version  $PACKAGE_VERSION ------------------------------------"
git checkout $PACKAGE_VERSION
go mod init $PACKAGE_NAME
if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME: build failed-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Build_Fails" > /home/tester/output/version_tracker
    exit 1
fi

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails" > /home/tester/output/version_tracker
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
