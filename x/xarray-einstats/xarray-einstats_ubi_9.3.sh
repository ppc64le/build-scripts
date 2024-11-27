#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : xarray-einstats
# Version          : v0.7.0
# Source repo      : https://github.com/arviz-devs/xarray-einstats.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=xarray-einstats
PACKAGE_VERSION=${1:-v0.7.0}
PACKAGE_URL=https://github.com/arviz-devs/xarray-einstats.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ cmake make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip gcc-gfortran libjpeg-devel openblas openblas-devel

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  # Change to the cloned repository
git checkout $PACKAGE_VERSION  # Checkout the specified version

#Original directory
ORIGINAL_DIR=$(pwd)

# Build LLVM
cd /usr/local/src
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout llvmorg-14.0.0
mkdir build && cd build
cmake -G "Unix Makefiles" ../llvm \
    -DLLVM_ENABLE_PROJECTS="clang;compiler-rt;libcxx;libcxxabi" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_RTTI=ON
make -j$(nproc)
export PATH=/usr/local/src/llvm-project/build/bin:$PATH
source ~/.bashrc

# Back to xarray-einstats directory
cd "$ORIGINAL_DIR"

# Install additional dependencies
pip install einops pillow build wheel numba scipy

#install
if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Run tests
if !(pytest -k "not test_linalg_accessor_solve and not test_solve"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    deactivate
    exit 0
fi


