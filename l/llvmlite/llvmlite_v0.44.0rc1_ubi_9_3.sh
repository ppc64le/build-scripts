#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : llvmlite
# Version          : 0.44.0rc1
# Source repo      : https://github.com/numba/llvmlite
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
PACKAGE_NAME=llvmlite
PACKAGE_VERSION=${1:-v0.44.0rc1}
PACKAGE_URL="https://github.com/numba/llvmlite"
LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-15.0.7"
PACKAGE_DIR=/llvmlite

# Install necessary system dependencies
yum install -y git make wget openssl-devel bzip2-devel libffi-devel zlib-devel cmake python3.11 python3.11-devel python3.11-pip
yum install gcc-toolset-13 -y
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
echo "enabling gcc13-toolset"
source /opt/rh/gcc-toolset-13/enable

# Clone the llvm-project repo
git clone $LLVM_PROJECT_GIT_URL
cd llvm-project
git checkout $LLVM_PROJECT_GIT_TAG
cd ..

#clone the llvmlite repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#create virtual env
python3.11 -m venv env
source env/bin/activate

# Install additional dependencies
pip install setuptools pip ninja wheel build

# Set LLVM_CONFIG environment variable
export LLVM_CONFIG="/llvm-project/build/bin/llvm-config"

# Build LLVM project
cd /llvm-project
git apply /llvmlite/conda-recipes/llvm15-clear-gotoffsetmap.patch
git apply /llvmlite/conda-recipes/llvm15-remove-use-of-clonefile.patch
cp /llvmlite/conda-recipes/llvmdev/build.sh .
chmod 777 build.sh && ./build.sh

# Build llvmlite
cd $PACKAGE_DIR
export CXXFLAGS="-I/llvm-project/llvm/include"
export LLVM_CONFIG=/llvm-project/build/bin/llvm-config

# Install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    deactivate
    exit 1
    
fi

# Run tests
if ! python -c "import llvmlite; import llvmlite.binding; import llvmlite.ir; import llvmlite.tests;"; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    deactivate
    exit 2
    
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    deactivate
    exit 0    
fi
