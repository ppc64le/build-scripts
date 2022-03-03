# -----------------------------------------------------------------------------
#
# Package	: github.com/niemeyer/pretty
# Version	: v0.0.0-20200227124842-a10e7caefd8e
# Source repo	: https://github.com/niemeyer/pretty
# Tested on	: UBI 8.5
# Language	: GO
# Travis-Check	: True
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
# The Build is passing but the test are in Parity with x86.
# Parity is for both the requested and the top of the tree version
# ----------------------------------------------------------------------------


PACKAGE_NAME=github.com/niemeyer/pretty
PACKAGE_VERSION=${1:-v0.0.0-20200227124842-a10e7caefd8e}
PACKAGE_URL=https://github.com/niemeyer/pretty

yum install -y wget git tar

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

# ----------------------------------------------------------------------------
# The Build is passing but the test are in Parity with x86.
# Parity is for both the requested and the top of the tree version
# [root@a3374864caf1 pretty]# go test ./... -v
# github.com/niemeyer/pretty
# ./formatter.go:40:9: conversion from int to string yields a string of one rune, not a string of digits (did you mean fmt.Sprint(x)?)
# FAIL    github.com/niemeyer/pretty [build failed]
# FAIL
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

