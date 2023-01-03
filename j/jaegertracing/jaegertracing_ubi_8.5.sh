#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : jaegertracing
# Version       : v1.40.0
# Source repo   : https://github.com/jaegertracing/jaeger.git
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhimrao Patil <Bhimrao.Patil@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------
set -e

PACKAGE_NAME=jaeger
PACKAGE_VERSION=${1:-v1.40.0}
PACKAGE_URL=https://github.com/jaegertracing/jaeger.git

dnf install -y jq git wget gcc-c++ gcc
wget https://go.dev/dl/go1.19.linux-ppc64le.tar.gz
tar -C /usr/local -xf go1.19.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export GO111MODULE=on

dnf module install -y nodejs:12

npm install -g yarn
yarn add caniuse-lite browserslist

mkdir -p $GOPATH/src/github.com/jaegertracing
cd $GOPATH/src/github.com/jaegertracing
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

git submodule update --init --recursive
yarn install
go get -d -u github.com/golang/dep
go install
go test -v ./...

#This test case is failing with parity on intel
#-- FAIL: TestExtractor_TraceOutputFileError (0.01s)
#panic: runtime error: invalid memory address or nil pointer dereference [recovered]
#panic: runtime error: invalid memory address or nil pointer dereference
#[signal SIGSEGV: segmentation violation code=0x1 addr=0x18 pc=0x791ee8]
