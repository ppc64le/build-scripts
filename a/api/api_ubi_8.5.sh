#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : api
# Version       : v0.3.20
# Source repo   : https://github.com/operator-framework/api
# Tested on     : UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas /Vedang Wartikar <Vedang.Wartikar@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=api
PACKAGE_VERSION=${1:-v0.3.20}
PACKAGE_URL=https://github.com/operator-framework/api

#Install the required dependencies
yum -y update && yum install git gcc make wget tar zip -y

GO_VERSION=1.13

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export GOPATH=/home/go
export PATH=$PATH:/bin/go/bin

#Setup working directory
mkdir -p $GOPATH/src && cd $GOPATH/src

#Clone the repository
git clone $PACKAGE_URL

cd api

git checkout $PACKAGE_VERSION

make install

go build ./...
go test ./...