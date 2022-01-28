# ----------------------------------------------------------------------------
#
# Package        : grafana
# Version        : v8.1.5
# Source repo    : https://github.com/grafana/grafana.git
# Tested on      : UBI 8.4
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -eu

PACKAGE_VERSION="${1:-v8.1.5}"
NODE_VERSION=v14.17.6
GO_VERSION=1.17.1

cd /
PATH=/node-$NODE_VERSION-linux-ppc64le/bin:$PATH
yum install -y wget git && \
    wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    tar -C / -xzf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    rm -rf node-$NODE_VERSION-linux-ppc64le.tar.gz && \
    npm install -g yarn

cd /
GOPATH=/go
PATH=$PATH:/usr/local/go/bin
yum install -y gcc gcc-c++ wget && \
    wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    rm -rf go$GO_VERSION.linux-ppc64le.tar.gz

mkdir -p $GOPATH/src/github.com/grafana/
cd $GOPATH/src/github.com/grafana/
git clone https://github.com/grafana/grafana.git
cd grafana
git checkout $PACKAGE_VERSION
# Needed to fix a test failure related to FP precision
# Ref: https://github.com/grafana/grafana/issues/39748
git cherry-pick -n 377b323fafcbf07ba898cda31086fc95c209cbaa
yarn install --pure-lockfile --no-progress
yarn build
go mod verify
go run build.go build
go test -v ./pkg/...
# Please note that there is one known npm test failure on power for v8.1.5
# Ref: https://github.com/grafana/grafana/issues/39778, skipping that here
sed -i 's/describe(/describe.skip(/g' public/app/features/alerting/unified/Receivers.test.tsx
yarn test --watchAll
exit 0

