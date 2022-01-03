# ---------------------------------------------------------------------
# 
# Package       : jaegertracing
# Version       : latest tag
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

umask 0022

export GO_VER=go1.16.3

# Install required packages

yum update -y
yum install -y jq git make gcc-c++

# Install GO 1.16.x

curl -O https://storage.googleapis.com/golang/${GO_VER}.linux-ppc64le.tar.gz
tar zxf ${GO_VER}.linux-ppc64le.tar.gz

chmod +x go/bin/*
chown -R root:root ./go
mv go /usr/local

mkdir -p $HOME/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Install Yarn & update

curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -
yum install -y nodejs
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
npm install -g yarn
yarn add caniuse-lite browserslist

# Install & Build Jaeger

mkdir -p $GOPATH/src/github.com/jaegertracing
cd $GOPATH/src/github.com/jaegertracing
git clone https://github.com/jaegertracing/jaeger.git
cd jaeger
git submodule update --init --recursive
yarn upgrade caniuse-lite browserslist
# Install build tools

go get -d -u github.com/golang/dep
cd $GOPATH/src/github.com/golang/dep

#install required tools.
make install-tools
#run unit test.
#Note: unit test is failing on both intel and power VM.
make test
