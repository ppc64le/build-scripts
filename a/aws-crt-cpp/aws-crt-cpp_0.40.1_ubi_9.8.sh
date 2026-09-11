#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : aws-crt-cpp
# Version       : v0.40.1
# Source repo   : https://github.com/awslabs/aws-crt-cpp
# Tested on     : UBI 9.8
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=aws-crt-cpp
PACKAGE_VERSION=${1:-"v0.40.1"}
PACKAGE_URL=https://github.com/awslabs/aws-crt-cpp
WORKING_DIR=$(pwd)
INSTALL_PREFIX=${2:-/usr/local}

# Detect POWER10 and set CPU optimization flags accordingly
if grep -qi "power10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies
yum install -y --allowerasing \
    wget \
    git \
    cmake \
    make \
    gcc \
    gcc-c++ \
    gcc-toolset-13-gcc \
    gcc-toolset-13-gcc-c++ \
    openssl \
    openssl-devel \
    libcurl \
    libxml2-devel \
    zlib-devel \
    pkg-config \
    tar \
    perl-FindBin \
    perl-File-Compare \
    python3-pip \
    ca-certificates

# Activate GCC Toolset 13 (provides GCC 13 on UBI 9)
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-13/root/usr/include:$CPATH
. /opt/rh/gcc-toolset-13/enable

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"
export LDFLAGS="${CPU_FLAGS}"

# Clone source
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
SOURCE_DIR=$(pwd)

# Configure from repo root so azure-core resolves in-tree
mkdir -p build && cd build

if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
		-DBUILD_DEPS=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=ON \
        -DWARNINGS_AS_ERRORS=OFF; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

if ! cmake --build . -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

if ! cmake --install .; then

    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! ctest --output-on-failure -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

cd "$SOURCE_DIR"

# Step 2: Prepare wheel directory structure
echo "Preparing wheel structure..."
LOCAL_PKG="${SOURCE_DIR}/local/aws_crt_cpp"

mkdir -p "${LOCAL_PKG}/lib64" \
         "${LOCAL_PKG}/lib" \
         "${LOCAL_PKG}/include" \
         "${LOCAL_PKG}/cmake" 		 

# Copy from lib64 if it exists
if [ -d "${INSTALL_PREFIX}/lib64" ]; then
    echo "  Copying from lib64..."
    # Copy shared libraries
    cp -r ${INSTALL_PREFIX}/lib64/*.so* local/aws_crt_cpp/lib64/ 2>/dev/null || true
    # Copy static libraries
    cp -r ${INSTALL_PREFIX}/lib64/*.a local/aws_crt_cpp/lib64/ 2>/dev/null || true
    # Copy CMake files
    find ${INSTALL_PREFIX}/lib64 -name "*.cmake" -exec cp {} local/aws_crt_cpp/lib64/ \; 2>/dev/null || true
    # Copy cmake subdirectories
    if [ -d "${INSTALL_PREFIX}/lib64/cmake" ]; then
        cp -r ${INSTALL_PREFIX}/lib64/cmake/* local/aws_crt_cpp/cmake/ 2>/dev/null || true
    fi
fi

# Copy from lib if it exists
if [ -d "${INSTALL_PREFIX}/lib" ]; then
    echo "  Copying from lib..."
    # Copy shared libraries
    cp -r ${INSTALL_PREFIX}/lib/*.so* local/aws_crt_cpp/lib/ 2>/dev/null || true
    # Copy static libraries
    cp -r ${INSTALL_PREFIX}/lib/*.a local/aws_crt_cpp/lib/ 2>/dev/null || true
    # Copy CMake files
    find ${INSTALL_PREFIX}/lib -name "*.cmake" -exec cp {} local/aws_crt_cpp/lib/ \; 2>/dev/null || true
    # Copy cmake subdirectories
    if [ -d "${INSTALL_PREFIX}/lib/cmake" ]; then
        cp -r ${INSTALL_PREFIX}/lib/cmake/* local/aws_crt_cpp/cmake/ 2>/dev/null || true
    fi
fi

# Copy ALL headers
echo "Copying headers from ${INSTALL_PREFIX}..."
if [ -d "${INSTALL_PREFIX}/include/aws" ]; then
    cp -r ${INSTALL_PREFIX}/include/aws local/aws_crt_cpp/include/
fi
# Copy any other headers that might be at the root
find ${INSTALL_PREFIX}/include -maxdepth 1 -type f -name "*.h" -exec cp {} local/aws_crt_cpp/include/ \; 2>/dev/null || true

# Create __init__.py
echo "Creating Python package files..."

touch "${LOCAL_PKG}/__init__.py"

python3 -m pip install --upgrade pip setuptools wheel build

# Locate pyproject.toml — try BUILD_SCRIPT_PATH (wheel CI), then repo-relative
# path (build CI), then fetch from master as last resort
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/a/aws-crt-cpp/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/a/aws-crt-cpp/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" "${SOURCE_DIR}/pyproject.toml"
else
    wget -O "${SOURCE_DIR}/pyproject.toml" \
    https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/aws-crt-cpp/pyproject.toml
fi

mkdir -p "${WORKING_DIR}/dist"
if ! python3 -m build --wheel --outdir "${WORKING_DIR}/dist" "${SOURCE_DIR}"; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

cd "${WORKING_DIR}"

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
