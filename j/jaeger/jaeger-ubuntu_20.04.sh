# Package : Jaeger, Distributed Tracing Platform
# Version : Master
# Source repo : https://github.com/jaegertracing/jaeger
# Tested on : ubuntu 20.04
# Architecture : ppc64le
# Maintainer : sachin.kakatkar@ibm.com
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

# Set go install version
export GO_VER=go1.16.3

# Install required packages
apt -y update
apt -y install sudo
sudo apt -y install jq
sudo apt -y install curl
sudo apt -y install git
sudo apt -y install make
sudo apt -y install gcc
sudo apt -y install time
sudo apt -y install gnupg2

# Install GO 1.16.x
curl -O https://storage.googleapis.com/golang/${GO_VER}.linux-ppc64le.tar.gz
tar zxf ${GO_VER}.linux-ppc64le.tar.gz

# Copy go binary
chmod +x go/bin/*
sudo chown -R root:root ./go
sudo mv go /usr/local

# Set go path
mkdir -p $HOME/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Install Yarn & update
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt -y update
sudo apt -y install yarn
yarn install

# Install & Build Jaeger
# See https://github.com/jaegertracing/jaeger/blob/master/CONTRIBUTING.md
GOPATH=$HOME/go
mkdir -p $GOPATH/src/github.com/jaegertracing
cd $GOPATH/src/github.com/jaegertracing
git clone https://github.com/jaegertracing/jaeger.git
cd jaeger

# Adds the jaeger-ui submodule
git submodule update --init --recursive

# Install build tools
make install-tools

# Run Tests
make test

# Build all platforms binaries
make build-all-platforms

# Below targets fails because of the delve package and docker images not supported for linux OS and ppc64le architecture
#index-cleaner-integration-test, index-rollover-integration-test, token-propagation-integration-test
#docker, docker-images-jaeger-backend, docker-images-jaeger-backend-debug, docker-images-only, thrift
#thrift-image, generate-zipkin-swagger, proto
