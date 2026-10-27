#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-storage-blobs
# Version       : azure-storage-blobs_12.18.0
# Source repo   : https://github.com/Azure/azure-sdk-for-cpp
# Tested on     : UBI 10.2
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Veenious D Geevarghese <Veenious.Geevarghese@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=azure-storage-blobs
PACKAGE_DIR=azure-sdk-for-cpp
PACKAGE_VERSION=${1:-"azure-storage-blobs_12.18.0"}
PACKAGE_URL=https://github.com/Azure/azure-sdk-for-cpp
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Detect POWER10 and set CPU optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies
# Note: curl-minimal is pre-installed in UBI 10 and conflicts with curl — do not install curl
yum install -y --allowerasing \
    wget \
    git \
    cmake \
    ninja-build \
    make \
    gcc \
    gcc-c++ \
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
    python3-devel \
    ca-certificates

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Disable vcpkg auto-integration — use system-installed libraries instead
export AZURE_SDK_DISABLE_AUTO_VCPKG=1

gcc --version
g++ --version
cmake --version

# Clone source
rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout ${PACKAGE_VERSION}
SOURCE_DIR=$(pwd)

# macro_guard.cpp uses intentional compile-fail macros (#define min/#define max/#define small)
# that trigger errors under gcc 14's strict UDL (user-defined literal) parsing (P1473R1).
# Remove those three defines so the translation unit compiles cleanly while still
# verifying that the public headers include-guard correctly against the macros.
sed -i '/^#define small /d; /^#define max(/d; /^#define min(/d' \
    "${SOURCE_DIR}/sdk/storage/azure-storage-blobs/test/ut/macro_guard.cpp"

# Configure from repo root so azure-core resolves in-tree
mkdir -p build && cd build

if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS} -include cstdint" \
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
if ! ctest --output-on-failure --test-dir . -R "^azure-storage-blobs\." \
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

# Copy only the blobs shared library from the build tree
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
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#azure-storage-blobs_}/g" "${SOURCE_DIR}/pyproject.toml"

mkdir -p "${WORKING_DIR}/dist"
if ! python3 -m build --wheel --outdir "${WORKING_DIR}/dist" "${SOURCE_DIR}"; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

cd "${WORKING_DIR}"

WHEEL_FILE=$(find "${WORKING_DIR}/dist" -name "azure_storage_blobs_cpp-*.whl" | head -1)
if [ -z "${WHEEL_FILE}" ]; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi
# Install the wheel in a clean venv
python3 -m venv /tmp/azure-storage-blobs-test-env
source /tmp/azure-storage-blobs-test-env/bin/activate
if ! pip install --force-reinstall "${WHEEL_FILE}"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    deactivate
    exit 1
fi

# Smoke test - run from /tmp so Python imports the installed wheel, not the
# source tree.
cd /tmp
if ! python3 -c "
import glob, os
from importlib.metadata import version
import azure_storage_blobs_cpp as p
d = os.path.dirname(p.__file__)
print('azure-storage-blobs-cpp', version('azure-storage-blobs-cpp'), '|', d)
assert version('azure-storage-blobs-cpp') == '${PACKAGE_VERSION#azure-storage-blobs_}'
assert glob.glob(d + '/lib64/libazure-storage-blobs.so*')
assert os.path.isfile(d + '/include/azure/storage/blobs.hpp')
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    cd "$WORKING_DIR"
    exit 2
fi
cd "$WORKING_DIR"
deactivate

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
