#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.56.4
# Source repo   : https://github.com/numba/numba
# Tested on     : UBI9.8
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Manya Rusiya <Manya.Rusiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-"0.56.4"}
PACKAGE_URL=https://github.com/numba/numba
WORKING_DIR=$(pwd)

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install all dependencies
yum install -y \
    wget \
    git \
    yum-utils \
    cmake \
    ninja-build \
    make \
    gcc \
    gcc-c++ \
    gcc-toolset-13-gcc \
    gcc-toolset-13-gcc-c++ \
    gcc-toolset-13-gcc-gfortran \
    openldap-devel \
    libffi \
    libffi-devel \
    libxml2 \
    libxml2-devel \
    libxslt \
    libxslt-devel \
    libjpeg-devel \
    openssl \
    openssl-devel \
    postgresql-devel \
    libicu \
    lz4 \
    xz-devel \
    bzip2-devel \
    zlib-devel

# Install Python 3.10
wget https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tgz
tar xzf Python-3.10.8.tgz
cd Python-3.10.8
CFLAGS="${CPU_FLAGS}" \
CXXFLAGS="${CPU_FLAGS}" \
./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
make -j ${nproc}
make altinstall
export PATH=$PATH:/usr/local/bin
cd .. && rm Python-3.10.8.tgz

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-13/root/usr/include:$CPATH
source /opt/rh/gcc-toolset-13/enable

# Apply CPU optimization flags (set earlier based on detected CPU generation)
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"
export LDFLAGS="${CPU_FLAGS}"

gcc --version
g++ --version
gfortran --version

python3.10 -m pip install --upgrade pip
python3.10 -m pip install setuptools==59.8.0 wheel build

echo "-------------------Installing LLVM 11.1.0----------------------"

echo "LLVM version:"
gcc --version
cmake --version
ninja --version

git clone --recursive https://github.com/llvm/llvm-project
cd llvm-project

git checkout llvmorg-11.1.0
sed -i '/#include <string>/a #include <cstdint>'   llvm/include/llvm/Support/Signals.h

export PREFIX=/usr

echo "Building LLVM 11.1.0 ..."

mkdir build
cd build

# LLVM projects
CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_ENABLE_PROJECTS=lld;libunwind;compiler-rt"

# libffi
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_INCLUDE_DIR=${PREFIX}/include"
CMAKE_ARGS="${CMAKE_ARGS} -DFFI_LIBRARY_DIR=${PREFIX}/lib"

# Remove flags that can cause problems while building LLVM
CFLAGS="$(echo "${CFLAGS}" | sed 's/-fno-plt //g')"
CXXFLAGS="$(echo "${CXXFLAGS}" | sed 's/-fno-plt //g')"

export CFLAGS
export CXXFLAGS

echo "Starting cmake ..."

cmake \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_LIBRARY_PATH="${PREFIX}" \
    -DLLVM_TARGETS_TO_BUILD="PowerPC" \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=ON \
    -DLLVM_INCLUDE_UTILS=ON \
    -DLLVM_INSTALL_UTILS=ON \
    -DLLVM_UTILS_INSTALL_DIR=libexec/llvm \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DLLVM_ENABLE_FFI=ON \
    -DLLVM_ENABLE_Z3_SOLVER=OFF \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DCMAKE_POLICY_DEFAULT_CMP0111=NEW \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILTINS_HIDE_SYMBOLS=OFF \
    -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
    -DCOMPILER_RT_BUILD_CRT=OFF \
    -DCOMPILER_RT_BUILD_MEMPROF=OFF \
    -DCOMPILER_RT_BUILD_PROFILE=OFF \
    -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
    -DCOMPILER_RT_BUILD_XRAY=OFF \
    -DCOMPILER_RT_BUILD_GWP_ASAN=OFF \
    -DCOMPILER_RT_BUILD_ORC=OFF \
    -DCOMPILER_RT_INCLUDE_TESTS=OFF \
    ${CMAKE_ARGS} \
    -GNinja \
    ../llvm

export CPU_COUNT=4

echo "Building LLVM with ${CPU_COUNT} jobs..."

ninja -j"${CPU_COUNT}"

echo "Starting make install..."

ninja install

cd ../..

rm -rf llvm-project

echo "-------------------LLVM 11.1.0 installation completed----------------------"

echo "-------------------Installing llvmlite----------------------"

git clone https://github.com/numba/llvmlite

cd llvmlite

git checkout v0.39.1

export LLVM_CONFIG=/usr/bin/llvm-config

python3.10 -m pip install --no-build-isolation .

cd ..

# Install NumPy
python3.10 -m pip install numpy==1.23.5 pytest

# Clone numba
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# Build
python3.10 setup.py build_ext --inplace

# Install
if ! python3.10 setup.py install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test
python3.10 <<EOF
import numba
import llvmlite
import numpy

print(numba.__version__)
print(llvmlite.__version__)
print(numpy.__version__)

from numba import njit

@njit
def add(a,b):
    return a+b

assert add(2,3)==5

print("Numba JIT OK")
EOF

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
