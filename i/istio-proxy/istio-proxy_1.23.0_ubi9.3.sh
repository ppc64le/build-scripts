#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : istio/proxy
# Version       : 1.23.0
# Source repo   : https://github.com/istio/proxy
# Tested on     : UBI 9.3
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandranana
#
# Disclaimer: This script has been tested in non root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=proxy
PACKAGE_ORG=istio
SCRIPT_PACKAGE_VERSION=1.23.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
PATH=$PATH:/usr/local/go/bin
SOURCE_ROOT=$(pwd)
scriptdir=$(dirname $(realpath $0))
GO_VERSION=${1:-1.23.2}
GOPATH=$SOURCE_ROOT/go
GOBIN=/usr/local/go/bin 
	
sudo yum install -y \
    sudo \
    cmake \
    patch \
    gcc-toolset-12-libatomic-devel \
    unzip \
    python3.11-devel \
    wget \
    zip \
    java-11-openjdk-devel \
    git \
    gcc-c++ \
    xz

# Install go
if [ "$( go version | cut -d " " -f3 )" = "go${GO_VERSION}" ]; then
    echo "${GO_VERSION} is already installed"
else
    cd $SOURCE_ROOT
    wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
    which go
    go version
fi

cd $SOURCE_ROOT
mkdir bazel
cd bazel/
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
unzip bazel-6.5.0-dist.zip
rm -rf bazel-6.5.0-dist.zip
./compile.sh
export PATH=$PATH:$(pwd)/output

cd $SOURCE_ROOT
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
export PATH=$SOURCE_ROOT/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/bin:$PATH

#Execute the envoy script
cd $SOURCE_ROOT
git clone https://github.com/ppc64le/build-scripts.git
cd build-scripts/e/envoy
sudo chmod +x $SOURCE_ROOT/build-scripts/e/envoy/envoy_1.31.0_ubi9.3.sh
sudo ./envoy_1.31.0_ubi9.3.sh

cd $SOURCE_ROOT
git clone https://github.com/istio/proxy.git
cd ${PACKAGE_NAME} 
git checkout ${PACKAGE_VERSION}
git apply $scriptdir/${PACKAGE_NAME}_v${PACKAGE_VERSION}.patch
bazel build --config=release --override_repository=envoy=$SOURCE_ROOT/build-scripts/e/envoy/envoy --config=ppc //:envoy

if [ "$?" != 0 ]; then
	echo "FAIL: Build failed."
	exit 1
else
	echo "Build successful!"
fi

