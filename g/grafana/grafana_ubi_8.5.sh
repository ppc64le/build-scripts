#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : grafana
# Version          : v9.1.3
# Source repo      : https://github.com/grafana/grafana.git
# Tested on        : UBI 8.5
# Language         : Go
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_VERSION="${1:-v9.1.5}"
NODE_VERSION=v14.17.6
GO_VERSION=1.17.1

cd /
PATH=/node-$NODE_VERSION-linux-ppc64le/bin:$PATH
yum install -y wget git npm && \
    wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    tar -C / -xzf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    rm -rf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    npm install -g yarn

cd /
GOPATH=/go
PATH=$PATH:/usr/local/go/bin
yum install -y gcc  gcc-c++ && \
    wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    rm -rf go$GO_VERSION.linux-ppc64le.tar.gz

mkdir -p $GOPATH/src/github.com/grafana/
cd $GOPATH/src/github.com/grafana/
git clone https://github.com/grafana/grafana.git
cd grafana
git checkout $PACKAGE_VERSION

yarn install --mode update-lockfile
yarn start

go run build.go build
yarn test 
go test -v ./pkg/...

exit 0
