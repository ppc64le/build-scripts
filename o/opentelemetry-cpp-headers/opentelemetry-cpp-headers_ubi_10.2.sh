#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opentelemetry-cpp-headers
# Version       : v1.27.0
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : UBI:10.2
# Language      : C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivender Singh <shivender.singh2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=opentelemetry-cpp-headers
PACKAGE_DIR=opentelemetry-cpp-headers
SCRIPT_PACKAGE_VERSION=v1.27.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-cpp
WORKING_DIR=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

# Test dependency versions
GTEST_VERSION=${GTEST_VERSION:-v1.14.0}

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

yum install -y git gcc-c++ gcc wget make python3 python3-pip cmake diffutils

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

gcc --version
cmake --version
python3 --version

# Install gtest (needed by the API unit tests)
cd "$WORKING_DIR"
rm -rf googletest
if ! git clone https://github.com/google/googletest.git; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd googletest/
git checkout "$GTEST_VERSION"
mkdir build
cd build
if ! (cmake .. && make -j"$(nproc)" && make install); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Clone source
cd "$WORKING_DIR"
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
echo "Resolved commit: $(git rev-parse HEAD)"

# Local prefix used for wheel packaging
PREFIX="${SOURCE_DIR}/local/opentelemetry_cpp_headers"
mkdir -p "$PREFIX"

# Build and install the header-only API (WITH_API_ONLY: no SDK, exporters or examples);
# only the API unit tests are built
if ! (cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DWITH_API_ONLY=ON \
        -DWITH_BENCHMARK=OFF \
        -DBUILD_TESTING=ON \
      && cmake --build build -j"$(nproc)" \
      && cmake --install build); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the build: run the upstream API unit tests
if ! (cd build && ctest --output-on-failure -j"$(nproc)"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Create __init__.py so setuptools recognises local/opentelemetry_cpp_headers as a Python package
touch "$PREFIX/__init__.py"

# Build Python wheel
python3 -m pip install --upgrade pip setuptools wheel

# Locate pyproject.toml
_PYPROJECT_SRC=""
if [ -f "${SCRIPT_PATH}/pyproject.toml" ]; then
    _PYPROJECT_SRC="${SCRIPT_PATH}/pyproject.toml"
elif [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/o/opentelemetry-cpp-headers/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/o/opentelemetry-cpp-headers/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" pyproject.toml
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opentelemetry-cpp-headers/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" pyproject.toml

if ! python3 -m pip wheel . --no-build-isolation --no-deps -w dist; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
cp -f dist/opentelemetry_cpp_headers-*.whl "$WORKING_DIR/"

# Install the wheel into a clean virtual environment (nothing from the install prefix is on its path)
rm -rf "$WORKING_DIR/venv"
python3 -m venv "$WORKING_DIR/venv"
source "$WORKING_DIR/venv/bin/activate"
if ! python3 -m pip install --force-reinstall --no-deps dist/opentelemetry_cpp_headers-*.whl; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Smoke test: the installed wheel is importable and ships the API headers and CMake package config
if ! python3 -c "
import glob, os, opentelemetry_cpp_headers
d = os.path.dirname(opentelemetry_cpp_headers.__file__)
need = ['include/opentelemetry/trace/tracer.h',
        'include/opentelemetry/version.h',
        'lib64/cmake/opentelemetry-cpp/opentelemetry-cpp-config.cmake']
missing = [p for p in need if not glob.glob(os.path.join(d, p))]
assert not missing, 'missing from wheel: %s' % missing
print('opentelemetry_cpp_headers import OK:', d)
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Test the wheel: the headers shipped in the installed wheel must be identical to the
# API headers in the source tree that the unit tests above were built and run against
WHEEL_INCLUDE_DIR=$(python3 -c "import os, opentelemetry_cpp_headers; print(os.path.dirname(opentelemetry_cpp_headers.__file__))")/include/opentelemetry
if ! diff -r -x '.clang-format' -x '*.md' "${SOURCE_DIR}/api/include/opentelemetry" "${WHEEL_INCLUDE_DIR}"; then
    echo "Headers in the installed wheel differ from api/include/opentelemetry"
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi
deactivate

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
