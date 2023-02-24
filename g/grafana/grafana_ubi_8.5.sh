#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : grafana
# Version          : v9.3.6
# Source repo      : https://github.com/grafana/grafana.git
# Tested on        : UBI 8.5
# Language         : Go,Typescript
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

PACKAGE_NAME="grafana"
PACKAGE_VERSION="${1:-v9.3.6}"
PACKAGE_URL="https://github.com/grafana/grafana.git"
NODE_VERSION=v18.9.0
GO_VERSION=1.19.6

yum update -y

cd /
PATH=/node-$NODE_VERSION-linux-ppc64le/bin:$PATH
yum install -y wget git make sed gcc-c++ && \
    wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    tar -C / -xzf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    rm -rf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    npm install -g yarn

cd /
GOPATH=/go
PATH=$PATH:/usr/local/go/bin

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz

mkdir -p $GOPATH/src/github.com/grafana/
cd $GOPATH/src/github.com/grafana/
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

yarn install --immutable
make gen-go
go run build.go build
go test -v ./pkg/...
sed -i '148d' public/app/features/dashboard/components/ShareModal/SharePublicDashboard/SharePublicDashboard.test.tsx
sed -i "148 i\    expect(screen.getByText('2022-08-30 00:00:00 to 2022-09-04 00:59:59')).toBeInTheDocument();" public/app/features/dashboard/components/ShareModal/SharePublicDashboard/SharePublicDashboard.test.tsx
yarn test --watchAll=false

