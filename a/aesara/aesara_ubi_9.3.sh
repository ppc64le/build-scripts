#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : aesara
# Version       : rel-2.9.4
# Source repo   : https://github.com/aesara-devs/aesara
# Tested on     : UBI: 9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=aesara
PACKAGE_VERSION=${1:-rel-2.9.4}
PACKAGE_URL=https://github.com/aesara-devs/aesara
WORKING_DIR=$(pwd)

yum install -y wget yum-utils python3.11-devel python3.11-pip gcc-toolset-13

yum install -y git make openssl-devel openblas-devel bzip2-devel libffi-devel zlib-devel cmake
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

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

python3.11 -m pip install  requests==2.26.0 wheel tox pytest 
python3.11 -m pip install numpy==1.26.4 setuptools==68.2.2 
python3.11 -m pip install typing_extensions scipy cons etuples kanren
python3.11 -m pip install --no-build-isolation numba

git clone https://github.com/pythological/unification.git
cd unification
python3.11 -m pip install .
cd $WORKING_DIR

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python3.11 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Skipping these tests as per aesara's CI.

if ! pytest \
    --ignore=tests/link/numba \
    --ignore=tests/test_printing.py \
    --ignore=tests/compile/test_mode.py \
    --ignore=tests/link/test_vm.py \
    --ignore=tests/link/c/test_op.py \
    --ignore=tests/tensor/nnet \
    --ignore=tests/tensor/rewriting/test_shape.py \
    --ignore=tests/tensor/signal \
    --ignore=tests/tensor/random \
    --ignore=tests/scan/ \
    -p no:warnings \
    -p no:xfail ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
