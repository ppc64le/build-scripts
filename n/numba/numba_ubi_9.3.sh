#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.57.0
# Source repo   : https://github.com/numba/numba.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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
yum install -y git gcc gcc-c++ make wget python3.11-devel python3.11-pip xz-devel bzip2-devel openssl-devel zlib-devel libffi-devel cmake

WORKING_DIR=$(pwd)
#Installing llvmlite from source
echo "-------------------Installing llvmlite----------------------"

LLVMLITE_PACKAGE_NAME=llvmlite
LLVMLITE_VERSION="v0.44.0rc1"
LLVMLITE_PACKAGE_URL="https://github.com/numba/llvmlite"
LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-15.0.7"

git clone -b ${LLVM_PROJECT_GIT_TAG} ${LLVM_PROJECT_GIT_URL}
git clone -b ${LLVMLITE_VERSION} ${LLVMLITE_PACKAGE_URL}

python3.11 -m pip install ninja

# Build LLVM project
cd "$WORKING_DIR/llvm-project"
git apply "$WORKING_DIR/llvmlite/conda-recipes/llvm15-clear-gotoffsetmap.patch"
git apply "$WORKING_DIR/llvmlite/conda-recipes/llvm15-remove-use-of-clonefile.patch"
cp "$WORKING_DIR/llvmlite/conda-recipes/llvmdev/build.sh" .
chmod 777 "$WORKING_DIR/llvm-project/build.sh" && "$WORKING_DIR/llvm-project/build.sh"

# Set LLVM_CONFIG environment variable
export LLVM_CONFIG="/llvm-project/build/bin/llvm-config"

# Check for llvm-config path
LLVM_CONFIG_PATH=$(which llvm-config)

# If llvm-config is not found in the system path, use the local path from the build
if [ -z "$LLVM_CONFIG_PATH" ]; then
    echo "llvm-config not found in PATH, using local path."
    export LLVM_CONFIG="$WORKING_DIR/llvm-project/build/bin/llvm-config"
else
    echo "llvm-config found at: $LLVM_CONFIG_PATH"
    export LLVM_CONFIG="$LLVM_CONFIG_PATH"
fi

# Check if llvm-config.h exists in the build include directory
echo "Checking for llvm-config.h in: $WORKING_DIR/llvm-project/build/include/llvm/Config"
ls "$WORKING_DIR/llvm-project/build/include/llvm/Config/llvm-config.h" || { echo "llvm-config.h not found. Exiting."; exit 1; }

# Build llvmlite
cd "$WORKING_DIR/llvmlite"
export CXXFLAGS="-I$WORKING_DIR/llvm-project/build/include"
export LLVM_CONFIG="$WORKING_DIR/llvm-project/build/bin/llvm-config"

python3.11 -m pip install .
cd $WORKING_DIR

echo "-------------------successfully Installed llvmlite----------------------"

# Install numpy
python3.11 -m pip install pytest numpy==1.21.1

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.11 -m pip install -r requirements.txt 
python3.11 setup.py build_ext --inplace 

# Install
if !(python3.11 setup.py install) ; then
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
