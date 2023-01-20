#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	 : go-gcfg/gcfg
# Version	 : v1, v1.2.3, v1.2.0
# Source repo	 : https://github.com/go-gcfg/gcfg
# Tested on	 : UBI 8.5
# Language       : GO
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer	 : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=gcfg
PACKAGE_URL=https://github.com/go-gcfg/gcfg
PACKAGE_VERSION=${1:-v1}

GO_VERSION=go1.19

yum install -y git wget

#install go
rm -rf /bin/go
wget https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /bin -xzf $GO_VERSION.linux-ppc64le.tar.gz  
rm -f $GO_VERSION.linux-ppc64le.tar.gz

#set go path
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
mkdir -p /home/tester/go/src
cd $GOPATH/src

#clone package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! go mod init; then
	echo "------------------$PACKAGE_NAME:initialize_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Initialize_Fails"
	exit 1
fi

if ! go mod tidy; then
	echo "------------------$PACKAGE_NAME:dependency_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Dependency_Fails"
	exit 1
fi

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi

# For v1.2.3 & v1.2.0 there are 2 test failures 
# Test failures
# 1. FAIL: TestParseInt (0.00s)
#       int_test.go:54: ParseInt(int, "0x", IntMode(Hex)): fail; got error failed to parse "0x" as int: strconv.ParseInt: parsing "0x": invalid syntax, want ok
#       int_test.go:54: ParseInt(int, "-0x", IntMode(Hex)): fail; got error failed to parse "-0x" as int: strconv.ParseInt: parsing "-0x": invalid syntax, want ok 
#
#2. FAIL: TestScanFully (0.00s)
#       scan_test.go:23: ScanFully(*int, "0x", 'v'): want ok, got error failed to parse "0x" as int: strconv.ParseInt: parsing "0x": invalid syntax
#
# Same obeservation on Intel as well
#
# Test failures are fixed for top of the tree i.e.v1
# Test failures fix link: https://github.com/go-gcfg/gcfg/pull/20/commits/1185e641ea2aa19d732dd9d7cd0d36599d6fe22d

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi