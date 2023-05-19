#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/hashicorp/vault
# Version	: v1.11.2, v1.11.3, v1.12.3,v1.13.1
# Source repo	: https://github.com/hashicorp/vault
# Tested on	: UBI: 8.5
# Language      : Go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vault
PACKAGE_VERSION=${1:-v1.13.1}
GO_VERSION=${GO_VERSION:-1.20.1}
PACKAGE_URL=https://github.com/hashicorp/vault

yum install -y openssl sudo make git gcc wget

wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH

mkdir -p /go/src/github.com/hashicorp

export GOPATH=/go
export PATH=$PATH:$GOPATH/bin

cd /go/src/github.com/hashicorp
git clone $PACKAGE_URL
cd vault
git checkout $PACKAGE_VERSION

go mod tidy
make bootstrap
go mod vendor
make

make testrace TEST=./vault
make testacc TEST=./builtin/logical/pki
make testacc TEST=./builtin/logical/totp
 
