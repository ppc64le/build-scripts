#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package          : llvmlite
# Version          : 0.49.0
# Source repo      : https://github.com/numba/llvmlite
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
#                    platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact the "Maintainer" of this script.
#
# Note: llvmlite 0.49.0 requires LLVM 22 (22.1.0). LLVM has no ppc64le
#       pre-built binary so this script builds LLVM 22.1.0 from source
#       using CMake + Ninja (llvm core only — no clang/lld to stay within
#       CI time limits), then builds llvmlite against it.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=llvmlite
PACKAGE_VERSION=${1:-v0.49.0}
PACKAGE_URL=https://github.com/numba/llvmlite
PACKAGE_DIR=llvmlite
CURRENT_DIR=$(pwd)

LLVM_VERSION=22.1.0
LLVM_SHORT=22

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y --allowerasing git wget cmake ninja-build make \
               openssl-devel bzip2-devel libffi-devel zlib-devel \
               python3.12 python3.12-devel python3.12-pip \
               gcc-toolset-13 curl tar xz pkg-config

source /opt/rh/gcc-toolset-13/enable

echo "Using gcc: $(gcc --version | head -1)"
echo "Using cmake: $(cmake --version | head -1)"
echo "Using ninja: $(ninja --version)"

# ---------------------------------------------------------------------------
# Python build tools
# ---------------------------------------------------------------------------
python3.12 -m pip install --upgrade pip
python3.12 -m pip install "setuptools<70" wheel build

# ---------------------------------------------------------------------------
# Build LLVM 22.1.0 from source (llvm core only — no clang/lld)
# llvmlite 0.49.0 hard-requires LLVM major version 22
# ---------------------------------------------------------------------------
LLVM_SRC_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz"
LLVM_BUILD_DIR="/tmp/llvm-${LLVM_VERSION}-build"
LLVM_INSTALL_PREFIX="/usr/local/llvm${LLVM_SHORT}"

echo "=== Building LLVM ${LLVM_VERSION} from source ==="
mkdir -p "${LLVM_BUILD_DIR}"
cd "${LLVM_BUILD_DIR}"
curl -sSL --fail -o "llvm-project.src.tar.xz" "${LLVM_SRC_URL}"
tar -xJf llvm-project.src.tar.xz
cd "llvm-project-${LLVM_VERSION}.src"

mkdir -p build
cd build

# ppc64le: disable -fno-plt (known compiler bug with LLVM build on ppc64le)
CFLAGS_SAVE="${CFLAGS:-}"
CXXFLAGS_SAVE="${CXXFLAGS:-}"
export CFLAGS="$(echo ${CFLAGS:-} | sed 's/-fno-plt//g')"
export CXXFLAGS="$(echo ${CXXFLAGS:-} | sed 's/-fno-plt//g')"

cmake ../llvm \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="${LLVM_INSTALL_PREFIX}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="PowerPC" \
    -DLLVM_ENABLE_RTTI=OFF \
    -DLLVM_ENABLE_FFI=ON \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DFFI_INCLUDE_DIR=$(pkg-config --variable=includedir libffi 2>/dev/null || echo /usr/include) \
    -DFFI_LIBRARY_DIR=$(pkg-config --variable=libdir libffi 2>/dev/null || echo /usr/lib64)

ninja -j"$(nproc)"
ninja install

export CFLAGS="${CFLAGS_SAVE}"
export CXXFLAGS="${CXXFLAGS_SAVE}"

echo "LLVM ${LLVM_VERSION} installed to ${LLVM_INSTALL_PREFIX}"
echo "llvm-config: $(${LLVM_INSTALL_PREFIX}/bin/llvm-config --version)"

export PATH="${LLVM_INSTALL_PREFIX}/bin:${PATH}"
export LLVM_CONFIG="${LLVM_INSTALL_PREFIX}/bin/llvm-config"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Clone and checkout llvmlite
# ---------------------------------------------------------------------------
git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"
cd "${PACKAGE_DIR}"

if git rev-parse "v${PACKAGE_VERSION#v}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION#v}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# ---------------------------------------------------------------------------
# Build & install llvmlite
# ---------------------------------------------------------------------------
export CXXFLAGS="${CXXFLAGS:-} -fPIC"

if ! python3.12 -m pip install --no-build-isolation . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
if ! python3.12 -m llvmlite.tests ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
