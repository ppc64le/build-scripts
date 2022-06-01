#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: consul
# Version	: v1.12.0
# Source repo	: https://github.com/hashicorp/consul
# Tested on	: UBI 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Kandarpa Malipeddi <kandarpa.malipeddi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y wget tar zip gcc-c++ make git procps diffutils

PACKAGE_VERSION=${1:-v1.12.0}

wget  https://go.dev/dl/$(curl https://go.dev/VERSION?m=text).linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.18.2.linux-ppc64le.tar.gz
ln -sf /usr/local/go/bin/go /usr/bin/
ln -sf /usr/local/go/bin/godoc /usr/bin/
rm -rf go1.18.2.linux-ppc64le.tar.gz

go install gotest.tools/gotestsum@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.45.2
ulimit -n 2048
umask 0022

export CWD=`pwd`
export PATH=$GOPATH/bin:$PATH
export CONSULPATH=$GOPATH/src/github.com/hashicorp
export PACKAGE_NAME=consul

#[ ! -d "$GOPATH" ] && mkdir -p $GOPATH
#[ ! -d "$CONSULPATH" ] && mkdir -p $CONSULPATH

#cd $CONSULPATH
#if [ -d "$PACKAGE_NAME" ]; then     rm -rf "$PACKAGE_NAME"; fi

git clone --branch $PACKAGE_VERSION https://github.com/hashicorp/consul.git
cd consul
go mod download
go mod tidy
make dev

export PATH=$(go env GOPATH)/bin:$PATH
cd sdk
gotestsum --format=short-verbose ./...
cd ..
go test -v ./acl
go test -v ./command
go test -v ./ipaddr
go test -v ./lib
go test -v ./proto/pbservice
go test -v ./tlsutil
go test -v ./snapshot
go test --race