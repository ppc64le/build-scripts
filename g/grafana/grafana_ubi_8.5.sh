#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : grafana
# Version          : v9.2.0
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

PACKAGE_VERSION="${1:-v9.1.6}"
GO_VERSION=1.17

yum update -y
cd /
PATH=/node-$NODE_VERSION-linux-ppc64le/bin:$PATH
yum install -y wget git make curl tar gcc-c++  && \
curl https://raw.githubusercontent.com/creationix/nvm/v0.39.1/install.sh| bash
source ~/.nvm/nvm.sh
nvm install v18.12.0
nvm use v18.12.0

cd /
GOPATH=/go
PATH=$PATH:/usr/local/go/bin
yum install -y gcc gcc-c++ && \
    wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    rm -rf go$GO_VERSION.linux-ppc64le.tar.gz

mkdir -p $GOPATH/src/github.com/grafana/
cd $GOPATH/src/github.com/grafana/
git clone https://github.com/grafana/grafana.git 
cd grafana
git checkout $PACKAGE_VERSION
npm install -g yarn

yarn install --immutable
make gen-go
go run build.go build
go test -v ./pkg/...
exit 0
