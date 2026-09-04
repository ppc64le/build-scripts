#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : llvmlite
# Version          : 0.49.0
# Source repo      : https://github.com/numba/llvmlite
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Note: llvmlite 0.49.0 requires LLVM 22 (22.1.0). LLVM has no ppc64le
#       pre-built binary so this script builds LLVM 22.1.0 from source
#       using CMake + Ninja, then builds llvmlite against it.
#       numpy 2.5.1 is installed as a runtime companion (required by numba),
#       sourced from https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=llvmlite
PACKAGE_VERSION=${1:-0.49.0}
PACKAGE_URL=https://github.com/numba/llvmlite
PACKAGE_DIR=llvmlite
CURRENT_DIR=$(pwd)

LLVM_VERSION=22.1.0
LLVM_SHORT=22
PYTHON_VERSION=3.12
PYTHON_BIN=$(which python3.12)

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake ninja-build \
    libffi-devel zlib-devel \
    curl tar xz which patch diffutils

# UBI 10 dropped SCL — guard block
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
echo "Using cmake: $(cmake --version | head -1)"
echo "Using ninja: $(ninja --version)"

# ---------------------------------------------------------------------------
# Python build tools
# ---------------------------------------------------------------------------
pip install --upgrade pip setuptools wheel build
pip install "numpy==2.5.1" --index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/ --extra-index-url https://pypi.org/simple

# ---------------------------------------------------------------------------
# Build LLVM 22.1.0 from source for ppc64le
# llvmlite 0.49.0 hard-requires LLVM major version 22 (CMakeLists.txt line 27)
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
# See: https://bugs.llvm.org/show_bug.cgi?id=51863
CFLAGS_SAVE="${CFLAGS}"
CXXFLAGS_SAVE="${CXXFLAGS}"
export CFLAGS="$(echo ${CFLAGS:-} | sed 's/-fno-plt//g')"
export CXXFLAGS="$(echo ${CXXFLAGS:-} | sed 's/-fno-plt//g')"

cmake ../llvm \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="${LLVM_INSTALL_PREFIX}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="lld" \
    -DLLVM_TARGETS_TO_BUILD="PowerPC;X86;AArch64;WebAssembly" \
    -DLLVM_ENABLE_RTTI=OFF \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_ENABLE_FFI=ON \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_GO_TESTS=OFF \
    -DLLVM_INCLUDE_UTILS=ON \
    -DLLVM_INSTALL_UTILS=ON \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DCMAKE_POLICY_DEFAULT_CMP0111=NEW \
    -DFFI_INCLUDE_DIR=$(pkg-config --variable=includedir libffi 2>/dev/null || echo /usr/include) \
    -DFFI_LIBRARY_DIR=$(pkg-config --variable=libdir libffi 2>/dev/null || echo /usr/lib64) \
    -DCMAKE_CXX_STANDARD=17

ninja -j"$(nproc)"
ninja install

# Restore CFLAGS/CXXFLAGS
export CFLAGS="${CFLAGS_SAVE}"
export CXXFLAGS="${CXXFLAGS_SAVE}"

echo "LLVM ${LLVM_VERSION} installed to ${LLVM_INSTALL_PREFIX}"
echo "llvm-config: $(${LLVM_INSTALL_PREFIX}/bin/llvm-config --version)"

# Make llvm-config findable for llvmlite's CMake probe
export PATH="${LLVM_INSTALL_PREFIX}/bin:${PATH}"
export LLVM_CONFIG="${LLVM_INSTALL_PREFIX}/bin/llvm-config"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Clone and checkout llvmlite
# ---------------------------------------------------------------------------
git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"
cd "${PACKAGE_DIR}"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# ---------------------------------------------------------------------------
# Build llvmlite wheel
# ffi/build.py uses CMake internally; LLVMLITE_PACKAGE_FORMAT=wheel tells it
# to produce a shared library suitable for wheel packaging.
# ---------------------------------------------------------------------------
export LLVMLITE_PACKAGE_FORMAT="wheel"
export LLVMLITE_USE_RTTI="OFF"

# Ensure libffi headers are visible to CMake
export CXXFLAGS="${CXXFLAGS:-} -fPIC"

if ! python3.12 setup.py bdist_wheel; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp dist/*.whl "${CURRENT_DIR}/"

# ---------------------------------------------------------------------------
# Install wheel and test
# ---------------------------------------------------------------------------
pip install "${CURRENT_DIR}"/llvmlite-*.whl

if ! python3.12 -c "
import llvmlite
import llvmlite.binding as llvm
# initialize(), initialize_native_target(), initialize_native_asmprinter()
# were removed in llvmlite 0.44+; LLVM init is now automatic.
print('llvmlite version:', llvmlite.__version__)
print('LLVM version:', llvm.llvm_version_info)
print('llvmlite import OK')
"; then
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
