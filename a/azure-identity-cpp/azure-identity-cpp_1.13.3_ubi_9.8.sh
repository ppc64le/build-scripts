#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-identity-cpp
# Version       : 1.13.3
# Source repo   : https://github.com/Azure/azure-sdk-for-cpp
# Tested on     : UBI:9.8
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=azure-identity-cpp
PACKAGE_VERSION=${1:-"1.13.3"}
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-cpp
PACKAGE_DIR=azure-sdk-for-cpp
WORKING_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# azure-core version bundled at the azure-identity_1.13.3 tag
# (confirmed from sdk/core/azure-core/src/private/package_version.hpp)
AZURE_CORE_VERSION="1.16.2"

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies
yum install -y --allowerasing wget git cmake ninja-build make gcc gcc-c++ gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ \
    openssl openssl-devel libcurl libcurl-devel libxml2 libxml2-devel krb5-devel zlib zlib-devel pkg-config perl-FindBin perl-File-Compare python3-pip ca-certificates

# Activate GCC Toolset 13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-13/root/usr/include:$CPATH
. /opt/rh/gcc-toolset-13/enable

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"
export LDFLAGS="${CPU_FLAGS}"

# Disable vcpkg auto-integration — use system-installed libraries instead
export AZURE_SDK_DISABLE_AUTO_VCPKG=1

gcc --version
g++ --version
cmake --version

# Clone source — the monorepo tag for azure-identity 1.13.3 is azure-identity_1.13.3
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"
git checkout azure-identity_$PACKAGE_VERSION
SOURCE_DIR=$(pwd)

# ---------------------------------------------------------------------------
# Step 1: Build azure-core (required dependency) — install to /usr/local
# ---------------------------------------------------------------------------

mkdir -p build_core && cd build_core

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TRANSPORT_CURL=ON \
    -DDISABLE_AZURE_CORE_OPENTELEMETRY=ON \
    -GNinja \
    ../sdk/core/azure-core

ninja -j"$(nproc)"
ninja install

cd ..

ldconfig /usr/local/lib64
if ! ldconfig -p | grep -q libazure-core; then
    echo "------------------$PACKAGE_NAME: libazure-core not found after install-----------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 2: Build azure-identity — install to local prefix for wheel packaging
# ---------------------------------------------------------------------------

mkdir -p local/azure_identity_cpp
PREFIX="${SOURCE_DIR}/local/azure_identity_cpp"

mkdir -p build_release && cd build_release

cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TRANSPORT_CURL=ON \
    -Dazure-core-cpp_DIR="/usr/local/share/cmake/azure-core-cpp" \
    -GNinja \
    ../sdk/identity/azure-identity

ninja -j"$(nproc)"
ninja install

cd ..

cd "$SOURCE_DIR"

# Bundle azure-core with azure-identity so auditwheel can repair the wheel.
cp -a /usr/local/lib64/libazure-core.so* "${PREFIX}/lib64/"

# Create __init__.py so setuptools recognises local/azure_identity_cpp as a Python package
touch local/azure_identity_cpp/__init__.py

# Smoke-test: verify the shared library and headers are present in the local prefix
IDENTITY_SO=$(find "${PREFIX}/lib64" "${PREFIX}/lib" -name "libazure-identity.so.*" 2>/dev/null | head -1)
if [ -z "$IDENTITY_SO" ]; then
    echo "------------------$PACKAGE_NAME: shared library not found after install-----------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 2
fi

if ! ls "${PREFIX}/include/azure/identity.hpp" > /dev/null 2>&1; then
    echo "------------------$PACKAGE_NAME: header not found after install-----------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 2
fi

# Also available system-wide (installed in Step 2 build_release to local, and /usr/local via build_core)
ldconfig /usr/local/lib64

# Validate native library linkage — azure-identity must link against azure-core
if ! ldd "$IDENTITY_SO" | grep -q libazure-core; then
    echo "------------------$PACKAGE_NAME:Test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Test_Fails"
    exit 2
fi
echo "Linkage validation passed: libazure-identity links against libazure-core"

# Build Python wheel
cd "$SOURCE_DIR"
python3 -m pip install --upgrade pip setuptools wheel build

# Locate pyproject.toml
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/a/azure-identity-cpp/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/a/azure-identity-cpp/pyproject.toml"
fi
if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" pyproject.toml
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/azure-identity-cpp/pyproject.toml
fi

mkdir -p wheelhouse
if ! python3 -m pip wheel . --no-build-isolation -w wheelhouse; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

WHEEL_FILE=$(find wheelhouse -name "azure_identity_cpp-*.whl" | head -1)
echo "Wheel created: $WHEEL_FILE"

# ---------------------------------------------------------------------------
# Wheel validation — install into a clean virtual environment and verify
# ---------------------------------------------------------------------------

python3 -m venv /tmp/azure-identity-test-env
source /tmp/azure-identity-test-env/bin/activate

pip install --upgrade pip setuptools wheel

# Install the wheel into the clean venv
if ! pip install --force-reinstall "$WHEEL_FILE"; then
    echo "------------------$PACKAGE_NAME:Wheel_test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_Test_Fails"
    deactivate
    exit 2
fi

if ! python3 -c "
from importlib.metadata import version
print('Package : azure-identity-cpp')
print('Version :', version('azure-identity-cpp'))
"; then
    echo "------------------$PACKAGE_NAME:Wheel_test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_Test_Fails"
    deactivate
    exit 2
fi

deactivate

cd "$WORKING_DIR"

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
