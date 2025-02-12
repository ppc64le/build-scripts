#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : maistra-proxy
# Version       : 2.6
# Source repo   : https://github.com/maistra/proxy
# Tested on     : UBI 9.3
# Language      : C++
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandranana
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=proxy
PACKAGE_ORG=maistra
PACKAGE_VERSION=${1:-maistra-2.6}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
PATH=$PATH:/usr/local/go/bin
SOURCE_ROOT=$HOME
GO_VERSION=${1:-1.23.1}
GOPATH=$SOURCE_ROOT/go
GOBIN=/usr/local/go/bin 

yum update -y
yum install -y git wget xz python3.11 libtool automake gcc vim cmake openssl-devel java-11-openjdk-devel openssl libstdc++-static perl lld patch java-11-openjdk-devel python3 ninja-build
ln -s /usr/bin/python3.11 /usr/bin/python

cd $SOURCE_ROOT
mkdir bazel
cd bazel/
wget https://github.com/bazelbuild/bazel/releases/download/6.3.2/bazel-6.3.2-dist.zip
unzip bazel-6.3.2-dist.zip
rm -rf bazel-6.3.2-dist.zip
./compile.sh
export PATH=$PATH:$(pwd)/output

#
# Install llvm
#
cd $SOURCE_ROOT
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz

export PATH=$SOURCE_ROOT/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/bin:$PATH
export CC=$SOURCE_ROOT/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/bin/clang
export CXX=$SOURCE_ROOT/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/bin/clang++

# Install go
if [ $( go version | cut -d " " -f3 ) = "go${GO_VERSION}" ]; then
    echo "${GO_VERSION} is already installed"
else
    cd $SOURCE_ROOT
    wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
    which go
    go version
fi

#
# Build proxy
#
cd $SOURCE_ROOT
git clone $PACKAGE_URL
cd proxy/
git checkout $PACKAGE_VERSION
./maistra/vendor/envoy/bazel/setup_clang.sh $SOURCE_ROOT/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/
# Below commit is tested - tests passed
if ! ./maistra/ci/pre-submit.sh; then
	echo "Build/test execution Fails"
	exit 1
else
	echo "Build & Test execution passed."
fi


