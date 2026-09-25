#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : llvmlite
# Version       : 0.39.1
# Source repo   : https://github.com/numba/llvmlite
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

PACKAGE_NAME=llvmlite
PACKAGE_VERSION=${1:-"v0.39.1"}
PACKAGE_URL=https://github.com/numba/llvmlite
PACKAGE_DIR=llvmlite
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

LLVM_VERSION=11.1.0
LLVM_TAG=llvmorg-${LLVM_VERSION}

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
python3.10 -m pip install "setuptools<60" wheel build

echo "-------------------Installing LLVM ${LLVM_VERSION}----------------------"

export PREFIX=/usr

echo "Building LLVM ${LLVM_VERSION} ..."
rm -rf llvm-project
git clone --depth 1 --branch ${LLVM_TAG} https://github.com/llvm/llvm-project llvm-project
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

echo "-------------------LLVM ${LLVM_VERSION} installation completed----------------------"

echo "-------------------Building llvmlite ${PACKAGE_VERSION} wheel----------------------"

rm -rf "$PACKAGE_DIR"
if ! git clone --depth 1 --branch ${PACKAGE_VERSION} ${PACKAGE_URL} ${PACKAGE_DIR}; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"

export LLVM_CONFIG=/usr/bin/llvm-config

# Build the llvmlite wheel
if ! python3.10 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

echo "-------------------llvmlite wheel built successfully----------------------"
echo "Wheel location: $(realpath dist/*.whl)"

# Create a virtual environment to test the wheel
cd "$WORKING_DIR"
python3.10 -m venv test_env
source test_env/bin/activate
pip install --upgrade pip

LLVMLITE_WHEEL=$(realpath "$WORKING_DIR/$PACKAGE_DIR"/dist/*.whl)

if ! pip install "$LLVMLITE_WHEEL"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the installed wheel
if ! python <<EOF
import llvmlite
import llvmlite.binding as llvm

print("llvmlite version:", llvmlite.__version__)

# Basic smoke test — initialise LLVM targets
llvm.initialize()
llvm.initialize_native_target()
llvm.initialize_native_asmprinter()
print("LLVM target initialisation: OK")

# Verify that the PowerPC target is available (required for numba on Power)
target = llvm.Target.from_triple("powerpc64le-unknown-linux-gnu")
print("PowerPC64LE target: OK —", target.name)
EOF
then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
