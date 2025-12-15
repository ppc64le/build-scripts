# -----------------------------------------------------------------------------
#
# Package	: github.com/mgutz/logxi
# Version	: v0.0.0-20161027140823-aebf8a7d67ab
# Source repo	: https://github.com/mgutz/logxi
# Language	: GO
# Tested on	: UBI 8.5
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Build is passing, test are in parity with x86
# ----------------------------------------------------------------------------



PACKAGE_NAME=github.com/mgutz/logxi
PACKAGE_VERSION=${1:-v0.0.0-20161027140823-aebf8a7d67ab}
PACKAGE_URL=https://github.com/mgutz/logxi

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

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_NAME*)

go mod init $PACKAGE_NAME
go mod tidy

go get -t github.com/mattn/go-colorable
go get -t github.com/mgutz/ansi
go get -t gopkg.in/godo.v2
go get -t github.com/mattn/go-isatty
go get -t github.com/Sirupsen/logrus
go get -t gopkg.in/inconshreveable/log15.v2
go get -t github.com/mgutz/logxi/v1

# ----------------------------------------------------------------------------
# Test are in parity with x86:
#    logger_test.go:32:
#               Error Trace:    logger_test.go:32
#               Error:          Not equal:
#                                expected: 4
#                               actual  : 3
#                Test:           TestEnvLOGXI
#                Messages:       Unset LOGXI defaults to *:WRN with TTY
#    logger_test.go:46:
#                Error Trace:    logger_test.go:46
#                Error:          Not equal:
#                                expected: 4
#                                actual  : 3
#                Test:           TestEnvLOGXI
#--- FAIL: TestComplexKeys (0.00s)
#    logger_test.go:128:
#                Error Trace:    logger_test.go:128
#                Error:          func (assert.PanicTestFunc)(0x101a8940) should panic
#                                        Panic value:    <nil>
#                Test:           TestComplexKeys
#    logger_test.go:132:
#                Error Trace:    logger_test.go:132
#                Error:          func (assert.PanicTestFunc)(0x101a8880) should panic
#                                        Panic value:    <nil>
#                Test:           TestComplexKeys

# ----------------------------------------------------------------------------


if ! go test ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
