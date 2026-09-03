#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-core-cpp
# Version       : 1.16.3
# Source repo   : https://github.com/Azure/azure-sdk-for-cpp
# Tested on     : UBI:8.10
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Veenious Geevarghese <Veenious.Geevarghese@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=azure-core-cpp
PACKAGE_VERSION=${1:-"1.16.3"}
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-cpp
WORKING_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies
# Enable the default perl module stream so perl sub-packages resolve correctly
yum module enable -y perl:5.26 2>/dev/null || true

yum install -y --allowerasing \
    wget \
    git \
    cmake \
    ninja-build \
    make \
    gcc \
    gcc-c++ \
    gcc-toolset-12-gcc \
    gcc-toolset-12-gcc-c++ \
    openssl \
    openssl-devel \
    libcurl \
    libcurl-devel \
    libxml2 \
    libxml2-devel \
    zlib \
    zlib-devel \
    pkg-config \
    perl \
    python39 \
    python39-pip \
    ca-certificates

# Activate GCC Toolset 12
export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib/gcc/ppc64le-redhat-linux/12:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-12/root/usr/include:$CPATH
. /opt/rh/gcc-toolset-12/enable

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"
export LDFLAGS="${CPU_FLAGS}"

# Disable vcpkg auto-integration — use system-installed libraries instead
export AZURE_SDK_DISABLE_AUTO_VCPKG=1

gcc --version
g++ --version
cmake --version

# Clone source
rm -rf azure-sdk-for-cpp
git clone $PACKAGE_URL
cd azure-sdk-for-cpp
git checkout azure-core_$PACKAGE_VERSION
SOURCE_DIR=$(pwd)

# Build azure-core only — install into a local prefix for wheel packaging
mkdir -p local/azure_core_cpp
PREFIX="${SOURCE_DIR}/local/azure_core_cpp"

# --- Release build (no tests) — installed to local prefix for wheel packaging ---
mkdir -p build_release && cd build_release

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TRANSPORT_CURL=ON \
    -GNinja \
    ../sdk/core/azure-core

ninja -j"$(nproc)"
ninja install

cd ..

# --- Test build — installed to /usr/local for ctest ---
mkdir -p build_test && cd build_test

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_TESTING=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TRANSPORT_CURL=ON \
    -GNinja \
    ../sdk/core/azure-core

ninja -j"$(nproc)"
DESTDIR="" ninja install

cd ..

cd "$SOURCE_DIR"

# Create __init__.py so setuptools recognises local/azure_core_cpp as a Python package
touch local/azure_core_cpp/__init__.py

# Smoke-test: verify the shared library and headers are present
ldconfig /usr/local/lib64
if ! ldconfig -p | grep -q libazure-core; then
    echo "------------------$PACKAGE_NAME: shared library not found after install-----------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! ls /usr/local/include/azure/core.hpp > /dev/null 2>&1; then
    echo "------------------$PACKAGE_NAME: header not found after install-----------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run unit tests — skip suites that require live network / Azure test proxy
cd "$SOURCE_DIR/build_test/test/ut"
if ! ctest --output-on-failure -j"$(nproc)" \
    --exclude-regex 'CurlConnectionPool\.|CurlTransportOptions\.|CurlSession\.|Test/TransportAdapter\.|TransportAdapterOptions\.|SdkWithLibcurl\.'; then
    echo "------------------$PACKAGE_NAME:Test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Test_Fails"
    exit 1
fi

# Build Python wheel
cd "$SOURCE_DIR"
python3.9 -m pip install --upgrade pip setuptools wheel build

cp "$SCRIPT_DIR/pyproject.toml" .

sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" pyproject.toml

if ! python3.9 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

cd "$WORKING_DIR"

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
