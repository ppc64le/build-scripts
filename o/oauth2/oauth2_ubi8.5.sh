#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : oauth2
# Version          : a6bd8cefa1811bd24b86f8902872e4e8225f74c4
# Source repo      : https://github.com/golang/oauth2
# Tested on        : UBI 8.5
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhimrao Patil <Bhimrao.Patil@ibm.com>
# Travis-Check     : True
# Language 	       : GO
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
PACKAGE_NAME=oauth2
PACKAGE_PATH=golang.org/x/oauth2
PACKAGE_VERSION=${1:-a6bd8cefa1811bd24b86f8902872e4e8225f74c4}
PACKAGE_URL=https://github.com/golang/oauth2

yum install -y wget tar gcc-c++ vim git

wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

mkdir -p /home/tester/output

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"

if [ -d "$PACKAGE_NAME" ] ; then
        rm -rf $PACKAGE_NAME
        echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$ACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 0
fi

#/home/tester/go/pkg/mod/golang.org/x/oauth2@v0.0.0-20211104180415-d3ed0bb246c8
#cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@v0.0.0-20211104180415-d3ed0bb246c8)

echo `pwd`
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"

# Ensure go.mod file exists
go mod init $PACKAGE_PATH

go mod tidy

# building
echo "Building and Testing $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 0
fi

if ! go test -v ./...; then
        echo "------------------$PACKAGE_NAME: build and  Test failed-------------------------"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

#This test case is failing with parity on intel
#=== RUN   TestRetrieveTokenBustedNoSecret
#    token_test.go:42: RetrieveToken = unexpected end of JSON input; want no error
#--- FAIL: TestRetrieveTokenBustedNoSecret (0.00s)
#FAIL
#FAIL    golang.org/x/oauth2/internal    0.011s
