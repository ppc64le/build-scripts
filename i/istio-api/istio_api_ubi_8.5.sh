#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : istio-api
# Version       : master, 1.16.1
# Source repo   : https://github.com/istio/api
# Tested on     : UBI 8.5
# Language      : go
# Travis-Check  : True
# Script License: Apache License 2.0 or later
# Maintainer's  : Haritha Patchari <haritha.patchari@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=https://github.com/istio/api
PACKAGE_VERSION=${1:-v1.16.1}
PACKAGE_URL=https://github.com/istio/api

WORKDIR=`pwd`

echo "# Install all dependencies"
yum install -y libtool patch
yum install -y automake autoconf make curl unzip
yum install -y wget tar git cmake3 zip
yum install -y gcc gcc-c++

mkdir -p source_root
export SOURCE_ROOT=$PWD/source_root

#Install Go
curl -O https://dl.google.com/go/go1.18.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.18.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
go version

cd $SOURCE_ROOT

wget https://github.com/protocolbuffers/protobuf/releases/download/v3.11.2/protobuf-all-3.11.2.tar.gz
tar -xzf protobuf-all-3.11.2.tar.gz  --no-same-owner
cd "protobuf-3.11.2"
./autogen.sh
./configure
make
make install
#git clone https://github.com/Masterminds/glide
#git clone https://github.com/nilslice/protolock
#git clone https://github.com/gogo/protobuf

# Clone istio/api and build
cd $SOURCE_ROOT
git clone https://github.com/istio/api
cd api && git checkout $PACKAGE_VERSION
sed -i '33a else ifeq ($(LOCAL_ARCH),ppc64le)' Makefile
sed -i '34a TARGET_ARCH ?= ppc64le' Makefile
export BUILD_WITH_CONTAINER=0
go get github.com/gogo/protobuf/protoc-gen-gogofast@latest
go get  github.com/gogo/protobuf/protoc-gen-gogoslick@latest
go install istio.io/tools/cmd/protoc-gen-docs@latest
go install istio.io/tools/cmd/annotations_prep@latest
go install  istio.io/tools/cmd/cue-gen@latest
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/golang/protobuf/protoc-gen-go
go install github.com/bufbuild/buf/cmd/protoc-gen-buf-breaking@latest
go install github.com/bufbuild/buf/cmd/protoc-gen-buf-lint@latest
go install istio.io/tools/cmd/protoc-gen-golang-jsonshim@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install istio.io/tools/cmd/protoc-gen-golang-deepcopy@latest
go install istio.io/tools/cmd/license-lint@latest
go install github.com/nilslice/protolock/cmd/protolock@latest

make
if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi
if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME: build_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_and_Test_Success"
	exit 0
fi
