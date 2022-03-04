#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : istio-api
# Version       : a584d151eff9b8f7327087a99b2cba53116c0136
# Source repo   : https://github.com/istio/api.git
# Tested on     : ubi: 8.4
# Language      : go, c++
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Nishikant Thorat <Nishikant.Thorat@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Docker must be installed
set -ex

PACKAGE_VERSION=${1:-a584d151eff9b8f7327087a99b2cba53116c0136}
WORKDIR=`pwd`

echo "# Install all dependencies"
yum install -y libtool patch 
yum install -y automake autoconf make curl unzip 
yum install -y wget tar git cmake3 zip
yum install -y gcc gcc-c++

mkdir -p source_root
export SOURCE_ROOT=$PWD/source_root

#Install Go
curl -O https://dl.google.com/go/go1.17.1.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.17.1.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
go version

cd $SOURCE_ROOT
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.11.2/protobuf-all-3.11.2.tar.gz
tar -xzf protobuf-all-3.11.2.tar.gz
cd "protobuf-3.11.2"
./autogen.sh
./configure
make
make install
go get github.com/Masterminds/glide
go get -u github.com/nilslice/protolock/...

# Clone istio/api and build
cd $SOURCE_ROOT
git clone https://github.com/istio/api
cd api && git checkout $PACKAGE_VERSION
sed -i '33a else ifeq ($(LOCAL_ARCH),ppc64le)' Makefile
sed -i '34a TARGET_ARCH ?= ppc64le' Makefile
export BUILD_WITH_CONTAINER=0
go install github.com/gogo/protobuf/protoc-gen-gogofast@latest
go install istio.io/tools/cmd/protoc-gen-jsonshim@latest
go install  github.com/gogo/protobuf/protoc-gen-gogoslick@latest
go install istio.io/tools/cmd/protoc-gen-deepcopy@latest
go install istio.io/tools/cmd/protoc-gen-docs@latest
go install istio.io/tools/cmd/annotations_prep@latest
go install  istio.io/tools/cmd/cue-gen@latest
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/golang/protobuf/protoc-gen-go
go install github.com/bufbuild/buf/cmd/protoc-gen-buf-breaking@latest
go install github.com/bufbuild/buf/cmd/protoc-gen-buf-lint@latest
go get istio.io/tools/cmd/license-lint

make
