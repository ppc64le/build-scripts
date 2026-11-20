#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : numba
# Version          : 0.68.1
# Source repo      : https://github.com/numba/numba
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pierre-Yves Le Borgne <pylaterreur@gmail.com>
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

# Install system dependencies — Python packages first (wrapper requirement)
yum install -y python3.12 python3.12-devel python3.12-pip \
               git make wget cmake ninja-build \
               openssl-devel bzip2-devel libffi-devel zlib-devel \
               gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran

# Activate gcc-toolset-13
if [[ -f /opt/rh/gcc-toolset-13/enable ]]; then
    source /opt/rh/gcc-toolset-13/enable
elif [[ -d /opt/rh/gcc-toolset-13/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-13 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Upgrade pip and install build tools
python3.12 -m pip install --upgrade pip setuptools wheel ninja

# -----------------------------------------------------------------------------
# Build and install LLVM + llvmlite
# (numba 0.68.1 requires llvmlite 0.50.x, which requires LLVM 22; 22.1.8 is
# the last LLVM 22 bug-fix release, with PowerPC backend fixes made after
# 22.1.0. llvmlite needs neither clang nor lld, so only LLVM is built.)
# -----------------------------------------------------------------------------
echo "-------------------Installing llvmlite----------------------"

LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-22.1.8"
LLVMLITE_VERSION="v0.50.0"
LLVMLITE_PACKAGE_URL="https://github.com/numba/llvmlite"

LLVM_SRC_DIR=$CURRENT_DIR/llvm-project
LLVM_INSTALL_DIR=$CURRENT_DIR/llvm-install

if [ ! -d "$LLVM_SRC_DIR" ]; then
    git -c advice.detachedHead=false clone --depth 1 --branch $LLVM_PROJECT_GIT_TAG $LLVM_PROJECT_GIT_URL $LLVM_SRC_DIR
fi
cd $LLVM_SRC_DIR
git -c advice.detachedHead=false checkout $LLVM_PROJECT_GIT_TAG

# Build & install LLVM
cmake -S llvm -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL_DIR \
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
python3.12 -m pip install --no-build-isolation .

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

# Install Python dependencies. numba builds against NumPy >= 2.0 and runs with
# NumPy < 2.6; pip picks the newest NumPy in that range for the Python in use
# (NumPy 2.5 needs Python >= 3.12, and UBI 9 wheel builds also cover 3.10/3.11).
python3.12 -m pip install "numpy>=2.0,<2.6" setuptools

# Clone and checkout numba
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

export CXXFLAGS=-I/usr/include

# Install numba (build against the numpy installed above instead of building
# another numpy from source in an isolated build environment)
if ! python3.12 -m pip install --no-build-isolation . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Test numba: import its sub-packages, then JIT-compile and run two functions
# (math.ldexp with a negative exponent, fixed for ppc64le in numba 0.68.0, and
# a parallel=True reduction that goes through the threading layer)
cd $CURRENT_DIR
if ! python3.12 -c "import numba; import numba.core.annotations; import numba.core.datamodel; import numba.core.rewrites; import numba.core.runtime; import numba.core.typing; import numba.core.unsafe; import numba.experimental.jitclass; import numba.np.ufunc; import numba.pycc; import numba.scripts; import numba.testing; import numba.tests; import numba.tests.npyufunc;" || \
   ! python3.12 -c "import math, numpy as np, numba; ldexp = numba.njit(lambda x, e: math.ldexp(x, e)); assert ldexp(1.0, -1) == 0.5, ldexp(1.0, -1); psum = numba.njit(parallel=True)(lambda a: a.sum()); assert psum(np.arange(1000.0)) == 499500.0; print('numba', numba.__version__, 'JIT test passed, threading layer:', numba.threading_layer())"; then
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
