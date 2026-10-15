#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.56.4
# Source repo   : https://github.com/numba/numba
# Tested on     : UBI 10.2
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
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
PACKAGE_DIR=numba
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install only required dependencies
yum install -y \
    wget git cmake ninja-build make gcc gcc-c++ \
    libffi-devel openssl-devel bzip2-devel xz-devel zlib-devel

# Verify compiler versions
gcc --version
g++ --version

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Install Python 3.10 from source
wget https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tgz
tar xzf Python-3.10.8.tgz
cd Python-3.10.8
CFLAGS="${CPU_FLAGS}" \
CXXFLAGS="${CPU_FLAGS}" \
./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
make -j$(nproc)
make altinstall
export PATH=/usr/local/bin:$PATH
cd ..
rm -f Python-3.10.8.tgz && rm -rf Python-3.10.8

python3.10 -m pip install --upgrade pip
python3.10 -m pip install "setuptools<60" wheel build numpy==1.23.5

echo "-------------------Installing LLVM 11.1.0----------------------"

export PREFIX=/usr

echo "Building LLVM 11.1.0 ..."
rm -rf llvm-project
git clone --depth 1 --branch llvmorg-11.1.0 https://github.com/llvm/llvm-project llvm-project
cd llvm-project

mkdir build && cd build

cmake \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="PowerPC" \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS} -include cstdint" \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_Z3_SOLVER=OFF \
    -DLLVM_ENABLE_FFI=ON \
    -DFFI_INCLUDE_DIR="${PREFIX}/include" \
    -DFFI_LIBRARY_DIR="${PREFIX}/lib" \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -GNinja \
    ../llvm

echo "Building LLVM with $(nproc) jobs..."
ninja -j"$(nproc)"
ninja install

cd ../..
rm -rf llvm-project

echo "-------------------LLVM 11.1.0 installation completed----------------------"

echo "-------------------Building llvmlite wheel----------------------"
rm -rf llvmlite
if ! git clone --depth 1 --branch v0.39.1 https://github.com/numba/llvmlite llvmlite; then
    echo "------------------llvmlite:clone_fails---------------------------------------"
    echo "llvmlite | https://github.com/numba/llvmlite | v0.39.1 | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd llvmlite

export LLVM_CONFIG=/usr/bin/llvm-config
if ! python3.10 -m build --wheel --no-isolation; then
    echo "------------------llvmlite:build_fails---------------------------------------"
    echo "llvmlite | https://github.com/numba/llvmlite | v0.39.1 | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

cd ..

# Clone numba
rm -rf "$PACKAGE_DIR"
if ! git clone --depth 1 --branch $PACKAGE_VERSION $PACKAGE_URL $PACKAGE_DIR; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"

# Build wheel with --no-isolation
if ! python3.10 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

# Create a virtual environment to test the wheel
cd "$WORKING_DIR"
python3.10 -m venv test_env
source test_env/bin/activate
pip install --upgrade pip

# Install wheels and dependencies in the virtual environment
LLVMLITE_WHEEL=$(realpath "$WORKING_DIR"/llvmlite/dist/*.whl)
NUMBA_WHEEL=$(realpath "$WORKING_DIR/$PACKAGE_DIR"/dist/*.whl)
if ! pip install "$LLVMLITE_WHEEL" "$NUMBA_WHEEL" numpy==1.23.5; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test wheel from outside the source tree within the virtual environment
if ! python <<EOF
import numba
import llvmlite
import numpy

print("Numba version:", numba.__version__)
print("llvmlite version:", llvmlite.__version__)
print("NumPy version:", numpy.__version__)

from numba import njit

@njit
def add(a, b):
    return a + b

assert add(2, 3) == 5
print("Numba JIT OK")
EOF
then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
