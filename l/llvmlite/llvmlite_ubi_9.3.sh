#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : llvmlite
# Version       : v0.40.0
# Source repo   : https://github.com/numba/llvmlite
# Tested on     : UBI: 9.3
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_VERSION=${1:-"v0.40.0"}
PACKAGE_NAME=llvmlite
PACKAGE_URL=https://github.com/numba/llvmlite

echo "installing dependencies ..."
yum install -y cmake git libffi-devel gcc-toolset-12 ninja-build python3-devel python3-pip

echo "install python dependencies ..."
source /opt/rh/gcc-toolset-12/enable
pip install setuptools build

echo "Build llvmdev which is a pre-req for llvmlite ..."
git clone --recursive https://github.com/llvm/llvm-project
cd llvm-project
git checkout llvmorg-14.0.1
export PREFIX=/usr
echo "build llvm ..."
mkdir build && cd  build
CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_ENABLE_PROJECTS=lld;libunwind;compiler-rt"
CFLAGS="$(echo $CFLAGS | sed 's/-fno-plt //g')"
CXXFLAGS="$(echo $CXXFLAGS | sed 's/-fno-plt //g')"
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=$PREFIX/include"
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=$PREFIX/lib"
echo "starting cmake ..."
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
echo "Starting make install..."
ninja install

cd ../..
rm -rf llvm-project

echo "Clone the repository ..."
git clone --recursive $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Install package ..."
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

 echo "Run tests ... "
if !(python3 runtests.py); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
