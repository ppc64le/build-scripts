#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : consul
# Version          : v1.18.1
# Source repo      : https://github.com/hashicorp/consul
# Tested on        : UBI: 9.3
# Language         : Go
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer	   : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=consul
PACKAGE_VERSION=${1:-v1.18.1}
PACKAGE_URL=https://github.com/hashicorp/consul
GO_VERSION=`curl https://go.dev/VERSION?m=text | head -n 1`

yum install -y wget tar zip gcc-c++ make git procps diffutils

wget  https://go.dev/dl/$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local -xzf $GO_VERSION.linux-ppc64le.tar.gz
ln -sf /usr/local/go/bin/go /usr/bin/
ln -sf /usr/local/go/bin/godoc /usr/bin/
rm -rf $GO_VERSION.linux-ppc64le.tar.gz

go install gotest.tools/gotestsum@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.45.2
ulimit -n 2048
umask 0022

export PATH=$GOPATH/bin:$PATH

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod download
go mod tidy

if ! make dev; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

export PATH=$(go env GOPATH)/bin:$PATH
cd sdk
gotestsum --format=short-verbose ./...
cd ..

if ! go test -v ./acl && go test -v ./command && go test -v ./ipaddr && go test -v ./lib && go test -v ./tlsutil && go test -v ./snapshot && go test --race; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
