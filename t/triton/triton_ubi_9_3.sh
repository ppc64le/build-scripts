#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : triton
# Version       : v2.1.0
# Source repo   : https://github.com/triton-lang/triton.git
# Tested on     : UBI: 9.3
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=triton
PACKAGE_VERSION=${1:-v2.1.0}
PACKAGE_URL=https://github.com/triton-lang/triton.git

# Install dependencies
dnf update -y
dnf install -y \
    python \
    python-devel \
    gcc \
    gcc-c++ \
    cmake \
    make \
    git \
    ninja-build \
    llvm \
    llvm-devel \
    libffi \
    libffi-devel \
    zlib \
    gcc-toolset-12 \
    zlib-devel

python3 -m pip install -U pip setuptools wheel

source /opt/rh/gcc-toolset-12/enable

# Build llvmdev which is a pre-req for triton
git clone --recursive https://github.com/llvm/llvm-project
cd llvm-project
git checkout llvmorg-14.0.6
export PREFIX=/usr

mkdir build && cd  build
CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_ENABLE_PROJECTS=lld;mlir;llvm;libunwind;compiler-rt"
CFLAGS="$(echo $CFLAGS | sed 's/-fno-plt //g')"
CXXFLAGS="$(echo $CXXFLAGS | sed 's/-fno-plt //g')"
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=$PREFIX/include"
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=$PREFIX/lib"

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}"   \
      -DCMAKE_BUILD_TYPE=Release           \
      -DCMAKE_LIBRARY_PATH="${PREFIX}"     \
      -DLLVM_ENABLE_LIBEDIT=OFF            \
      -DLLVM_ENABLE_LIBXML2=OFF            \
      -DLLVM_ENABLE_RTTI=ON                \
      -DLLVM_ENABLE_TERMINFO=OFF           \
      -DLLVM_INCLUDE_BENCHMARKS=OFF        \
      -DLLVM_INCLUDE_DOCS=OFF              \
      -DLLVM_INCLUDE_EXAMPLES=OFF          \
      -DLLVM_INCLUDE_GO_TESTS=OFF          \
      -DLLVM_INCLUDE_TESTS=ON              \
      -DLLVM_INCLUDE_UTILS=ON              \
      -DLLVM_INSTALL_UTILS=ON              \
      -DLLVM_UTILS_INSTALL_DIR=libexec/llvm            \
      -DLLVM_BUILD_LLVM_DYLIB=OFF          \
      -DLLVM_LINK_LLVM_DYLIB=OFF           \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
      -DLLVM_ENABLE_FFI=ON                 \
      -DLLVM_ENABLE_Z3_SOLVER=OFF          \
      -DLLVM_OPTIMIZED_TABLEGEN=ON         \
      -DCMAKE_POLICY_DEFAULT_CMP0111=NEW   \
      -DCOMPILER_RT_BUILD_BUILTINS=ON      \
      -DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=OFF          \
      -DCOMPILER_RT_BUILD_LIBFUZZER=OFF    \
      -DCOMPILER_RT_BUILD_CRT=OFF          \
      -DCOMPILER_RT_BUILD_MEMPROF=OFF      \
      -DCOMPILER_RT_BUILD_PROFILE=OFF      \
      -DCOMPILER_RT_BUILD_SANITIZERS=OFF   \
      -DCOMPILER_RT_BUILD_XRAY=OFF         \
      -DCOMPILER_RT_BUILD_GWP_ASAN=OFF     \
      -DCOMPILER_RT_BUILD_ORC=OFF          \
      -DCOMPILER_RT_INCLUDE_TESTS=OFF      \
      ${CMAKE_ARGS}       -GNinja       ../llvm

export CPU_COUNT=4
ninja -j${CPU_COUNT}

ninja install
cd ../..
rm -rf llvm-project


# Clone and build Triton
git clone --recursive "$PACKAGE_URL"
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export PATH=/usr/bin:$PATH

mkdir -p build && cd build

cmake -DCMAKE_BUILD_TYPE=Release -DTRITON_ENABLE_CUDA=OFF ..

ninja -j${CPU_COUNT}

ninja install
cd ..

pip install ninja cmake wheel pybind11

if ! pip install -e python; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

