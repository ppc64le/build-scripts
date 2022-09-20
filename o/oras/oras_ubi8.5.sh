# -----------------------------------------------------------------------------
#
# Package	: github.com/oras-project/oras
# Version	: v0.12.0, v0.8.1
# Source repo	: https://github.com/oras-project/oras
# Tested on	: ubi8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>, Shantanu Kadam <Shantanu.Kadam@ibm.com>
# Language	: GO
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=oras
PACKAGE_VERSION=${1:-v0.12.0}
PACKAGE_URL=https://github.com/oras-project/oras

yum install -y wget git tar gcc

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz
mkdir -p /home/tester/go/src 
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

cd /home/tester/go/src
git clone --recurse $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION



if ! go install -v ./...; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Intsall_Fails"
	exit 1
fi


if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails-------------------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Success_Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	echo "------------------$PACKAGE_NAME:Installed at path: /home/tester/go/src/$PACKAGE_NAME------------------------"
	exit 0
fi

#for v0.8.1
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

