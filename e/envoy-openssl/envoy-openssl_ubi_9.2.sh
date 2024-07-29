#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : envoy-openssl
# Version       : release/v1.28
# Source repo   : https://github.com/envoyproxy/envoy-openssl.git
# Tested on     : RHEL 9.2
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anurag Chitrakar <Anurag.Chitrakar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=envoy-openssl
PACKAGE_URL=https://github.com/envoyproxy/envoy-openssl
PACKAGE_VERSION=${1:-release/v1.28}
GO_VERSION=${1:-1.22.1}

# Install dependencies

yum install -y perl git cmake wget gcc gcc-c++ make libffi-devel python3 ninja-build openssl openssl-devel diffutils patch

# Exporting path

export SOURCE_ROOT=/root
if [ ! -h /usr/bin/python ]; then
  ln -s /usr/bin/python3 /usr/bin/python
fi
export PATH=$PATH:/usr/bin/ninja
python --version
ninja --version
yum info openssl

# Install llvm

cd $SOURCE_ROOT
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout llvmorg-14.0.6
cd $SOURCE_ROOT
mkdir -p llvm_build
cd llvm_build
cmake3 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_ENABLE_PROJECTS="clang;lld" -G "Ninja" ../llvm-project/llvm
ninja -j$(nproc)
export PATH=$SOURCE_ROOT/llvm_build/bin:$PATH
export CC=$SOURCE_ROOT/llvm_build/bin/clang
export CXX=$SOURCE_ROOT/llvm_build/bin/clang++
clang --version

# Install go use 1.22.1

export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
if [ $( go version | cut -d " " -f3 ) = "go${GO_VERSION}" ]; then
    echo "${GO_VERSION} is already installed"
else
    cd $SOURCE_ROOT
    wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/root/go
    export GOBIN=/usr/local/go/bin
    which go
    go version
fi

# Build envoy openssl

cd $SOURCE_ROOT
git clone ${PACKAGE_URL}
export LD_LIBRARY_PATH=/root/llvm_build/lib:$LD_LIBRARY_PATH
export CPLUS_INCLUDE_PATH=/root/llvm-project/clang/include:/root/llvm_build/tools/clang/include
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
cd bssl-compat/
git submodule init
git submodule update
mkdir build
cd build
cmake ..
cmake --build .
