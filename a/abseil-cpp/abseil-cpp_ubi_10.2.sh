#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : abseil-cpp
# Version          : 20240116.2
# Source repo      : https://github.com/abseil/abseil-cpp
# Tested on        : UBI:10.2
# Language         : Python, C++
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=abseil-cpp
PACKAGE_DIR=abseil-cpp
PACKAGE_VERSION=${1:-20240116.2}
PACKAGE_URL=https://github.com/abseil/abseil-cpp
CURRENT_DIR=$(pwd)

# Install core dependencies — Python packages must come first
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake wget ninja-build

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

echo "Using gcc: $(gcc --version | head -1)"

python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install cmake ninja

# Setting paths and creating directories
mkdir -p "$CURRENT_DIR/abseil-prefix"
PREFIX="$CURRENT_DIR/abseil-prefix"

git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

SOURCE_DIR=$(pwd)
mkdir -p "$SOURCE_DIR/local/abseilcpp"
ABSEILCPP_DIR="$SOURCE_DIR/local/abseilcpp"

# Build abseil-cpp
echo "$PACKAGE_NAME build starts!"

mkdir build
cd build

cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ..

cmake --build .
cmake --install .

cd "$SOURCE_DIR"

cp -r "$PREFIX/"* "$ABSEILCPP_DIR/"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"

# Create pyproject.toml from upstream template
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/abseil-cpp/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g" pyproject.toml

if ! python3.14 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

if ! python3.14 -c "import abseil; print('abseil import OK')" 2>/dev/null && \
   ! python3.14 -c "import absl; print('absl import OK')" 2>/dev/null; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
