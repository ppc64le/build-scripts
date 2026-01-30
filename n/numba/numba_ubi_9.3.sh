#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.57.0
# Source repo   : https://github.com/numba/numba.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Robin Jain <robin.jain1@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_VERSION=${1:-"0.57.0"}
PACKAGE_NAME=numba
PACKAGE_URL=https://github.com/numba/numba

# Install dependencies and tools.
yum install -y cmake git libffi-devel gcc-toolset-12 ninja-build python3-devel python3-pip
yum install -y  xz-devel bzip2-devel openssl-devel zlib-devel libffi-devel make

#Installing llvmlite from source
echo "-------------------Installing llvmlite----------------------"

source /opt/rh/gcc-toolset-12/enable
pip install setuptools==78.0.1 build

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
git clone --recursive https://github.com/numba/llvmlite
cd llvmlite
git checkout v0.42.0

pip install .

cd ..

echo "-------------------successfully Installed llvmlite----------------------"

# Install numpy
pip install pytest numpy==1.26.4

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install -r requirements.txt 
python3 setup.py build_ext --inplace 

# Install
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Install_Success"
    exit 0
fi

# Skipping the test cases as they are taking more than 5 hours. 
