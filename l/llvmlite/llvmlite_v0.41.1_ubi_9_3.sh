#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : llvmlite
# Version       : v0.41.1
# Source repo   : https://github.com/numba/llvmlite
# Tested on     : UBI: 9.3
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Nishidha Panpaliya <nishidha.panpaliya@partner.ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
export PACKAGE_VERSION=${1:-"v0.41.1"}
export PACKAGE_NAME=llvmlite
export PACKAGE_URL=https://github.com/numba/llvmlite
export PYTHON_VER=${PYTHON_VER:-"3.11"}

# Install dependencies

yum install -y cmake git libffi-devel gcc-toolset-12 ninja-build python${PYTHON_VER}-devel python${PYTHON_VER}-wheel python${PYTHON_VER}-pip python${PYTHON_VER}-setuptools 

python${PYTHON_VER} --version
python${PYTHON_VER} -m pip install -U pip

source /opt/rh/gcc-toolset-12/enable
pip install setuptools build

# Build llvmdev which is a pre-req for llvmlite
git clone --recursive https://github.com/llvm/llvm-project
cd llvm-project
git checkout llvmorg-14.0.6
export PREFIX=/usr

mkdir build && cd  build
CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_ENABLE_PROJECTS=lld;libunwind;compiler-rt"
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


# Clone the repository
if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME
else
    cd $PACKAGE_SOURCE_DIR
fi
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Build package
if !(python${PYTHON_VER} setup.py build) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi
# Run test cases
if !(python${PYTHON_VER} runtests.py); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
