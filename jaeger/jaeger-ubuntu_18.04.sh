# Package : Jaeger, Distributed Tracing Platform
# Version : Master
# Source repo : https://github.com/jaegertracing/jaeger
# Tested on : ubuntu 18.04
# Maintainer : redmark@us.ibm.com
#
# Disclaimer: This script has been tested in non-root (with sudo) mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

umask 0022

export GO_VER=go1.13.6

# Install required packages

sudo apt -y update
sudo apt -y install jq

# Install GO 1.13.x

curl -O https://storage.googleapis.com/golang/${GO_VER}.linux-ppc64le.tar.gz
tar zxf ${GO_VER}.linux-ppc64le.tar.gz

chmod +x go/bin/*
sudo chown -R root:root ./go
sudo mv go /usr/local

mkdir -p $HOME/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Install Yarn & update

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt -y update
sudo apt -y install yarn
yarn install

# Install & Build Jaeger
# See https://github.com/jaegertracing/jaeger/blob/master/CONTRIBUTING.md

mkdir -p $GOPATH/src/github.com/jaegertracing
cd $GOPATH/src/github.com/jaegertracing
git clone https://github.com/jaegertracing/jaeger.git
cd jaeger
git submodule update --init --recursive

# Install build tools

go get -d -u github.com/golang/dep
cd $GOPATH/src/github.com/golang/dep
DEP_LATEST=$(git describe --abbrev=0 --tags)
git checkout $DEP_LATEST
go install -ldflags="-X main.version=$DEP_LATEST" ./cmd/dep
cd $GOPATH/src/github.com/jaegertracing/jaeger

# Run dep ensure, install build tools, then test

make install-ci
make test-ci

# Build Jaeger

make build-all-in-one-linux
