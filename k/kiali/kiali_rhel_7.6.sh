# ----------------------------------------------------------------------------
#
# Package       : kiali
# Version       : v1.12.1
# Source repo   : https://github.com/kiali/kiali/
# Tested on     : ppc64le_rhel7.6
# Script License: Apache License 2.0
# Maintainer's  : Rashmi Sakhalkar <srashmi@us.ibm.com>
#                 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

yum update -y
yum install -y gcc
yum install -y make
yum install -y python36
yum install -y wget git

BUILD_VERSION=v1.12.1

wget https://dl.google.com/go/go1.12.13.linux-ppc64le.tar.gz -P /tmp
tar xf /tmp/go1.12.13.linux-ppc64le.tar.gz -C /usr/local/
export PATH="$PATH:/usr/local/go/bin"

export GOPATH="$HOME/go"
export PATH=$GOPATH/bin:$PATH

#build swagger-go
export SWAGGER_SRC="$GOPATH/src/github.com/go-swagger/go-swagger"
mkdir -p $SWAGGER_SRC
git clone -b v0.19.0 https://github.com/go-swagger/go-swagger.git $SWAGGER_SRC
cd $SWAGGER_SRC
go install ./cmd/swagger

#clone & build kiali
export KIALI_SRC="$GOPATH/src/github.com/kiali/kiali"
mkdir -p $KIALI_SRC
git clone https://github.com/kiali/kiali.git $KIALI_SRC
cd $KIALI_SRC
git checkout $BUILD_VERSION
sed -i 's/amd64/ppc64le/' Makefile
GO_FILES=$(find . -iname '*.go' -type f | grep -v /vendor/)
make lint-install
if [ ! -z "$(gofmt -l ${GO_FILES})" ]; then echo "These files need to be formatted:" "$(gofmt -l ${GO_FILES})";echo "Diff files:"; gofmt -d ${GO_FILES}; exit 1; fi
make lint
make clean build test-race