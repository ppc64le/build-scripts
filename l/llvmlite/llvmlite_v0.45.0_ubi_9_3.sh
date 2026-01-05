#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : llvmlite
# Version          : 0.45.0
# Source repo      : https://github.com/numba/llvmlite
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
#                    platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=llvmlite
PACKAGE_VERSION=${1:-v0.45.0}
PACKAGE_URL="https://github.com/numba/llvmlite.git"

LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-20.1.8"

WORKING_DIR="$(pwd)"
LLVM_SRC_DIR=$WORKING_DIR/llvm-project
LLVM_INSTALL_DIR=$WORKING_DIR/llvm-install

# Install system dependencies
yum install -y git wget cmake ninja-build make \
               openssl-devel bzip2-devel libffi-devel zlib-devel \
               python3.12 python3.12-devel python3.12-pip
yum install -y gcc-toolset-13
source /opt/rh/gcc-toolset-13/enable

# Ensure pip is up-to-date
python3.12 -m pip install --upgrade pip setuptools wheel build ninja

# Clone llvm-project
if [ ! -d "$LLVM_SRC_DIR" ]; then
    git clone $LLVM_PROJECT_GIT_URL $LLVM_SRC_DIR
fi
cd $LLVM_SRC_DIR
git fetch --all --tags
git checkout $LLVM_PROJECT_GIT_TAG

# Build & install LLVM
cmake -S llvm -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL_DIR \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="PowerPC"   

cmake --build build --target install -j$(nproc)

# Clone llvmlite
cd $WORKING_DIR
if [ ! -d "$PACKAGE_NAME" ]; then
    git clone $PACKAGE_URL
fi
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build & install llvmlite
export CMAKE_PREFIX_PATH=$LLVM_INSTALL_DIR/lib/cmake/llvm
export CXXFLAGS="-fPIC"

if ! (python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
if ! python3.12 -m llvmlite.tests ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
