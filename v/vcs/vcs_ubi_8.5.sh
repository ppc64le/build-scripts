#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : vcs
# Version       : 1.13.1
# Source repo   : https://github.com/masterminds/vcs
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License:  Apache License, Version 2 or later
# Maintainer    : Haritha Patchari <haritha.patchari@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vcs
PACKAGE_VERSION=${1:-v1.13.1}
PACKAGE_URL=https://github.com/masterminds/vcs


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
mkdir -p $GOPATH/src/$PACKAGE_PATH
cd $GOPATH/src/$PACKAGE_PATH
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init
go mod tidy

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi
echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi

#Parity with power and Intel
#testing.tRunner.func1.2({0x102c2460, 0x10500c20})
#        /usr/bin/go/src/testing/testing.go:1209 +0x27c
#testing.tRunner.func1(0xc000142340)
#        /usr/bin/go/src/testing/testing.go:1212 +0x228
#panic({0x102c2460, 0x10500c20})
#        /usr/bin/go/src/runtime/panic.go:1038 +0x240
#vcs.(*BzrRepo).CheckLocal(0x0)
#        /home/go/src/vcs/bzr.go:199 +0x24
#vcs.TestBzrCheckLocal(0xc000142340)
#        /home/go/src/vcs/bzr_test.go:253 +0x118
#testing.tRunner(0xc000142340, 0x10324398)
#        /usr/bin/go/src/testing/testing.go:1259 +0xf0
#created by testing.(*T).Run
#        /usr/bin/go/src/testing/testing.go:1306 +0x370
#FAIL    vcs     0.008s
