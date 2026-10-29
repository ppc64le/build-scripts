#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : aws-c-common
# Version       : v0.14.0
# Source repo   : https://github.com/awslabs/aws-c-common
# Tested on     : UBI 10.2
# Language      : C
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

PACKAGE_NAME=aws-c-common
PACKAGE_DIR=aws-c-common
SCRIPT_PACKAGE_VERSION=v0.14.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/awslabs/aws-c-common
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies 
yum install -y  \
    wget \
    git \
    cmake \
    make \
    gcc \
    python3 \
    python3-pip

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"

gcc --version
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
git checkout "$PACKAGE_VERSION"
SOURCE_DIR=$(pwd)

# Local prefix used for wheel packaging
mkdir -p local/aws_c_common
PREFIX="${SOURCE_DIR}/local/aws_c_common"

# Build and install 
if ! (cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=ON \
      && cmake --build build -j"$(nproc)" \
      && cmake --install build); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the build
export LD_LIBRARY_PATH="${SOURCE_DIR}/build"
if ! (cd build && ctest --output-on-failure -j"$(nproc)") \
   || ! python3 bin/system_info/test-print-system-info.py --build-dir build; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Create __init__.py so setuptools recognises local/aws_c_common as a Python package
touch local/aws_c_common/__init__.py

# Build Python wheel
python3 -m pip install --upgrade setuptools wheel

# Locate pyproject.toml — try two known repo-relative paths before wget:
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/a/aws-c-common/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/a/aws-c-common/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" pyproject.toml
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/aws-c-common/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" pyproject.toml

if ! python3 -m pip wheel . --no-build-isolation --no-deps -w dist \
   || ! python3 -m pip install --force-reinstall --no-deps dist/aws_c_common-*.whl; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Smoke test: the installed wheel is importable and ships the shared library
if ! python3 -c "import os, aws_c_common; d = os.path.dirname(aws_c_common.__file__); assert os.path.isfile(os.path.join(d, 'lib64', 'libaws-c-common.so')); print('aws_c_common import OK')"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi
# Test the wheel: run the same upstream tests again, now against the library from the installed wheel
cd "$SOURCE_DIR"
export LD_LIBRARY_PATH=$(python3 -c "import os, aws_c_common; print(os.path.dirname(aws_c_common.__file__))")/lib64
if ! (cd build && ctest --output-on-failure -j"$(nproc)") \
   || ! python3 bin/system_info/test-print-system-info.py --build-dir build; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
