#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : triton
# Version       : 3.6.0
# Source repo   : https://github.com/triton-lang/triton
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Daniel Schenker <daniel.schenker@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=triton
PACKAGE_VERSION=${1:-3.6.0}
PACKAGE_URL=https://github.com/triton-lang/triton
PACKAGE_DIR=triton
CURRENT_DIR=$(pwd)

LLVM_BUILD_DIR="${CURRENT_DIR}/llvm-project"
LLVM_INSTALL_DIR="${CURRENT_DIR}/llvm-install"

# Install dependencies
yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake ninja-build zlib-devel make

# Configure GCC Toolset 15
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

# Install Python build tools
pip install --upgrade pip setuptools wheel ninja cmake pybind11

# Clone repository
cd $CURRENT_DIR
git clone $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR

# Checkout version — try v-prefixed tag first, then bare version
if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Create a local branch named release/<version> so that setup.py's
# get_git_version_suffix() sees a branch starting with "release" and
# suppresses the +gitXXXXXXXX hash from the wheel filename.
# Without this, detached HEAD makes git report "HEAD" as the branch name
# and the hash is always appended.
git checkout -b "release/${PACKAGE_VERSION}"

git submodule sync --recursive
git submodule update --init --recursive

# Read the LLVM commit hash pinned by this Triton release
LLVM_HASH_FILE="$CURRENT_DIR/$PACKAGE_DIR/cmake/llvm-hash.txt"
if [[ ! -f "$LLVM_HASH_FILE" ]]; then
    echo "ERROR: Expected LLVM hash file not found: $LLVM_HASH_FILE"
    exit 1
fi
LLVM_COMMIT="$(cat "$LLVM_HASH_FILE")"
echo "Triton requires LLVM commit: $LLVM_COMMIT"

# Build LLVM from source
# Triton does not provide pre-built LLVM binaries for ppc64le.
# We build the minimum set of LLVM targets needed by Triton:
#   PowerPC (ppc64le native codegen), NVPTX (GPU), AMDGPU (GPU), WebAssembly,
#   and the MLIR + LLD libraries that Triton requires.
cd $CURRENT_DIR
git clone https://github.com/llvm/llvm-project.git $LLVM_BUILD_DIR
cd $LLVM_BUILD_DIR
git fetch origin "$LLVM_COMMIT" 2>/dev/null || git fetch origin
git checkout "$LLVM_COMMIT"

mkdir -p build
cd build

NPROC="$(nproc)"
MAX_JOBS="${MAX_JOBS:-$(( NPROC < 16 ? NPROC : 16 ))}"
export MAX_JOBS

cmake ../llvm \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL_DIR" \
    -DLLVM_ENABLE_PROJECTS="mlir;lld;clang" \
    -DLLVM_TARGETS_TO_BUILD="PowerPC;NVPTX;AMDGPU;WebAssembly" \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INSTALL_UTILS=ON \
    -DMLIR_ENABLE_BINDINGS_PYTHON=OFF \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DLLVM_PARALLEL_LINK_JOBS=4

ninja -j"$MAX_JOBS" install
export LLVM_SYSPATH="$LLVM_INSTALL_DIR"
echo "LLVM installed to $LLVM_SYSPATH"

# Build Triton wheel
# LLVM_SYSPATH tells setup.py where our built LLVM lives, bypassing the
# upstream prebuilt-binary download (which has no ppc64le image).
# TRITON_BUILD_WITH_CLANG_LLD=0 keeps the GCC toolchain active.
# TRITON_OFFLINE_BUILD=1 prevents downloading CUDA/NVIDIA binaries (no
# ppc64le packages on NVIDIA's CDN; NVIDIA backend unused on this platform).
# TRITON_BUILD_PROTON=0 / CMAKE_ARGS disables the Proton GPU profiling
# dialect, avoiding JSON_SYSPATH requirement and the ProtonGPUIR build failure.
cd $CURRENT_DIR/$PACKAGE_DIR

export LLVM_SYSPATH
export TRITON_BUILD_WITH_CLANG_LLD=0
export TRITON_OFFLINE_BUILD=1
# Disable Proton via both the env-var spelling Triton's setup.py checks AND
# via CMAKE_ARGS so the sub-CMake invocation it spawns also sees it.
# Using integer 0 (not string "OFF") matches the os.environ check in setup.py.
export TRITON_BUILD_PROTON=0
export CMAKE_ARGS="-DTRITON_BUILD_PROTON=OFF"

# Install package
# Use 'pip install' instead of the deprecated 'setup.py install' which is
# unsupported on Python 3.12 and can silently mis-install with new setuptools.
if ! pip install --no-build-isolation -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR
pip wheel --no-build-isolation --no-deps -w dist .
cp dist/*.whl $CURRENT_DIR/

# Run tests
if ! python3.12 -c "import triton; print('triton import OK')" ; then
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
