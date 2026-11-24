#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-identity-cpp
# Version       : azure-identity_1.13.3
# Source repo   : https://github.com/Azure/azure-sdk-for-cpp
# Tested on     : UBI 10.2
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <prachi.gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=azure-identity-cpp
PACKAGE_DIR=azure-sdk-for-cpp
PACKAGE_VERSION=${1:-azure-identity_1.13.3}
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-cpp
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

# Install dependencies
yum install -y --allowerasing \
    wget \
    git \
    cmake \
    ninja-build \
    make \
    gcc \
    gcc-c++ \
    openssl-devel \
    libcurl-devel \
    libxml2-devel \
    zlib-devel \
    pkgconf-pkg-config \
    python3-pip \
    sudo \
    ca-certificates

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Disable vcpkg auto-integration - use system-installed libraries instead
export AZURE_SDK_DISABLE_AUTO_VCPKG=1

gcc --version
g++ --version
cmake --version

# Clone source - azure-sdk-for-cpp is a monorepo; the azure-identity release tag is used as is
rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
SOURCE_DIR=$(pwd)

# Local prefix used for wheel packaging (azure-core is bundled with azure-identity)
mkdir -p local/azure_identity_cpp
PREFIX="${SOURCE_DIR}/local/azure_identity_cpp"

# Build azure-identity with its tests and azure-core from the same tag (the tests need
# azure-core-test-fw, which only exists in the whole-repo build); AMQP and OpenTelemetry
# are not used by azure-identity.
if ! (cmake -S . -B build_cmake -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_INSTALL_RPATH='$ORIGIN' \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TRANSPORT_CURL=ON \
        -DBUILD_TESTING=ON \
        -DDISABLE_AMQP=ON \
        -DDISABLE_AZURE_CORE_OPENTELEMETRY=ON \
      && cmake --build build_cmake -j"$(nproc)" --target azure-core azure-identity azure-identity-test \
      && cmake -P build_cmake/sdk/core/azure-core/cmake_install.cmake \
      && cmake -P build_cmake/sdk/identity/azure-identity/cmake_install.cmake); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Environment used by upstream CI (sdk/identity/ci.yml TestEnv)
export AZURE_TENANT_ID=33333333-3333-3333-3333-333333333333
export AZURE_CLIENT_ID=non-real-client
export AZURE_CLIENT_SECRET=non-real-secret

# Test the build (upstream CtestRegex: azure-identity.). Tests run serially as upstream CI does:
# several tests share one temporary azure-identity-test.pem file; the Azure Arc tests call sudo.
BUILD_LIBS=$(find build_cmake -name '*.so*' -printf '%h\n' | sort -u | paste -sd:)
export LD_LIBRARY_PATH="${BUILD_LIBS}"
if ! (cd build_cmake && ctest --output-on-failure -R 'azure-identity\.'); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Create __init__.py so setuptools recognises local/azure_identity_cpp as a Python package
touch local/azure_identity_cpp/__init__.py

# Build Python wheel
python3 -m pip install --upgrade setuptools wheel

# Locate pyproject.toml - try two known repo-relative paths before wget:
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

if ! python3 -m pip wheel . --no-build-isolation --no-deps -w dist \
   || ! python3 -m pip install --force-reinstall --no-deps dist/azure_identity_cpp-*.whl; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Smoke test: the installed wheel ships the headers, azure-identity loads, and azure-core is
# resolved from the wheel itself (LD_LIBRARY_PATH is cleared so only the RUNPATH can find it)
unset LD_LIBRARY_PATH
WHEEL_DIR=$(python3 -c "import os, azure_identity_cpp; print(os.path.dirname(azure_identity_cpp.__file__))")
if ! python3 -c "
import ctypes, os
d = '${WHEEL_DIR}'
assert os.path.isfile(os.path.join(d, 'include', 'azure', 'identity.hpp'))
ctypes.CDLL(os.path.join(d, 'lib64', 'libazure-identity.so'))
print('azure_identity_cpp load OK')
" \
   || ! ldd "${WHEEL_DIR}/lib64/libazure-identity.so" | grep "libazure-core" | grep -q "${WHEEL_DIR}/lib64"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi
cd "$WORKING_DIR"

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
