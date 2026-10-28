#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : aws-crt-cpp
# Version       : v0.40.1
# Source repo   : https://github.com/awslabs/aws-crt-cpp
# Tested on     : UBI 10.2
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

PACKAGE_NAME="aws-crt-cpp"
PACKAGE_VERSION="${1:-v0.40.1}"
PACKAGE_URL="https://github.com/awslabs/aws-crt-cpp"
PACKAGE_DIR="aws-crt-cpp"
WORKING_DIR="$(pwd)"
INSTALL_PREFIX="${2:-/usr/local}"

# Detect POWER10 and set CPU optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi


# Install dependencies
yum install -y --allowerasing \
    wget git cmake make gcc gcc-c++ \
    openssl openssl-devel libcurl libxml2-devel zlib-devel \
    pkg-config tar perl-FindBin perl-File-Compare ca-certificates \
    python3 python3-pip python3-devel 

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

# Configure and build.
echo "Configuring ${PACKAGE_NAME} ${PACKAGE_VERSION}..."
mkdir -p build && cd build

if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
	-DCMAKE_EXE_LINKER_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_SHARED_LINKER_FLAGS="${CPU_FLAGS}" \
	-DBUILD_DEPS=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=ON \
        -DWARNINGS_AS_ERRORS=OFF; then
	echo "ERROR: CMake configuration failed"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Configure_Fails"
    exit 1
fi

if ! cmake --build . -j"$(nproc)"; then
    echo "ERROR: Build failed"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

# Install native libraries and headers.
if ! cmake --install .; then
    echo "ERROR: Installation failed"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run Test 
if ! ctest --output-on-failure -j"$(nproc)"; then
    echo "ERROR: C++ tests failed"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Test_Fails"
    exit 2
fi

echo "C++ build and tests passed."

cd "$SOURCE_DIR"

# Prepare the Python wheel package structure.
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

# # Copy installed headers.
echo "Copying headers from ${INSTALL_PREFIX}..."
if [ -d "${INSTALL_PREFIX}/include/aws" ]; then
    cp -r ${INSTALL_PREFIX}/include/aws local/aws_crt_cpp/include/
fi

# Copy any other headers that might be at the root
find ${INSTALL_PREFIX}/include -maxdepth 1 -type f -name "*.h" -exec cp {} local/aws_crt_cpp/include/ \; 2>/dev/null || true

# Create __init__.py
echo "Creating Python package files..."

# Ensure the Python package has an initializer.
touch "${LOCAL_PKG}/__init__.py"

# Install Python build tools.
python3 -m pip install --upgrade pip setuptools wheel build

# Locate the Python project configuration.
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

sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#aws-crt-cpp_}/g" "${SOURCE_DIR}/pyproject.toml"

# Build the wheel.
mkdir -p "${WORKING_DIR}/dist"
if ! python3 -m build --wheel --outdir "${WORKING_DIR}/dist" "${SOURCE_DIR}"; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

cd "${WORKING_DIR}"

WHEEL_FILE=$(find "${WORKING_DIR}/dist" -name "aws_crt_cpp-*.whl" | head -1)
if [ -z "${WHEEL_FILE}" ]; then
    echo "ERROR: Expected aws_crt_cpp wheel was not produced"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_Not_Found"
    exit 1
fi

echo "Wheel created: ${WHEEL_FILE}"

# Install and validate the wheel in isolation.
python3 -m venv /tmp/aws-crt-cpp-test-env
source /tmp/aws-crt-cpp-test-env/bin/activate
python3 -m pip install --upgrade pip
if ! pip install --force-reinstall "${WHEEL_FILE}"; then
    echo "ERROR: Wheel installation failed"
    deactivate || true
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Smoke test - run from /tmp so Python imports the installed wheel, not the
# source tree.
echo "Running Python wheel smoke test..."
cd /tmp

if ! python3 -c "
from importlib.metadata import version
import aws_crt_cpp

assert version('aws-crt-cpp') == '${PACKAGE_VERSION#v}', 'Package version mismatch'
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    cd "$WORKING_DIR"
    deactivate || true
    exit 2
fi

cd "$WORKING_DIR"
deactivate

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
