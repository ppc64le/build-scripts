#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : numba
# Version          : 0.68.1
# Source repo      : https://github.com/numba/numba
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
#                    platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-0.68.1}
PACKAGE_URL=https://github.com/numba/numba
PACKAGE_DIR=numba
CURRENT_DIR=$(pwd)

# Install system dependencies (Python packages first, wrapper requirement)
yum install -y python3.14 python3.14-devel python3.14-pip \
               git make wget cmake ninja-build \
               openssl-devel bzip2-devel libffi-devel zlib-devel \
               gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran

# Activate gcc-toolset-15 (UBI 10 has no SCL, so guard both layouts)
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Upgrade pip and install build tools
python3.14 -m pip install --upgrade pip setuptools wheel ninja

# -----------------------------------------------------------------------------
# Build and install LLVM + llvmlite
# (numba 0.68.1 needs llvmlite 0.50.x, which is built against LLVM 22.1.0)
# -----------------------------------------------------------------------------
echo "-------------------Installing llvmlite----------------------"

LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-22.1.0"
LLVMLITE_VERSION="v0.50.0"
LLVMLITE_PACKAGE_URL="https://github.com/numba/llvmlite"

LLVM_SRC_DIR=$CURRENT_DIR/llvm-project
LLVM_INSTALL_DIR=$CURRENT_DIR/llvm-install

if [ ! -d "$LLVM_SRC_DIR" ]; then
    git -c advice.detachedHead=false clone --branch $LLVM_PROJECT_GIT_TAG $LLVM_PROJECT_GIT_URL $LLVM_SRC_DIR
fi
cd $LLVM_SRC_DIR
git -c advice.detachedHead=false checkout $LLVM_PROJECT_GIT_TAG

# Build and install LLVM
cmake -S llvm -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL_DIR \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_TARGETS_TO_BUILD="PowerPC"

cmake --build build --target install -j$(nproc)

cd $CURRENT_DIR
if [ ! -d "llvmlite" ]; then
    git clone $LLVMLITE_PACKAGE_URL
fi
cd llvmlite
git checkout $LLVMLITE_VERSION

export CMAKE_PREFIX_PATH=$LLVM_INSTALL_DIR/lib/cmake/llvm
export CXXFLAGS="-fPIC"
python3.14 -m pip install --no-build-isolation .

echo "-------------------Successfully installed llvmlite----------------------"

# -----------------------------------------------------------------------------
# Install OpenBLAS from the IBM DeveloperFirst (devpi) index
# -----------------------------------------------------------------------------
echo "---------------------------------Installing OpenBLAS from devpi----------------"
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
python3.14 -m pip install --prefer-binary --extra-index-url ${IBM_WHEELS} openblas==0.3.33

SITE_PACKAGES=$(python3.14 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
export OpenBLAS_HOME=${SITE_PACKAGES}/openblas
export OpenBLAS_DIR=${OpenBLAS_HOME}
export LD_LIBRARY_PATH=${OpenBLAS_HOME}/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH=${OpenBLAS_HOME}/lib/pkgconfig:${PKG_CONFIG_PATH}
cd $CURRENT_DIR
echo "--------------------OpenBLAS installed-------------------------------"

# Install Python dependencies (numba 0.68.1 supports numpy < 2.6)
python3.14 -m pip install "numpy<2.6" setuptools

# Clone and checkout numba
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

export CXXFLAGS=-I/usr/include

# Install numba
if ! python3.14 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test numba from outside the source tree
cd $CURRENT_DIR
if ! python3.14 -c "import numba; import numba.core.annotations; import numba.core.datamodel; import numba.core.rewrites; import numba.core.runtime; import numba.core.typing; import numba.core.unsafe; import numba.experimental.jitclass; import numba.np.ufunc; import numba.pycc; import numba.scripts; import numba.testing; import numba.tests; import numba.tests.npyufunc;"; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
