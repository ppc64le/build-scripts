# ----------------------------------------------------------------------------
#
# Package       : istio-api
# Version       : 1.4.3
# Source repo   : https://github.com/istio/api
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
WORKDIR=`pwd`

# Install all dependencies
yum install -y devtoolset-7*
source scl_source enable devtoolset-7
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y libtool patch aspell-en automake autoconf make curl unzip binutils-devel
yum install -y wget tar git cmake3 zip
ln -sf /usr/bin/cmake3 /usr/bin/cmake


mkdir source_root
export SOURCE_ROOT=/source_root
BUILD_VERSION=1.4.3

#Install Go
curl -O https://dl.google.com/go/go1.13.6.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.6.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
go version

cd $SOURCE_ROOT
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.11.2/protobuf-all-3.11.2.tar.gz
tar -xvzf protobuf-all-3.11.2.tar.gz
cd protobuf-3.11.2
./autogen.sh
./configure
make
make install
go get github.com/Masterminds/glide
go get -u github.com/nilslice/protolock/...

# Clone istio/api and build
cd $SOURCE_ROOT
git clone https://github.com/istio/api
cd api && git checkout $BUILD_VERSION
sed -i '33a else ifeq ($(LOCAL_ARCH),ppc64le)' Makefile
sed -i '34a TARGET_ARCH ?= ppc64le' Makefile
export BUILD_WITH_CONTAINER=0
go get github.com/gogo/protobuf/protoc-gen-gogofast
go install istio.io/tools/cmd/protoc-gen-jsonshim
go get github.com/gogo/protobuf/protoc-gen-gogoslick
go install istio.io/tools/cmd/protoc-gen-deepcopy
go install istio.io/tools/cmd/protoc-gen-docs
go get istio.io/tools/cmd/annotations_prep@latest
go get istio.io/tools/cmd/cue-gen@latest
make