#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : numba
# Version          : 0.67.0
# Source repo      : https://github.com/numba/numba
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
#                    platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-0.67.0}
PACKAGE_URL=https://github.com/numba/numba
PACKAGE_DIR=numba
CURRENT_DIR=$(pwd)

# Install system dependencies — Python packages first (wrapper requirement)
yum install -y python3.14 python3.14-devel python3.14-pip \
               git make wget cmake ninja-build \
               openssl-devel bzip2-devel libffi-devel zlib-devel \
               gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran

# Activate gcc-toolset-15 (UBI 10 — SCL removed, use guard block)
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
# (numba 0.67.0 requires llvmlite 0.49.0)
# -----------------------------------------------------------------------------
echo "-------------------Installing llvmlite----------------------"

LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-22.1.0"
LLVMLITE_VERSION="v0.49.0"
LLVMLITE_PACKAGE_URL="https://github.com/numba/llvmlite"

LLVM_SRC_DIR=$CURRENT_DIR/llvm-project
LLVM_INSTALL_DIR=$CURRENT_DIR/llvm-install

if [ ! -d "$LLVM_SRC_DIR" ]; then
    git -c advice.detachedHead=false clone --branch $LLVM_PROJECT_GIT_TAG $LLVM_PROJECT_GIT_URL $LLVM_SRC_DIR
fi
cd $LLVM_SRC_DIR
git -c advice.detachedHead=false checkout $LLVM_PROJECT_GIT_TAG

# Build & install LLVM
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
# Build and install OpenBLAS from source (POWER9-optimised)
# -----------------------------------------------------------------------------
echo "---------------------------------Installing OpenBLAS from source----------------"
cd $CURRENT_DIR
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.33
git submodule update --init

LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
export PREFIX=/usr/local

declare -a build_opts
build_opts+=(USE_OPENMP=${USE_OPENMP})

if [ -n "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

build_opts+=(BINARY=64 DYNAMIC_ARCH=1 TARGET="POWER9" BUILD_BFLOAT16=1)
build_opts+=(INTERFACE64=0 SYMBOLSUFFIX="" NO_LAPACK=0)
build_opts+=(USE_THREAD=1 NUM_THREADS=120 NO_AFFINITY=1)

make -j"$(nproc)" "${build_opts[@]}" CFLAGS="${CF}" FFLAGS="${FFLAGS}"
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" "${build_opts[@]}"

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib64:/usr/local/lib"
ldconfig
cd $CURRENT_DIR
echo "--------------------OpenBLAS installed-------------------------------"

# Install Python dependencies
python3.14 -m pip install numpy==2.5.0 setuptools

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

# Test numba
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
