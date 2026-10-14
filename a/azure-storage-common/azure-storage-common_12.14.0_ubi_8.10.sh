#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-storage-common
# Version       : 12.14.0
# Source repo   : https://github.com/Azure/azure-sdk-for-cpp
# Tested on     : UBI 8.10
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

PACKAGE_NAME=azure-storage-common
SCRIPT_PACKAGE_VERSION=12.14.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_VERSION=$(echo "${PACKAGE_VERSION}" | sed 's/^azure-storage-common_//')
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-cpp
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Detect POWER10 and set CPU optimization flags accordingly
if grep -qi "power10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies
# Enable perl module stream so sub-packages resolve correctly on UBI 8
yum module enable -y perl:5.26 2>/dev/null || true

# Note: curl-minimal is pre-installed in UBI 8 and conflicts with curl — do not install curl
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
    tar \
    perl \
    python39 \
    python39-pip \
    ca-certificates

# Activate GCC Toolset 12 (provides GCC 12 on UBI 8)
export PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib/gcc/ppc64le-redhat-linux/12:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-12/root/usr/include:$CPATH
. /opt/rh/gcc-toolset-12/enable

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Disable vcpkg auto-integration — use system-installed libraries instead
export AZURE_SDK_DISABLE_AUTO_VCPKG=1

gcc --version
g++ --version
cmake --version

# Clone source
rm -rf azure-sdk-for-cpp
if ! git clone "$PACKAGE_URL"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd azure-sdk-for-cpp
git checkout azure-storage-common_${PACKAGE_VERSION}
SOURCE_DIR=$(pwd)

# Configure from repo root so azure-core resolves in-tree
mkdir -p build && cd build

if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TRANSPORT_CURL=ON \
        -DBUILD_TESTING=ON \
        -DDISABLE_AZURE_CORE_OPENTELEMETRY=ON \
        -DDISABLE_AMQP=ON \
        -DCMAKE_PREFIX_PATH=/usr/local \
        -DWARNINGS_AS_ERRORS=OFF \
        -Wno-dev; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! cmake --build . --target azure-storage-common azure-storage-common-test -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! ctest --output-on-failure --test-dir . -R "^azure-storage-common\."; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

cd "$SOURCE_DIR"

# Build Python wheel
LOCAL_PKG="${SOURCE_DIR}/local/azure_storage_common_cpp"
mkdir -p "${LOCAL_PKG}/lib64" \
         "${LOCAL_PKG}/include/azure/storage/common" \
         "${LOCAL_PKG}/share/azure-storage-common-cpp"

# Copy shared libraries directly from the build tree
find "${SOURCE_DIR}/build" -name "libazure-storage-common.so*" \
    -exec cp -P {} "${LOCAL_PKG}/lib64/" \;

# Copy headers from source tree
cp -r "${SOURCE_DIR}/sdk/storage/azure-storage-common/inc/azure/storage/common" \
      "${LOCAL_PKG}/include/azure/storage/"
[ -f "${SOURCE_DIR}/sdk/storage/azure-storage-common/inc/azure/storage/common.hpp" ] && \
    cp "${SOURCE_DIR}/sdk/storage/azure-storage-common/inc/azure/storage/common.hpp" \
       "${LOCAL_PKG}/include/azure/storage/"

touch "${LOCAL_PKG}/__init__.py"

python3.9 -m pip install --upgrade pip setuptools wheel build

# Locate pyproject.toml — try BUILD_SCRIPT_PATH (wheel CI), then repo-relative
# path (build CI), then fetch from master as last resort
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/a/azure-storage-common/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/a/azure-storage-common/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" "${SOURCE_DIR}/pyproject.toml"
else
    wget -O "${SOURCE_DIR}/pyproject.toml" \
        https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/azure-storage-common/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" "${SOURCE_DIR}/pyproject.toml"

mkdir -p "${WORKING_DIR}/dist"
if ! python3.9 -m build --wheel --outdir "${WORKING_DIR}/dist" "${SOURCE_DIR}"; then
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
