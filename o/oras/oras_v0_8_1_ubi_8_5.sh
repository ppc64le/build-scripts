#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package        : github.com/oras-project/oras
# Version        : v0.8.1
# Source repo    : https://github.com/oras-project/oras
# Tested on      : UBI 8.5
# Language      : go
# Travis-Check  : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Shantanu Kadam <shantanu.kadam@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=oras
PACKAGE_VERSION=${1:-v0.8.1}
PACKAGE_URL=https://github.com/oras-project/oras
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y go git gcc-c++ 

#set GO PATH
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go/

#clone package
mkdir -p $GOPATH/src/github.com/
cd $GOPATH/src/github.com/

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy


if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
fi 

if ! go test -v ./... ; then
echo "------------------$PACKAGE_NAME:Test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Success_Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:Build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Build_and_Test_Success"
	exit 0
fi


#Test failure is in parity with Intel
#On first attempt one test case is failing, but on second attempt the test case is passing.
#=== RUN   TestContentTestSuite
#    content_test.go:51:
#                Error Trace:    content_test.go:51
#                                                        suite.go:102
#                                                        content_test.go:171
#                Error:          Expected nil, but got: &fs.PathError{Op:"open", Path:"/home/tester/go/src/github.com/oras/.test/testfile", Err:0x2}
#                Test:           TestContentTestSuite
#                Messages:       no error creating test file on disk
#    content_test.go:54:
#                Error Trace:    content_test.go:54
#                                                        suite.go:102
#                                                        content_test.go:171
#                Error:          Expected nil, but got: &fs.PathError{Op:"stat", Path:"/home/tester/go/src/github.com/oras/.test/testfile", Err:0x2}
#                Test:           TestContentTestSuite
#                Messages:       no error adding item to file store
#=== RUN   TestContentTestSuite/Test_0_Ingesters
#cannot commit on closed writer: failed precondition
#cannot commit on closed writer: failed precondition
#=== RUN   TestContentTestSuite/Test_1_Providers
#=== RUN   TestContentTestSuite/Test_2_GetByName
#--- FAIL: TestContentTestSuite (2.84s)
#    --- PASS: TestContentTestSuite/Test_0_Ingesters (2.84s)
#    --- PASS: TestContentTestSuite/Test_1_Providers (0.00s)
#    --- PASS: TestContentTestSuite/Test_2_GetByName (0.00s)
#FAIL
#FAIL    github.com/deislabs/oras/pkg/content    2.866s
