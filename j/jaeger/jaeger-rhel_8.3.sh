# Package : Jaeger, Distributed Tracing Platform
# Version : Master
# Source repo : https://github.com/jaegertracing/jaeger
# Tested on : UBI RHEL 8.3
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

# Set Go lang version
export GO_VER=go1.16.3

# Install required packages
yum -y update
yum -y install sudo
yum -y install jq
yum -y install curl
yum -y install git
yum -y install make
yum -y install npm
yum -y install gcc
yum -y install time
yum -y install gnupg2

# Install GO 1.16.x
curl -O https://storage.googleapis.com/golang/${GO_VER}.linux-ppc64le.tar.gz
tar zxf ${GO_VER}.linux-ppc64le.tar.gz

# Move and set go executable permission
chmod +x go/bin/*
sudo chown -R root:root ./go
sudo mv go /usr/local

# Set go PATH
mkdir -p $HOME/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Update and Install yarn
sudo yum -y update
npm install --global yarn 
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

# Build all platforms
make build-all-platforms

# Below target fails because of the delve package and docker images not supported for ppc64le architecture
#index-cleaner-integration-test, index-rollover-integration-test, token-propagation-integration-test
#docker, docker-images-jaeger-backend, docker-images-jaeger-backend-debug, docker-images-only, thrift
#thrift-image, generate-zipkin-swagger, proto

