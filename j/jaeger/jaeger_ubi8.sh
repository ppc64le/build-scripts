#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: Jaeger
# Version	: v1.39.0
# Source repo	: https://github.com/jaegertracing/jaeger.git
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

GO_VERSION=1.19
PACKAGE_VERSION=v1.39.0
PACKAGE_NAME=jaeger
PACKAGE_URL=https://github.com/jaegertracing/jaeger.git

# Install required packages
yum -y update
yum -y install wget sudo jq curl git make gcc time gnupg2 gcc-c++ python3

cd /
GOPATH=/go
PATH=$PATH:/usr/local/go/bin

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install v16.17.1

npm install -g yarn


# Install & Build Jaeger
# See https://github.com/jaegertracing/jaeger/blob/master/CONTRIBUTING.md
mkdir -p $GOPATH/src/github.com/jaegertracing
cd $GOPATH/src/github.com/jaegertracing
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Adds the jaeger-ui submodule
git submodule update --init --recursive
yarn install --ignore-engines

# Install build tools
make install-tools

# Run Tests
make test

# Build all platforms
make build-all-platforms

