#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: consul
# Version	: v1.14.4
# Source repo	: https://github.com/hashicorp/consul
# Tested on	: UBI 8.5
# Language      : Go, SCSS, JavaScript, Handlebars, Shell, Gherkin
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=consul
PACKAGE_VERSION=${1:-v1.14.4}
PACKAGE_URL=https://github.com/hashicorp/consul
yum install -y wget tar zip gcc-c++ make git procps diffutils

wget  https://go.dev/dl/$(curl https://go.dev/VERSION?m=text).linux-ppc64le.tar.gz
tar -C /usr/local -xzf $(ls go*)
ln -sf /usr/local/go/bin/go /usr/bin/
ln -sf /usr/local/go/bin/godoc /usr/bin/
rm -rf $(ls go*)

go install gotest.tools/gotestsum@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.45.2
ulimit -n 2048
umask 0022

export CWD=`pwd`
export PATH=$GOPATH/bin:$PATH
export CONSULPATH=$GOPATH/src/github.com/hashicorp
export PACKAGE_NAME=consul

git clone --branch $PACKAGE_VERSION $PACKAGE_URL
cd consul
go mod download
go mod tidy
if ! make dev; then
    echo "Build fails"
    exit 1
fi

export PATH=$(go env GOPATH)/bin:$PATH
cd sdk
gotestsum --format=short-verbose ./...
cd ..
if ! go test -v ./acl && go test -v ./command && go test -v ./ipaddr && go test -v ./lib && go test -v ./proto/pbservice && go test --race; then
    echo "Test fails"
    exit 2
else
    echo "Build and test successful"
    exit 0
fi
