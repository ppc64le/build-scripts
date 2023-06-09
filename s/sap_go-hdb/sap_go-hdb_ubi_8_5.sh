#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package        : sap/go-hdb
# Version        : v0.14.1
# Source repo    : https://github.com/sap/go-hdb
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

PACKAGE_NAME=go-hdb
PACKAGE_URL=https://github.com/sap/go-hdb
PACKAGE_VERSION=v0.14.1
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)


#install dependencies
yum install -y  go git gcc-c++ 

#removed old data 
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
echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Success_Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:Build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	exit 0
fi

#For requested version test cases(both integration and unit test cases) has dependency on HANA database.
#
#For requested version(v0.14.1) below test case is failing on power, which is in parity with Intel.  
#    main_test.go:55: parse "hdb://user:password@ip_address:port": invalid port ":port" after host
#    FAIL    github.com/SAP/go-hdb/driver    0.004s

