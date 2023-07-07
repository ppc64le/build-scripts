#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: vfsgen
# Version	: v0.0.0-20181202132449-6a9ea43bcacd
# Source repo	: https://github.com/shurcooL/vfsgen
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik / Vedang Wartikar<Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vfsgen
PACKAGE_VERSION=${1:-6a9ea43bcacd}
PACKAGE_URL=https://github.com/shurcooL/vfsgen

yum install -y wget git gcc-c++ diffutils golang

mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg
export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod init github.com/shurcooL/vfsgen
go mod tidy

go get -t -v ./...
diff -u <(echo -n) <(gofmt -d -s .)
go vet .

if ! go test -v -race ./...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
fi