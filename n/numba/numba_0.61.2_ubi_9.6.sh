#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.61.2
# Source repo   : https://github.com/numba/numba
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Rushikesh Sathe <Rushikesh.Sathe1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-0.61.2}
PACKAGE_URL=https://github.com/numba/numba
PACKAGE_DIR=numba
WORKING_DIR=$(pwd)
NUMERIC_VERSION=$(echo "$PACKAGE_VERSION" | grep -oP '^\d+(\.\d+){0,2}')
echo "------------------------------------------------------------------"
echo "$WORKING_DIR"
# Install necessary  dependencies

yum install -y git make wget python3.12 python3.12-devel python3.12-pip gcc-toolset-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-13/root/usr/include:$CPATH

yum install -y git make wget openssl-devel bzip2-devel libffi-devel zlib-devel cmake

export LLVM_CONFIG="$WORKING_DIR/llvm-install/bin/llvm-config"
export PATH="$WORKING_DIR/llvm-install/bin:$PATH"

echo "-------------------Installing llvmlite----------------------"

LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-15.0.7"

LLVMLITE_PACKAGE_URL="https://github.com/numba/llvmlite"
LLVMLITE_VERSION="v0.44.0"

LLVM_SRC_DIR=$WORKING_DIR/llvm-project
LLVM_INSTALL_DIR=$WORKING_DIR/llvm-install

git clone -b ${LLVM_PROJECT_GIT_TAG} ${LLVM_PROJECT_GIT_URL}
git clone -b ${LLVMLITE_VERSION} ${LLVMLITE_PACKAGE_URL}

python3.12 -m pip install ninja setuptools==77.0.3

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

cd $WORKING_DIR/llvmlite
# Build & install llvmlite
export CMAKE_PREFIX_PATH=$LLVM_INSTALL_DIR/lib/cmake/llvm
export CXXFLAGS="-fPIC"
python3.12 -m pip install .

echo "-------------------successfully Installed llvmlite----------------------"


echo "---------------------------------Installing openblas from source----------------"
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.32

make -j${MAX_JOBS} TARGET=POWER9 BUILD_BFLOAT16=1 BINARY=64 USE_OPENMP=1 USE_THREAD=1 NUM_THREADS=120 DYNAMIC_ARCH=1 INTERFACE64=0
make install

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib
cd ..
echo "------------openblas installed--------------------"

python3.12 -m pip install numpy==2.0.2

cd $WORKING_DIR

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_DIR
git checkout $PACKAGE_VERSION



# echo "before CXXFLAGS............$CXXFLAGS........."
export CXXFLAGS=-I/usr/include
# echo "after CXXFLAGS............$CXXFLAGS........."

PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

#install
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
cd $WORKING_DIR
if ! python3.12 -c "import numba; import numba.core.annotations; import numba.core.datamodel; import numba.core.rewrites; import numba.core.runtime; import numba.core.typing; import numba.core.unsafe; import numba.experimental.jitclass; import numba.np.ufunc; import numba.pycc; import numba.scripts; import numba.testing; import numba.tests; import numba.tests.npyufunc;"; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

