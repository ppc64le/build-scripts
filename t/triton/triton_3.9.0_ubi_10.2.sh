
#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : triton
# Version       : 3.9.0
# Source repo   : https://github.com/triton-lang/triton
# Tested on     : UBI 10.2
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : vrushanaik <Vrusha.Naik@ibm.com>
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
PACKAGE_VERSION=${1:-3.9.0}
PACKAGE_URL=https://github.com/triton-lang/triton
PACKAGE_DIR=triton
CURRENT_DIR=$(pwd)

LLVM_BUILD_DIR="${CURRENT_DIR}/llvm-project"
LLVM_INSTALL_DIR="${CURRENT_DIR}/llvm-install"

# Separate LLVM build required for AMD code generation
AMD_LLVM_BUILD_DIR="${CURRENT_DIR}/amd-llvm-project"
AMD_LLVM_INSTALL_DIR="${CURRENT_DIR}/amd-llvm-install"

AMD_CODEGEN_BUILD_DIR="${CURRENT_DIR}/amd-codegen-build"
AMD_CODEGEN_INSTALL_DIR="${CURRENT_DIR}/amd-codegen-install"

AMD_LLVM_INFO_FILE="$CURRENT_DIR/$PACKAGE_DIR/cmake/amd-llvm-info.json"

if [[ ! -f "$AMD_LLVM_INFO_FILE" ]]; then
    echo "ERROR: AMD LLVM metadata file not found"
    exit 1
fi

AMD_LLVM_COMMIT=$(python3.12 -c \
    "import json; print(json.load(open('$AMD_LLVM_INFO_FILE'))['llvm_hash'])")

AMD_LLVM_BUILD_NUMBER=$(python3.12 -c \
    "import json; print(json.load(open('$AMD_LLVM_INFO_FILE'))['build_number'])")

if [[ ! "$AMD_LLVM_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
    echo "ERROR: Invalid AMD LLVM commit: $AMD_LLVM_COMMIT"
    exit 1
fi

AMD_LLVM_REVISION="${AMD_LLVM_COMMIT}-${AMD_LLVM_BUILD_NUMBER}"

echo "AMD LLVM commit: $AMD_LLVM_COMMIT"
echo "AMD LLVM revision: $AMD_LLVM_REVISION"

# Install system dependencies
yum install -y \
    python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake ninja-build zlib-devel make

# Configure GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using GCC: $(gcc --version | head -1)"
echo "Using Python: $(python3.12 --version)"

# Install Python build tools
python3.12 -m pip install --upgrade pip setuptools wheel
python3.12 -m pip install ninja cmake pybind11 packaging

# Clone Triton repository
cd "$CURRENT_DIR"

git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

# Checkout requested release
if git rev-parse "v${PACKAGE_VERSION}" >/dev/null 2>&1; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" >/dev/null 2>&1; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No Git tag found for ${PACKAGE_VERSION}"
    exit 1
fi

# Create release branch
git checkout -b "release/${PACKAGE_VERSION}"

# Initialize submodules
git submodule sync --recursive
git submodule update --init --recursive

# Read LLVM commit from Triton 3.9.0 metadata
LLVM_INFO_FILE="$CURRENT_DIR/$PACKAGE_DIR/cmake/llvm-info.json"

if [[ ! -f "$LLVM_INFO_FILE" ]]; then
    echo "ERROR: LLVM metadata file not found: $LLVM_INFO_FILE"
    exit 1
fi

LLVM_COMMIT=$(python3.12 -c \
    "import json; print(json.load(open('$LLVM_INFO_FILE'))['llvm_hash'])")

if [[ ! "$LLVM_COMMIT" =~ ^[0-9a-f]{40}$ ]]; then
    echo "ERROR: Invalid LLVM commit hash: $LLVM_COMMIT"
    exit 1
fi

echo "Triton requires LLVM commit: $LLVM_COMMIT"

# Install Triton build requirements
python3.12 -m pip install -r python/requirements.txt

# Clone LLVM repository
cd "$CURRENT_DIR"

git clone https://github.com/llvm/llvm-project.git "$LLVM_BUILD_DIR"

cd "$LLVM_BUILD_DIR"

git fetch origin "$LLVM_COMMIT"
git checkout "$LLVM_COMMIT"

# Configure LLVM build
mkdir -p build
cd build

NPROC=$(nproc)
MAX_JOBS=${MAX_JOBS:-$(( NPROC < 16 ? NPROC : 16 ))}

export MAX_JOBS

echo "Building LLVM with $MAX_JOBS jobs"

cmake ../llvm \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL_DIR" \
    -DLLVM_ENABLE_PROJECTS="mlir;lld;clang" \
    -DLLVM_TARGETS_TO_BUILD="PowerPC;NVPTX;AMDGPU" \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INSTALL_UTILS=ON \
    -DMLIR_ENABLE_BINDINGS_PYTHON=OFF \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DLLVM_PARALLEL_LINK_JOBS=4

ninja -j"$MAX_JOBS" install

export LLVM_SYSPATH="$LLVM_INSTALL_DIR"

echo "LLVM installed at: $LLVM_SYSPATH"

# Install nlohmann/json dependency
JSON_VERSION=$(cat "$CURRENT_DIR/$PACKAGE_DIR/cmake/json-version.txt")

JSON_INSTALL_DIR="$CURRENT_DIR/json"
JSON_URL="https://github.com/nlohmann/json/releases/download/${JSON_VERSION}/include.zip"

echo "Installing nlohmann/json version: $JSON_VERSION"

yum install -y curl unzip

mkdir -p "$JSON_INSTALL_DIR"

curl -fL "$JSON_URL" -o "$CURRENT_DIR/json-include.zip"

unzip -q -o "$CURRENT_DIR/json-include.zip" -d "$JSON_INSTALL_DIR"

# Configure JSON path for Triton
export JSON_SYSPATH="$JSON_INSTALL_DIR"

# Verify installation
if [[ ! -f "$JSON_SYSPATH/include/nlohmann/json.hpp" ]]; then
    echo "ERROR: nlohmann/json headers not found"
    exit 1
fi

echo "JSON installed to $JSON_SYSPATH"

# ------------------------------------------------------------
# Build separate AMD LLVM required by Triton 3.9.0
# ------------------------------------------------------------

echo "Building AMD-specific LLVM: $AMD_LLVM_COMMIT"

cd "$CURRENT_DIR"

git clone https://github.com/triton-lang/llvm-project.git \
    "$AMD_LLVM_BUILD_DIR"

cd "$AMD_LLVM_BUILD_DIR"

git fetch origin "$AMD_LLVM_COMMIT"
git checkout "$AMD_LLVM_COMMIT"

mkdir -p build
cd build

cmake ../llvm \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$AMD_LLVM_INSTALL_DIR" \
    -DLLVM_TARGETS_TO_BUILD="AMDGPU" \
    -DLLVM_ENABLE_PROJECTS="" \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_ENABLE_PIC=ON \
    -DLLVM_ENABLE_RTTI=OFF \
    -DLLVM_ENABLE_EH=OFF \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_PARALLEL_LINK_JOBS=2 \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++

ninja -j"$MAX_JOBS" install

# Verify AMD LLVM installation
AMD_LLVM_CONFIG="$AMD_LLVM_INSTALL_DIR/lib/cmake/llvm/LLVMConfig.cmake"

if [[ ! -f "$AMD_LLVM_CONFIG" ]]; then
    echo "ERROR: AMD LLVMConfig.cmake not found"
    exit 1
fi

echo "AMD LLVM installed at: $AMD_LLVM_INSTALL_DIR"


# ------------------------------------------------------------
# Build Triton AMD code-generation shared library
# ------------------------------------------------------------

echo "Building Triton AMD code-generation library"

cd "$CURRENT_DIR/$PACKAGE_DIR"

cmake \
    -G Ninja \
    -S third_party/amd/backend/codegen \
    -B "$AMD_CODEGEN_BUILD_DIR" \
    -DLLVM_DIR="$AMD_LLVM_INSTALL_DIR/lib/cmake/llvm" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$AMD_CODEGEN_INSTALL_DIR" \
    -DTRITON_AMD_LLVM_REVISION="$AMD_LLVM_REVISION"
    
cmake --build "$AMD_CODEGEN_BUILD_DIR" \
    --target triton_amd_codegen \
    --parallel "$MAX_JOBS"

cmake --install "$AMD_CODEGEN_BUILD_DIR"

# Configure AMD code-generation library path
export TRITON_AMD_CODEGEN_PATH="$AMD_CODEGEN_INSTALL_DIR/lib/libtriton_amd_codegen.so"

# Verify library
echo "Checking AMD codegen library dependencies"

ldd "$TRITON_AMD_CODEGEN_PATH"

if ldd "$TRITON_AMD_CODEGEN_PATH" | grep -q "not found"; then
    echo "ERROR: Missing shared-library dependencies for AMD codegen"
    exit 1
fi

echo "AMD code-generation library: $TRITON_AMD_CODEGEN_PATH"

# Configure Triton build
cd "$CURRENT_DIR/$PACKAGE_DIR"

export LLVM_SYSPATH="$LLVM_INSTALL_DIR"
export JSON_SYSPATH="$JSON_INSTALL_DIR"
export TRITON_AMD_CODEGEN_PATH

export TRITON_BUILD_WITH_CLANG_LLD=0
export TRITON_OFFLINE_BUILD=1
export TRITON_BUILD_PROTON=0
export CMAKE_ARGS="-DTRITON_BUILD_PROTON=OFF"

# Install Triton
if ! python3.12 -m pip install --no-build-isolation -e .; then
    echo "------------------TRITON:Install_fails------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Build wheel
mkdir -p dist

if ! python3.12 -m pip wheel \
    --no-build-isolation \
    --no-deps \
    -w dist .; then
    echo "ERROR: Triton wheel build failed"
    exit 1
fi

# Copy wheel to current directory
cp dist/*.whl "$CURRENT_DIR/"

# Test installation
if ! python3.12 -c "import triton; print('Triton import OK:', triton.__version__)"; then
    echo "------------------TRITON:Install_success_but_test_fails------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Import_Test_Fails"
    exit 2
else
    echo "------------------TRITON:Install_&_test_both_success------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
