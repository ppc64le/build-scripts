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

# Clone source
rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" 
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
SOURCE_DIR=$(pwd)

INSTALL_PREFIX="${2:-${SOURCE_DIR}/local/install_stage}"
mkdir -p "${INSTALL_PREFIX}"

# Configure and build.
echo "Configuring ${PACKAGE_NAME} ${PACKAGE_VERSION}..."
mkdir -p build && cd build

if ! cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
    	-DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
		-DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
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

# Run tests against the freshly installed (staged) libraries.
export LD_LIBRARY_PATH="${INSTALL_PREFIX}/lib64:${INSTALL_PREFIX}/lib"
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

for libdir in lib64 lib; do
    if [ -d "${INSTALL_PREFIX}/${libdir}" ]; then
        echo "  Copying from ${libdir}..."
        cp -a "${INSTALL_PREFIX}/${libdir}"/*.so* "${LOCAL_PKG}/${libdir}/" 2>/dev/null || true
        cp -a "${INSTALL_PREFIX}/${libdir}"/*.a   "${LOCAL_PKG}/${libdir}/" 2>/dev/null || true
        find "${INSTALL_PREFIX}/${libdir}" -name "*.cmake" -exec cp {} "${LOCAL_PKG}/${libdir}/" \; 2>/dev/null || true
        if [ -d "${INSTALL_PREFIX}/${libdir}/cmake" ]; then
            cp -r "${INSTALL_PREFIX}/${libdir}/cmake"/* "${LOCAL_PKG}/cmake/" 2>/dev/null || true
        fi
    fi
done

# Copy installed headers.
echo "Copying headers from ${INSTALL_PREFIX}..."
if [ -d "${INSTALL_PREFIX}/include/aws" ]; then
    cp -r "${INSTALL_PREFIX}/include/aws" "${LOCAL_PKG}/include/"
fi
find "${INSTALL_PREFIX}/include" -maxdepth 1 -type f -name "*.h" -exec cp {} "${LOCAL_PKG}/include/" \; 2>/dev/null || true

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

sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" "${SOURCE_DIR}/pyproject.toml"

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

# Smoke test: package version matches, and the installed wheel ships the shared
# libraries. Run from /tmp so Python imports the installed wheel, not the source tree.
echo "Running Python wheel smoke test..."
cd /tmp
if ! python3 -c "
import glob, os
from importlib.metadata import version
import aws_crt_cpp

assert version('aws-crt-cpp') == '${PACKAGE_VERSION#v}', 'Package version mismatch'
d = os.path.dirname(aws_crt_cpp.__file__)
for lib in ('libaws-crt-cpp.so', 'libaws-c-common.so'):
    assert glob.glob(os.path.join(d, 'lib64', lib + '*')), 'missing ' + lib + ' in wheel'
print('aws_crt_cpp import OK')
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    cd "$WORKING_DIR"
    deactivate || true
    exit 2
fi

# Wheel test: re-run the upstream tests, now against the libraries from the installed wheel.
WHEEL_LIB_DIR=$(python3 -c "import os, aws_crt_cpp; print(os.path.dirname(aws_crt_cpp.__file__))")
export LD_LIBRARY_PATH="${WHEEL_LIB_DIR}/lib64:${WHEEL_LIB_DIR}/lib"
cd "${SOURCE_DIR}/build"
if ! ctest --output-on-failure -j"$(nproc)"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    cd "$WORKING_DIR"
    deactivate || true
    exit 2
fi

cd "$WORKING_DIR"
deactivate

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
