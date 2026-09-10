#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-storage-blobs
# Version       : 12.18.0
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

PACKAGE_NAME=azure-storage-blobs
SCRIPT_PACKAGE_VERSION=12.18.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_VERSION=$(echo "${PACKAGE_VERSION}" | sed 's/^azure-storage-blobs_//')
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-cpp
WORKING_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$(realpath "$0" 2>/dev/null || echo "$0")" 2>/dev/null || echo ".")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Detect POWER10+ and apply POWER10 baseline optimizations
if grep -qi "power10" /proc/cpuinfo 2>/dev/null || \
   grep -qi "power11" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10+ — applying POWER10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10+ not detected — no arch-specific flags applied"
fi

# Install dependencies
yum install -y --allowerasing \
    wget \
    git \
    cmake \
    ninja-build \
    make \
    gcc-toolset-15 \
    gcc-toolset-15-gcc \
    gcc-toolset-15-gcc-c++ \
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
    perl-FindBin \
    perl-File-Compare \
    perl-IPC-Cmd \
    python3 \
    python3-pip \
    ca-certificates

# Activate gcc-toolset-15 (UBI 10 — SCL removed, use PATH export)
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Disable vcpkg auto-integration — use system-installed libraries instead
export AZURE_SDK_DISABLE_AUTO_VCPKG=1

echo "Using gcc: $(gcc --version | head -1)"
g++ --version | head -1
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
git checkout azure-storage-blobs_${PACKAGE_VERSION}
SOURCE_DIR=$(pwd)

# Configure from repo root so azure-core resolves in-tree
mkdir -p build && cd build

if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
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

if ! cmake --build . --target azure-storage-blobs azure-storage-blobs-test -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run offline unit tests only, skipping all test suites that require live Azure credentials.
if ! ctest --output-on-failure --test-dir . -j"$(nproc)" -R "^azure-storage-blobs\." \
        --exclude-regex 'AppendBlobClientTest\.|BlobContainerClientTest\.|BlobSasTest\.|BlobServiceClientTest\.|BlockBlobClientTest\.|PageBlobClientTest\.|_LIVEONLY_|_PLAYBACKONLY_'; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

cd "$SOURCE_DIR"

# Build Python wheel
LOCAL_PKG="${SOURCE_DIR}/local/azure_storage_blobs_cpp"
mkdir -p "${LOCAL_PKG}/lib64" \
         "${LOCAL_PKG}/include/azure/storage/blobs" \
         "${LOCAL_PKG}/share/azure-storage-blobs-cpp"

# Copy shared libraries directly from the build tree
find "${SOURCE_DIR}/build" -name "libazure-storage-blobs.so*" \
    -exec cp -P {} "${LOCAL_PKG}/lib64/" \;

# Copy headers from source tree
cp -r "${SOURCE_DIR}/sdk/storage/azure-storage-blobs/inc/azure/storage/blobs" \
      "${LOCAL_PKG}/include/azure/storage/"
[ -f "${SOURCE_DIR}/sdk/storage/azure-storage-blobs/inc/azure/storage/blobs.hpp" ] && \
    cp "${SOURCE_DIR}/sdk/storage/azure-storage-blobs/inc/azure/storage/blobs.hpp" \
       "${LOCAL_PKG}/include/azure/storage/"

touch "${LOCAL_PKG}/__init__.py"

python3 -m pip install --upgrade pip setuptools wheel build

# Locate pyproject.toml — try BUILD_SCRIPT_PATH (wheel CI), then repo-relative
# path (build CI), then fetch from master as last resort
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/a/azure-storage-blobs/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/a/azure-storage-blobs/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" "${SOURCE_DIR}/pyproject.toml"
else
    wget -O "${SOURCE_DIR}/pyproject.toml" \
        https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/azure-storage-blobs/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION}/g" "${SOURCE_DIR}/pyproject.toml"

mkdir -p "${WORKING_DIR}/dist"
if ! python3 -m build --wheel --outdir "${WORKING_DIR}/dist" "${SOURCE_DIR}"; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

cd "${WORKING_DIR}"

# Install the built wheel and validate the package is importable
WHEEL_FILE=$(find "${WORKING_DIR}/dist" -name "azure_storage_blobs_cpp-*.whl" | head -1)
if [ -z "${WHEEL_FILE}" ]; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

python3 -m pip install --force-reinstall "${WHEEL_FILE}"

if ! python3 -c "import azure_storage_blobs_cpp; print('azure_storage_blobs_cpp import OK')"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
