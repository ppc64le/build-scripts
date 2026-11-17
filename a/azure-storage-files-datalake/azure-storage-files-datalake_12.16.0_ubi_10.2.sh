#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-storage-files-datalake
# Version       : azure-storage-files-datalake_12.16.0
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

PACKAGE_NAME=azure-storage-files-datalake
PACKAGE_DIR=azure-sdk-for-cpp
SCRIPT_PACKAGE_VERSION=azure-storage-files-datalake_12.16.0   
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}               
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
yum install -y --allowerasing wget git cmake ninja-build make gcc gcc-c++ openssl openssl-devel libcurl libcurl-devel \
    libxml2 libxml2-devel zlib zlib-devel pkg-config tar perl-FindBin perl-File-Compare perl-IPC-Cmd python3 python3-pip python3-devel ca-certificates

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Disable vcpkg auto-integration — use in-tree sources instead
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
git checkout "${PACKAGE_VERSION}"
git checkout azure-core_1.16.3 -- sdk/core/azure-core
git checkout azure-identity_1.13.3 -- sdk/identity/azure-identity
SOURCE_DIR=$(pwd)
PKG_VERSION="${PACKAGE_VERSION#azure-storage-files-datalake_}"

# Configure from repo root so azure-core / azure-storage-common / azure-storage-blobs
# resolve in-tree
mkdir -p build && cd build

if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS} -include cstdint" \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DCMAKE_SHARED_LINKER_FLAGS='-Wl,-rpath,\$ORIGIN' \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TRANSPORT_CURL=ON \
        -DBUILD_TESTING=OFF \
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

if ! cmake --build . --target azure-storage-files-datalake -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Unit tests are skipped: most of the upstream test suite needs live Azure credentials.

cd "$SOURCE_DIR"

# Build Python wheel
LOCAL_PKG="${SOURCE_DIR}/local/azure_storage_files_datalake_cpp"
mkdir -p "${LOCAL_PKG}/lib64" \
         "${LOCAL_PKG}/include/azure/storage/files" \
         "${LOCAL_PKG}/share/azure-storage-files-datalake-cpp"

# Bundle the datalake library together with the libraries it links against
# (core, common, blobs) so the wheel works on its own. The libraries find each
# other through the $ORIGIN rpath set at link time.
for lib in azure-storage-files-datalake azure-storage-blobs azure-storage-common azure-core; do
    find "${SOURCE_DIR}/build/sdk" -name "lib${lib}.so*" \
        -exec cp -P {} "${LOCAL_PKG}/lib64/" \;
done

# Copy headers from source tree
INC_DIR="${SOURCE_DIR}/sdk/storage/azure-storage-files-datalake/inc/azure/storage/files"
cp -r "${INC_DIR}/datalake" "${LOCAL_PKG}/include/azure/storage/files/"
cp "${INC_DIR}/datalake.hpp" "${LOCAL_PKG}/include/azure/storage/files/"

touch "${LOCAL_PKG}/__init__.py"

python3 -m pip install --upgrade pip setuptools wheel build

# Locate pyproject.toml — try BUILD_SCRIPT_PATH (wheel CI), then repo-relative
# path (build CI), then fetch from master as last resort
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/a/azure-storage-files-datalake/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/a/azure-storage-files-datalake/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" "${SOURCE_DIR}/pyproject.toml"
else
    wget -O "${SOURCE_DIR}/pyproject.toml" \
        https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/azure-storage-files-datalake/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PKG_VERSION}/g" "${SOURCE_DIR}/pyproject.toml"

mkdir -p "${WORKING_DIR}/dist"
if ! python3 -m build --wheel --outdir "${WORKING_DIR}/dist" "${SOURCE_DIR}"; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

cd "${WORKING_DIR}"

WHEEL_FILE=$(find "${WORKING_DIR}/dist" -name "azure_storage_files_datalake_cpp-*.whl" | head -1)
if [ -z "${WHEEL_FILE}" ]; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Install the wheel in a clean venv
python3 -m venv /tmp/azure-storage-files-datalake-test-env
source /tmp/azure-storage-files-datalake-test-env/bin/activate
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
import azure_storage_files_datalake_cpp as p
d = os.path.dirname(p.__file__)
print('azure-storage-files-datalake-cpp', version('azure-storage-files-datalake-cpp'), '|', d)
assert version('azure-storage-files-datalake-cpp') == '${PKG_VERSION}'
assert glob.glob(d + '/lib64/libazure-storage-files-datalake.so*')
assert os.path.isfile(d + '/include/azure/storage/files/datalake.hpp')
assert os.listdir(d + '/include/azure/storage/files/datalake')
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    cd "$WORKING_DIR"
    deactivate
    exit 2
fi
cd "$WORKING_DIR"
deactivate

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
