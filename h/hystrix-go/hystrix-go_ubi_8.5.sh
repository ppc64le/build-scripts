#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : hystrix-go
# Version       : v0.0.0-20180502004556-fa1af6a1f4f5
# Source repo   : https://github.com/afex/hystrix-go
# Tested on     : UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas / Vedang Wartikar <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=hystrix-go
PACKAGE_VERSION=${1:-fa1af6a1f4f5}
PACKAGE_URL=https://github.com/afex/hystrix-go



#Install the required dependencies
yum -y update && yum install git gcc make wget tar zip -y

GO_VERSION=1.17

# Install Go and setup working directory
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /bin -xf go$GO_VERSION.linux-ppc64le.tar.gz

rm -f go$GO_VERSION.linux-ppc64le.tar.gz

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/go

mkdir -p $GOPATH/src && cd $GOPATH/src

#Clone the repository
git clone $PACKAGE_URL

cd hystrix-go/hystrix

git checkout $PACKAGE_VERSION


go mod init

go mod tidy

go build && go test






