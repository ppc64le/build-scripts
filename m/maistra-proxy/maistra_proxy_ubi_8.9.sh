#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : proxy
# Version       : maistra-2.5.0
# Source repo   : https://github.com/maistra/proxy
# Tested on     : UBI 8.9
# Language      : C++
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandranana
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.

#Note: Tested the script on ubi8.9 as maistra-proxy 2.5.0 is based on openssl 1.1 and RHEL 9 has openssl 3.0.x 
# ----------------------------------------------------------------------------

PACKAGE_NAME=proxy
PACKAGE_VERSION=${1:-maistra-2.5.0}
PACKAGE_URL=https://github.com/maistra/${PACKAGE_NAME}
PATH=$PATH:/usr/local/go/bin
SOURCE_ROOT=${HOME}
GO_VERSION=1.22.5
GOPATH=$SOURCE_ROOT/go
GOBIN=/usr/local/go/bin

yum install -y git wget python3 libtool automake gcc gcc-c++ vim cmake openssl java-11-openjdk-devel perl lld patch openssl-devel ninja-build
ln -s /usr/bin/python3 /usr/bin/python

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
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout llvmorg-13.0.1
cd $SOURCE_ROOT
mkdir -p llvm_build
cd llvm_build
cmake3 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_ENABLE_PROJECTS="clang;lld" -G "Ninja" ../llvm-project/llvm
ninja -j$(nproc)
export PATH=$SOURCE_ROOT/llvm_build/bin:$PATH
export CC=$SOURCE_ROOT/llvm_build/bin/clang
export CXX=$SOURCE_ROOT/llvm_build/bin/clang++

# Install go
if echo $(go version) | grep -q $GO_VERSION; then
	echo "=======================Go $(go version) is already installed====================="
else
	echo "=======================Installing Go v$GO_VERSION====================="
	cd $SOURCE_ROOT
	wget https://go.dev/dl/go$GO_VERSION.linux-ppc64le.tar.gz
	tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz
	which go
	go version
fi

#
# Build proxy
#
cd $SOURCE_ROOT
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./maistra/ci/pre-submit.sh; then
	echo "Build Fails"
	exit 1
else
	echo "Build Success"
fi



