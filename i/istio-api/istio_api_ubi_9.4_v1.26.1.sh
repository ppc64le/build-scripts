#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : istio-api
# Version       : v1.26.1
# Source repo   : https://github.com/istio/api
# Tested on     : UBI:9.4
# Language      : go
# Ci-Check  : True
# Script License: Apache License 2.0 or later
# Maintainer's  : Anurag Chitrakar <Anurag.Chitrakar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=api
PACKAGE_ORG=istio
SCRIPT_PACKAGE_VERSION=v1.26.1
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
GO_VERSION=${GO_VERSION:-1.23.0}
HOME_DIR=`pwd`

# Install dependencies
yum install -y --allowerasing  git wget curl unzip gcc pkg-config openssl-devel clang-devel cmake iproute procps-ng iptables

#installing golang
wget "https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz"
tar -C /usr/local/ -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOBIN=/usr/local/go/bin
go version

#installing protobuf
cd $HOME_DIR
wget https://github.com/protocolbuffers/protobuf/releases/download/v31.1/protoc-31.1-linux-ppcle_64.zip
unzip protoc-31.1-linux-ppcle_64.zip
mv ./bin/protoc /usr/local/bin/
protoc --version

# Download api source code
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

go get github.com/gogo/protobuf/protoc-gen-gogofast@latest 
go get  github.com/gogo/protobuf/protoc-gen-gogoslick@latest 
go install istio.io/tools/cmd/protoc-gen-docs@latest
go install istio.io/tools/cmd/protoc-gen-crd@latest
go install istio.io/tools/cmd/annotations_prep@latest
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/golang/protobuf/protoc-gen-go 
go install github.com/bufbuild/buf/cmd/protoc-gen-buf-breaking@latest
go install github.com/bufbuild/buf/cmd/protoc-gen-buf-lint@latest
go install istio.io/tools/cmd/protoc-gen-golang-jsonshim@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install istio.io/tools/cmd/protoc-gen-golang-deepcopy@latest
go install istio.io/tools/cmd/license-lint@latest
go install github.com/nilslice/protolock/cmd/protolock@latest
go get google.golang.org/grpc@v1.64.0

# build api
echo "Build Started"
go build -v ./...

# testing api
echo "Testing Started"
cd tests/
go test -v ./...
