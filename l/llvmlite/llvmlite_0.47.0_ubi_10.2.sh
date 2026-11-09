#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : llvmlite
# Version       : 0.47.0
# Source repo   : https://github.com/numba/llvmlite
# Tested on     : UBI:10.2
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
PACKAGE_VERSION=${1:-v0.47.0}
PACKAGE_URL=https://github.com/numba/llvmlite
PACKAGE_DIR=llvmlite
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

LLVM_VERSION="20.1.8"
LLVM_TAG="llvmorg-${LLVM_VERSION}"
LLVM_PREFIX="${LLVM_PREFIX:-"/opt/llvm-${LLVM_VERSION}"}"

# -----------------------------------------------------------------------------
# CPU optimization flags
# -----------------------------------------------------------------------------
if [ -z "${CPU_FLAGS+x}" ]; then
    if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
        CPU_FLAGS="-mcpu=power10 -mtune=power10"
        echo "Detected POWER10 - applying power10 optimization flags"
    else
        CPU_FLAGS=""
        echo "POWER10 not detected - no arch-specific flags applied"
    fi
else
    echo "Using caller supplied CPU_FLAGS='${CPU_FLAGS}'"
fi

export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
yum install -y wget git make gcc gcc-c++ \
    python3-pip python3-devel \
    libffi-devel openssl-devel bzip2-devel xz-devel zlib-devel

gcc --version
g++ --version

python3 --version
python3 -m pip install --upgrade pip
python3 -m pip install setuptools wheel build auditwheel patchelf cmake ninja
cmake --version
ninja --version

# -----------------------------------------------------------------------------
# Install LLVM
# -----------------------------------------------------------------------------
echo "-------------------Installing LLVM ${LLVM_VERSION}----------------------"

if [ -f "${LLVM_PREFIX}/lib64/cmake/llvm/LLVMConfig.cmake" ] || \
   [ -f "${LLVM_PREFIX}/lib/cmake/llvm/LLVMConfig.cmake" ]; then
    echo "LLVM ${LLVM_VERSION} already present in ${LLVM_PREFIX} - reusing"
else
    echo "Building LLVM ${LLVM_VERSION} ..."
    rm -rf llvm-project
    if ! git clone --depth 1 --branch ${LLVM_TAG} https://github.com/llvm/llvm-project llvm-project; then
        echo "------------------llvm-project:clone_fails---------------------------------------"
        echo "llvm-project | https://github.com/llvm/llvm-project | ${LLVM_TAG} | $OS_NAME | GitHub | Fail | Clone_Fails"
        exit 1
    fi
    cd llvm-project
    mkdir build && cd build

    cmake \
        -DCMAKE_INSTALL_PREFIX="${LLVM_PREFIX}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_TARGETS_TO_BUILD="PowerPC" \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_ENABLE_LIBEDIT=OFF \
        -DLLVM_ENABLE_LIBXML2=OFF \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_ENABLE_Z3_SOLVER=OFF \
        -DLLVM_ENABLE_ZLIB=OFF \
        -DLLVM_ENABLE_ZSTD=OFF \
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

    cd "$WORKING_DIR"
    rm -rf llvm-project
fi

export CMAKE_PREFIX_PATH="${LLVM_PREFIX}${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export PATH="${LLVM_PREFIX}/bin:$PATH"
export LLVM_CONFIG="${LLVM_PREFIX}/bin/llvm-config"
llvm-config --version

echo "-------------------LLVM ${LLVM_VERSION} installation completed----------------------"

# -----------------------------------------------------------------------------
# Build llvmlite wheel
# -----------------------------------------------------------------------------
echo "-------------------Building llvmlite ${PACKAGE_VERSION} wheel----------------------"

rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | ${PACKAGE_VERSION} | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"
if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | ${PACKAGE_VERSION} | $OS_NAME | GitHub | Fail | Tag_Not_Found"
    exit 1
fi

if ! python3 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | ${PACKAGE_VERSION} | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi
cd "$WORKING_DIR"

echo "-------------------llvmlite wheel built successfully----------------------"

# -----------------------------------------------------------------------------
# Repair llvmlite wheel with auditwheel - bundles non-system shared libraries
# and retags the wheel as manylinux.
# -----------------------------------------------------------------------------
echo "-------------------Repairing llvmlite wheel with auditwheel----------------------"

WHEEL_DIR="$WORKING_DIR/$PACKAGE_DIR/dist"
REPAIRED_DIR="$WORKING_DIR/repaired_dist"
rm -rf "$REPAIRED_DIR"
mkdir -p "$REPAIRED_DIR"

if ! python3 -m auditwheel repair \
        --wheel-dir "$REPAIRED_DIR" \
        "$WHEEL_DIR"/*.whl; then
    echo "------------------$PACKAGE_NAME:auditwheel_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | ${PACKAGE_VERSION} | $OS_NAME | GitHub | Fail | Auditwheel_Fails"
    exit 1
fi
echo "-------------------auditwheel repair completed----------------------"
echo "Repaired wheel:"
ls -lh "$REPAIRED_DIR"/*.whl

# -----------------------------------------------------------------------------
# Install repaired llvmlite wheel
# -----------------------------------------------------------------------------
echo "-------------------Installing and testing llvmlite----------------------"

if ! python3 -m pip install "$REPAIRED_DIR"/*.whl; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | ${PACKAGE_VERSION} | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# Smoke test - run from /tmp so Python imports the installed llvmlite, not the
# source tree.
# -----------------------------------------------------------------------------
cd /tmp
if ! python3 -c "
import llvmlite, llvmlite.binding as llvm
print('llvmlite', llvmlite.__version__, '| LLVM', llvm.llvm_version_info, '|', llvm.get_default_triple())
assert llvmlite.__version__ == '${PACKAGE_VERSION#v}'
assert llvm.llvm_version_info[0] == 20
assert 'powerpc64le' in llvm.get_default_triple()
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    cd "$WORKING_DIR"
    exit 2
fi

# -----------------------------------------------------------------------------
# llvmlite test suite - ships inside the wheel as llvmlite.tests.
# -----------------------------------------------------------------------------
echo "-------------------Running llvmlite test suite----------------------"
if ! python3 -m llvmlite.tests 2>&1; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    cd "$WORKING_DIR"
    exit 2
fi
cd "$WORKING_DIR"

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "Wheel: $(ls "$REPAIRED_DIR"/*.whl)"
exit 0
