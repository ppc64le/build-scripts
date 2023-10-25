#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: github.com/hashicorp/vault
# Version	: v1.11.2, v1.11.3, v1.12.3,v1.13.1,v1.14.0
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
PACKAGE_VERSION=${1:-v1.14.1}
GO_VERSION=${GO_VERSION:-1.20.6}
PACKAGE_URL=https://github.com/hashicorp/vault

WORKDIR=`pwd`

yum install -y openssl sudo make git gcc wget

cd $WORKDIR
 #install go
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz 
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz 
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go 
export GOPATH=$HOME 
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#Clone and build the source
mkdir -p ${GOPATH}/src/github.com/hashicorp
cd ${GOPATH}/src/github.com/hashicorp

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod tidy
make bootstrap
go mod vendor
make

make testrace TEST=./vault
